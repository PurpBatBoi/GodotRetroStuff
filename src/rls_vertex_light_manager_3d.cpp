#include "rls_vertex_light_manager_3d.h"

#include "rls_directional_light_3d.h"
#include "rls_point_light_3d.h"
#include "rls_spot_light_3d.h"

#include <godot_cpp/classes/camera3d.hpp>
#include <godot_cpp/classes/editor_interface.hpp>
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/mesh.hpp>
#include <godot_cpp/classes/sub_viewport.hpp>
#include <godot_cpp/classes/viewport.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/math.hpp>

#include <algorithm>
#include <array>
#include <unordered_map>
#include <vector>

using namespace godot;

namespace {

template <typename T>
bool remove_from_vector(Vector<T *> &p_values, T *p_value) {
	int64_t idx = p_values.find(p_value);
	if (idx == -1) {
		return false;
	}
	p_values.remove_at(idx);
	return true;
}

constexpr int32_t MAX_GEOMETRY_UPDATES_PER_FRAME = 64;
constexpr uint32_t CAMERA_FADE_STEPS = 32;
constexpr uint32_t CAMERA_FADE_STATE_CULLED = 0;
constexpr uint32_t CAMERA_FADE_STATE_FULL = CAMERA_FADE_STEPS + 1;

struct LocalLightCandidate {
	enum class Type {
		POINT,
		SPOT
	};

	Type type = Type::POINT;
	RLS_PointLight3D *point_light = nullptr;
	RLS_SpotLight3D *spot_light = nullptr;
	float contribution_score = 0.0f;
	float camera_fade_factor = 1.0f;
	float distance_squared = 0.0f;
	Vector3 reference_position;
};

struct MeshInfluenceBounds {
	Transform3D global_transform;
	Transform3D inverse_global_transform;
	AABB local_aabb;
	Vector3 world_origin;
	Vector3 world_center;
};

float compute_light_color_intensity(const Color &p_color) {
	return (p_color.r * 0.2126f) + (p_color.g * 0.7152f) + (p_color.b * 0.0722f);
}

float compute_distance_attenuation(float p_distance, float p_range, float p_exponent) {
	const float range = MAX(p_range, 0.0001f);
	const float exponent = p_exponent > 0.0f ? p_exponent : 1.0f;
	return Math::pow(1.0f - Math::smoothstep(0.0f, range, p_distance), exponent);
}

float compute_camera_distance_fade(float p_distance, bool p_enabled, float p_begin, float p_length) {
	if (!p_enabled) {
		return 1.0f;
	}

	const float begin = MAX(p_begin, 0.0f);
	const float length = MAX(p_length, 0.01f);
	const float end = begin + length;

	if (p_distance <= begin) {
		return 1.0f;
	}
	if (p_distance >= end) {
		return 0.0f;
	}

	return 1.0f - Math::smoothstep(begin, end, p_distance);
}

template <typename T>
uint32_t compute_camera_fade_state(T *p_light, Camera3D *p_camera) {
	if (p_light == nullptr || !p_light->is_enabled() || !p_light->is_distance_fade_enabled() || p_camera == nullptr) {
		return CAMERA_FADE_STATE_FULL;
	}

	const float camera_distance = p_camera->get_global_transform().origin.distance_to(p_light->get_global_transform().origin);
	const float fade = compute_camera_distance_fade(camera_distance, true, p_light->get_distance_fade_begin(), p_light->get_distance_fade_length());

	if (fade <= static_cast<float>(CMP_EPSILON)) {
		return CAMERA_FADE_STATE_CULLED;
	}
	if (fade >= 1.0f - static_cast<float>(CMP_EPSILON)) {
		return CAMERA_FADE_STATE_FULL;
	}

	const float scaled = fade * static_cast<float>(CAMERA_FADE_STEPS - 1);
	const uint32_t bucket = static_cast<uint32_t>(CLAMP(Math::round(scaled), 0.0f, static_cast<float>(CAMERA_FADE_STEPS - 1)));
	return 1 + bucket;
}

bool update_camera_fade_states(Camera3D *p_camera, const Vector<RLS_PointLight3D *> &p_point_lights, const Vector<RLS_SpotLight3D *> &p_spot_lights, std::unordered_map<uint64_t, uint32_t> &r_last_states) {
	std::unordered_map<uint64_t, uint32_t> current_states;
	current_states.reserve(p_point_lights.size() + p_spot_lights.size());

	bool changed = false;

	for (RLS_PointLight3D *light : p_point_lights) {
		if (light == nullptr || !light->is_enabled() || !light->is_distance_fade_enabled()) {
			continue;
		}

		const uint64_t light_id = light->get_instance_id();
		const uint32_t state = compute_camera_fade_state(light, p_camera);
		current_states[light_id] = state;

		auto last_it = r_last_states.find(light_id);
		if (last_it == r_last_states.end() || last_it->second != state) {
			changed = true;
		}
	}

	for (RLS_SpotLight3D *light : p_spot_lights) {
		if (light == nullptr || !light->is_enabled() || !light->is_distance_fade_enabled()) {
			continue;
		}

		const uint64_t light_id = light->get_instance_id();
		const uint32_t state = compute_camera_fade_state(light, p_camera);
		current_states[light_id] = state;

		auto last_it = r_last_states.find(light_id);
		if (last_it == r_last_states.end() || last_it->second != state) {
			changed = true;
		}
	}

	if (!changed && current_states.size() != r_last_states.size()) {
		changed = true;
	}

	r_last_states.swap(current_states);
	return changed;
}

bool has_camera_distance_fade_lights(const Vector<RLS_PointLight3D *> &p_point_lights, const Vector<RLS_SpotLight3D *> &p_spot_lights) {
	for (RLS_PointLight3D *light : p_point_lights) {
		if (light != nullptr && light->is_enabled() && light->is_distance_fade_enabled()) {
			return true;
		}
	}

	for (RLS_SpotLight3D *light : p_spot_lights) {
		if (light != nullptr && light->is_enabled() && light->is_distance_fade_enabled()) {
			return true;
		}
	}

	return false;
}

Camera3D *resolve_active_camera(Node *p_node) {
	if (p_node != nullptr) {
		Viewport *viewport = p_node->get_viewport();
		if (viewport != nullptr) {
			if (Camera3D *viewport_camera = viewport->get_camera_3d()) {
				return viewport_camera;
			}
		}
	}

	Engine *engine = Engine::get_singleton();
	if (engine == nullptr || !engine->is_editor_hint()) {
		return nullptr;
	}

	EditorInterface *editor_interface = EditorInterface::get_singleton();
	if (editor_interface == nullptr) {
		return nullptr;
	}

	SubViewport *editor_viewport = editor_interface->get_editor_viewport_3d();
	if (editor_viewport == nullptr) {
		return nullptr;
	}

	return editor_viewport->get_camera_3d();
}

MeshInfluenceBounds build_mesh_influence_bounds(RLS_LitGeometryInstance *p_geometry) {
	MeshInfluenceBounds bounds;
	if (p_geometry == nullptr) {
		return bounds;
	}

	bounds.global_transform = p_geometry->get_geometry_node()->get_global_transform();
	bounds.inverse_global_transform = bounds.global_transform.affine_inverse();
	bounds.local_aabb = p_geometry->get_geometry_local_aabb();
	bounds.world_origin = bounds.global_transform.origin;
	bounds.world_center = bounds.global_transform.xform(bounds.local_aabb.position + (bounds.local_aabb.size * 0.5f));
	return bounds;
}

Vector3 get_closest_world_point_on_mesh_bounds(const MeshInfluenceBounds &p_bounds, const Vector3 &p_world_position) {
	const Vector3 local_position = p_bounds.inverse_global_transform.xform(p_world_position);
	const Vector3 aabb_min = p_bounds.local_aabb.position;
	const Vector3 aabb_max = p_bounds.local_aabb.position + p_bounds.local_aabb.size;
	const Vector3 clamped_local_position(
			CLAMP(local_position.x, aabb_min.x, aabb_max.x),
			CLAMP(local_position.y, aabb_min.y, aabb_max.y),
			CLAMP(local_position.z, aabb_min.z, aabb_max.z));
	return p_bounds.global_transform.xform(clamped_local_position);
}

Vector3 get_fake_light_direction_vector(const Vector3 &p_light_position, const MeshInfluenceBounds &p_bounds, const LocalLightCandidate &p_candidate) {
	Vector3 to_light = p_light_position - p_bounds.world_center;
	if (to_light.length_squared() <= static_cast<float>(CMP_EPSILON * CMP_EPSILON) &&
			p_candidate.reference_position != p_bounds.world_center) {
		to_light = p_light_position - p_candidate.reference_position;
	}
	return to_light;
}

bool evaluate_point_light_candidate(RLS_PointLight3D *p_light, const MeshInfluenceBounds &p_bounds, LocalLightCandidate &r_candidate) {
	const float color_intensity = compute_light_color_intensity(p_light->get_color()) * p_light->get_energy();
	const Vector3 light_position = p_light->get_global_transform().origin;
	const Vector3 closest_point = get_closest_world_point_on_mesh_bounds(p_bounds, light_position);
	const float closest_distance_squared = closest_point.distance_squared_to(light_position);
	const float closest_distance = Math::sqrt(closest_distance_squared);
	const float closest_score = color_intensity * compute_distance_attenuation(closest_distance, p_light->get_range(), p_light->get_attenuation());

	const float center_distance_squared = p_bounds.world_center.distance_squared_to(light_position);
	const float center_distance = Math::sqrt(center_distance_squared);
	const float center_score = color_intensity * compute_distance_attenuation(center_distance, p_light->get_range(), p_light->get_attenuation());

	const bool use_center = center_score > closest_score;
	const float best_score = use_center ? center_score : closest_score;
	const float best_distance_squared = use_center ? center_distance_squared : closest_distance_squared;
	const Vector3 best_position = use_center ? p_bounds.world_center : closest_point;

	if (best_score <= static_cast<float>(CMP_EPSILON)) {
		return false;
	}

	r_candidate.contribution_score = best_score;
	r_candidate.distance_squared = best_distance_squared;
	r_candidate.reference_position = best_position;
	return true;
}

bool evaluate_spot_light_candidate(RLS_SpotLight3D *p_light, const MeshInfluenceBounds &p_bounds, LocalLightCandidate &r_candidate) {
	const float color_intensity = compute_light_color_intensity(p_light->get_color()) * p_light->get_energy();
	const Vector3 light_origin = p_light->get_global_transform().origin;
	const Vector3 spot_dir = p_light->get_light_direction().normalized();
	const float outer_angle_radians = Math::deg_to_rad(p_light->get_spot_angle());
	const float inner_angle_radians = outer_angle_radians * (1.0f - p_light->get_spot_blend());
	const float inner_cos = Math::cos(inner_angle_radians);
	const float outer_cos = Math::cos(outer_angle_radians);

	float best_score = 0.0f;
	float best_distance_squared = 0.0f;
	Vector3 best_position;

	const Vector3 sample_positions[] = {
		get_closest_world_point_on_mesh_bounds(p_bounds, light_origin),
		p_bounds.world_center,
		p_bounds.world_origin
	};

	for (const Vector3 &sample_position : sample_positions) {
		const Vector3 to_light = light_origin - sample_position;
		const float distance_squared = to_light.length_squared();
		if (distance_squared <= static_cast<float>(CMP_EPSILON * CMP_EPSILON)) {
			continue;
		}

		const float distance = Math::sqrt(distance_squared);
		const float attenuation = compute_distance_attenuation(distance, p_light->get_range(), p_light->get_attenuation());
		if (attenuation <= static_cast<float>(CMP_EPSILON)) {
			continue;
		}

		const Vector3 light_dir = to_light / distance;
		const float cone_dot = spot_dir.dot(-light_dir);

		float cone_attenuation = 0.0f;
		if (inner_cos <= outer_cos + 0.0001f) {
			cone_attenuation = cone_dot >= outer_cos ? 1.0f : 0.0f;
		} else {
			cone_attenuation = Math::smoothstep(outer_cos, inner_cos, cone_dot);
		}

		const float score = color_intensity * attenuation * cone_attenuation;
		if (score <= best_score) {
			continue;
		}

		best_score = score;
		best_distance_squared = distance_squared;
		best_position = sample_position;
	}

	if (best_score <= static_cast<float>(CMP_EPSILON)) {
		return false;
	}

	r_candidate.contribution_score = best_score;
	r_candidate.distance_squared = best_distance_squared;
	r_candidate.reference_position = best_position;
	return true;
}

float compute_spot_cone_attenuation(RLS_SpotLight3D *p_light, const Vector3 &p_sample_position) {
	const Vector3 light_origin = p_light->get_global_transform().origin;
	const Vector3 to_light = light_origin - p_sample_position;
	const float distance_squared = to_light.length_squared();
	if (distance_squared <= static_cast<float>(CMP_EPSILON * CMP_EPSILON)) {
		return 0.0f;
	}

	const Vector3 light_dir = to_light / Math::sqrt(distance_squared);
	const Vector3 spot_dir = p_light->get_light_direction().normalized();
	const float outer_angle_radians = Math::deg_to_rad(p_light->get_spot_angle());
	const float inner_angle_radians = outer_angle_radians * (1.0f - p_light->get_spot_blend());
	const float inner_cos = Math::cos(inner_angle_radians);
	const float outer_cos = Math::cos(outer_angle_radians);
	const float cone_dot = spot_dir.dot(-light_dir);

	if (inner_cos <= outer_cos + 0.0001f) {
		return cone_dot >= outer_cos ? 1.0f : 0.0f;
	}
	return Math::smoothstep(outer_cos, inner_cos, cone_dot);
}

} // namespace

void RLS_VertexLightManager3D::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_ambient_color", "color"), &RLS_VertexLightManager3D::set_ambient_color);
	ClassDB::bind_method(D_METHOD("get_ambient_color"), &RLS_VertexLightManager3D::get_ambient_color);
	ClassDB::bind_method(D_METHOD("set_ambient_energy", "energy"), &RLS_VertexLightManager3D::set_ambient_energy);
	ClassDB::bind_method(D_METHOD("get_ambient_energy"), &RLS_VertexLightManager3D::get_ambient_energy);
	ClassDB::bind_method(D_METHOD("set_max_lights", "max_lights"), &RLS_VertexLightManager3D::set_max_lights);
	ClassDB::bind_method(D_METHOD("get_max_lights"), &RLS_VertexLightManager3D::get_max_lights);

	ADD_PROPERTY(PropertyInfo(Variant::COLOR, "ambient_color"), "set_ambient_color", "get_ambient_color");
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "ambient_energy", PROPERTY_HINT_RANGE, "0.0,8.0,0.01,or_greater"), "set_ambient_energy", "get_ambient_energy");
	ADD_PROPERTY(PropertyInfo(Variant::INT, "max_lights", PROPERTY_HINT_RANGE, "1,8,1"), "set_max_lights", "get_max_lights");
}

void RLS_VertexLightManager3D::_notification(int p_what) {
	switch (p_what) {
		case Node::NOTIFICATION_ENTER_TREE:
			set_process(true);
			lights_dirty = true;
			break;
		case Node::NOTIFICATION_EXIT_TREE:
			set_process(false);
			dirty_geometries.clear();
			point_lights.clear();
			spot_lights.clear();
			directional_lights.clear();
			lit_geometries.clear();
			last_camera_fade_states.clear();
			break;
		case Node::NOTIFICATION_PROCESS:
			if (has_camera_distance_fade_lights(point_lights, spot_lights)) {
				if (update_camera_fade_states(resolve_active_camera(this), point_lights, spot_lights, last_camera_fade_states)) {
					lights_dirty = true;
				}
			} else if (!last_camera_fade_states.empty()) {
				last_camera_fade_states.clear();
			}

			if (lights_dirty) {
				_rebuild_all_geometries();
			} else {
				_rebuild_dirty_geometries();
			}
			break;
		default:
			break;
	}
}

void RLS_VertexLightManager3D::set_ambient_color(const Color &p_color) {
	if (ambient_color == p_color) {
		return;
	}
	ambient_color = p_color;
	notify_light_changed();
}

Color RLS_VertexLightManager3D::get_ambient_color() const {
	return ambient_color;
}

void RLS_VertexLightManager3D::set_ambient_energy(float p_energy) {
	if (Math::is_equal_approx(ambient_energy, p_energy)) {
		return;
	}
	ambient_energy = p_energy;
	notify_light_changed();
}

float RLS_VertexLightManager3D::get_ambient_energy() const {
	return ambient_energy;
}

void RLS_VertexLightManager3D::set_max_lights(int32_t p_max_lights) {
	const int32_t clamped = CLAMP(p_max_lights, 1, MAX_SUPPORTED_LIGHTS);
	if (max_lights == clamped) {
		return;
	}
	max_lights = clamped;
	notify_light_changed();
}

int32_t RLS_VertexLightManager3D::get_max_lights() const {
	return max_lights;
}

void RLS_VertexLightManager3D::register_point_light(RLS_PointLight3D *p_light) {
	if (p_light == nullptr || point_lights.find(p_light) != -1) {
		return;
	}
	point_lights.push_back(p_light);
	notify_light_changed();
}

void RLS_VertexLightManager3D::unregister_point_light(RLS_PointLight3D *p_light) {
	if (_remove_point_light(point_lights, p_light)) {
		notify_light_changed();
	}
}

void RLS_VertexLightManager3D::register_spot_light(RLS_SpotLight3D *p_light) {
	if (p_light == nullptr || spot_lights.find(p_light) != -1) {
		return;
	}
	spot_lights.push_back(p_light);
	notify_light_changed();
}

void RLS_VertexLightManager3D::unregister_spot_light(RLS_SpotLight3D *p_light) {
	if (_remove_spot_light(spot_lights, p_light)) {
		notify_light_changed();
	}
}

void RLS_VertexLightManager3D::register_directional_light(RLS_DirectionalLight3D *p_light) {
	if (p_light == nullptr || directional_lights.find(p_light) != -1) {
		return;
	}
	directional_lights.push_back(p_light);
	notify_light_changed();
}

void RLS_VertexLightManager3D::unregister_directional_light(RLS_DirectionalLight3D *p_light) {
	if (_remove_directional_light(directional_lights, p_light)) {
		notify_light_changed();
	}
}

void RLS_VertexLightManager3D::register_lit_geometry(RLS_LitGeometryInstance *p_geometry) {
	if (p_geometry == nullptr || lit_geometries.find(p_geometry) != -1) {
		return;
	}
	lit_geometries.push_back(p_geometry);
	dirty_geometries.insert(p_geometry);
}

void RLS_VertexLightManager3D::unregister_lit_geometry(RLS_LitGeometryInstance *p_geometry) {
	if (_remove_lit_geometry(lit_geometries, p_geometry)) {
		dirty_geometries.erase(p_geometry);
	}
}

void RLS_VertexLightManager3D::notify_light_changed() {
	lights_dirty = true;
}

void RLS_VertexLightManager3D::notify_geometry_changed(RLS_LitGeometryInstance *p_geometry) {
	if (p_geometry == nullptr) {
		return;
	}
	dirty_geometries.insert(p_geometry);
}

bool RLS_VertexLightManager3D::_remove_point_light(Vector<RLS_PointLight3D *> &p_lights, RLS_PointLight3D *p_light) {
	return remove_from_vector(p_lights, p_light);
}

bool RLS_VertexLightManager3D::_remove_spot_light(Vector<RLS_SpotLight3D *> &p_lights, RLS_SpotLight3D *p_light) {
	return remove_from_vector(p_lights, p_light);
}

bool RLS_VertexLightManager3D::_remove_directional_light(Vector<RLS_DirectionalLight3D *> &p_lights, RLS_DirectionalLight3D *p_light) {
	return remove_from_vector(p_lights, p_light);
}

bool RLS_VertexLightManager3D::_remove_lit_geometry(Vector<RLS_LitGeometryInstance *> &p_geometries, RLS_LitGeometryInstance *p_geometry) {
	return remove_from_vector(p_geometries, p_geometry);
}

void RLS_VertexLightManager3D::_mark_all_geometries_dirty() {
	for (RLS_LitGeometryInstance *geometry : lit_geometries) {
		if (geometry != nullptr) {
			dirty_geometries.insert(geometry);
		}
	}
}

void RLS_VertexLightManager3D::_rebuild_all_geometries() {
	_mark_all_geometries_dirty();
	lights_dirty = false;
	_rebuild_dirty_geometries();
}

void RLS_VertexLightManager3D::_rebuild_dirty_geometries() {
	if (dirty_geometries.is_empty()) {
		return;
	}

	Vector<RLS_LitGeometryInstance *> pending_geometries;
	int32_t pending_count = 0;
	for (RLS_LitGeometryInstance *geometry : dirty_geometries) {
		if (pending_count >= MAX_GEOMETRY_UPDATES_PER_FRAME) {
			break;
		}
		pending_geometries.push_back(geometry);
		pending_count++;
	}

	for (RLS_LitGeometryInstance *geometry : pending_geometries) {
		dirty_geometries.erase(geometry);
	}

	for (RLS_LitGeometryInstance *geometry : pending_geometries) {
		const Node3D *geometry_node = geometry == nullptr ? nullptr : geometry->get_geometry_node();
		if (geometry_node == nullptr || !geometry_node->is_inside_tree()) {
			continue;
		}
		_apply_geometry_lighting(geometry);
	}
}

void RLS_VertexLightManager3D::_apply_geometry_lighting(RLS_LitGeometryInstance *p_geometry) {
	Ref<ShaderMaterial> material = p_geometry->get_runtime_shader_material();
	const Vector<Ref<ShaderMaterial>> &surface_materials = p_geometry->get_runtime_surface_shader_materials();
	if (material.is_null() && surface_materials.is_empty()) {
		return;
	}

	Camera3D *active_camera = resolve_active_camera(this);
	const bool has_active_camera = active_camera != nullptr;
	const Vector3 active_camera_position = has_active_camera ? active_camera->get_global_transform().origin : Vector3();

	std::array<Vector4, MAX_SUPPORTED_LIGHTS> light_vector_type;
	std::array<Vector4, MAX_SUPPORTED_LIGHTS> light_color_energy;
	std::array<Vector4, MAX_SUPPORTED_LIGHTS> light_spot_direction_inner;
	std::array<float, MAX_SUPPORTED_LIGHTS> light_range;
	std::array<float, MAX_SUPPORTED_LIGHTS> light_attenuation;
	std::array<float, MAX_SUPPORTED_LIGHTS> light_spot_outer_cos;

	for (int32_t i = 0; i < MAX_SUPPORTED_LIGHTS; i++) {
		light_vector_type[i] = Vector4();
		light_color_energy[i] = Vector4();
		light_spot_direction_inner[i] = Vector4();
		light_range[i] = 0.0f;
		light_attenuation[i] = 1.0f;
		light_spot_outer_cos[i] = -1.0f;
	}

	int32_t light_count = 0;

	for (RLS_DirectionalLight3D *light : directional_lights) {
		if (light == nullptr || !light->is_enabled()) {
			continue;
		}
		if (light_count >= max_lights) {
			break;
		}

		const Vector3 direction = light->get_light_direction();
		const Color color = light->get_color();
		light_vector_type[light_count] = Vector4(direction.x, direction.y, direction.z, 1.0f);
		light_color_energy[light_count] = Vector4(color.r, color.g, color.b, light->get_energy());
		light_range[light_count] = 0.0f;
		light_attenuation[light_count] = 1.0f;
		light_spot_direction_inner[light_count] = Vector4();
		light_spot_outer_cos[light_count] = -1.0f;
		light_count++;
	}

	if (light_count < max_lights) {
		std::vector<LocalLightCandidate> local_candidates;
		local_candidates.reserve(point_lights.size() + spot_lights.size());
		const MeshInfluenceBounds mesh_bounds = build_mesh_influence_bounds(p_geometry);

		for (RLS_PointLight3D *light : point_lights) {
			if (light == nullptr || !light->is_enabled()) {
				continue;
			}

			LocalLightCandidate candidate;
			candidate.type = LocalLightCandidate::Type::POINT;
			candidate.point_light = light;
			if (!evaluate_point_light_candidate(light, mesh_bounds, candidate)) {
				continue;
			}

			if (has_active_camera && light->is_distance_fade_enabled()) {
				const float camera_distance = active_camera_position.distance_to(light->get_global_transform().origin);
				candidate.camera_fade_factor = compute_camera_distance_fade(camera_distance, true, light->get_distance_fade_begin(), light->get_distance_fade_length());
				candidate.contribution_score *= candidate.camera_fade_factor;
				if (candidate.contribution_score <= static_cast<float>(CMP_EPSILON)) {
					continue;
				}
			}

			local_candidates.push_back(candidate);
		}

		for (RLS_SpotLight3D *light : spot_lights) {
			if (light == nullptr || !light->is_enabled()) {
				continue;
			}

			LocalLightCandidate candidate;
			candidate.type = LocalLightCandidate::Type::SPOT;
			candidate.spot_light = light;
			if (!evaluate_spot_light_candidate(light, mesh_bounds, candidate)) {
				continue;
			}

			if (has_active_camera && light->is_distance_fade_enabled()) {
				const float camera_distance = active_camera_position.distance_to(light->get_global_transform().origin);
				candidate.camera_fade_factor = compute_camera_distance_fade(camera_distance, true, light->get_distance_fade_begin(), light->get_distance_fade_length());
				candidate.contribution_score *= candidate.camera_fade_factor;
				if (candidate.contribution_score <= static_cast<float>(CMP_EPSILON)) {
					continue;
				}
			}

			local_candidates.push_back(candidate);
		}

		// Rank by estimated influence at the mesh bounds so closer but fully
		// culled lights do not steal one of the limited local-light slots.
		std::sort(local_candidates.begin(), local_candidates.end(), [](const LocalLightCandidate &p_a, const LocalLightCandidate &p_b) {
			if (!Math::is_equal_approx(p_a.contribution_score, p_b.contribution_score)) {
				return p_a.contribution_score > p_b.contribution_score;
			}
			return p_a.distance_squared < p_b.distance_squared;
		});

		for (const LocalLightCandidate &candidate : local_candidates) {
			if (light_count >= max_lights) {
				break;
			}

			if (candidate.type == LocalLightCandidate::Type::POINT) {
				RLS_PointLight3D *light = candidate.point_light;
				const Vector3 position = light->get_global_transform().origin;
				const Color color = light->get_color();

				if (light->is_fake_point_light() && !p_geometry->is_ignoring_fake_lights()) {
					const Vector3 to_light = get_fake_light_direction_vector(position, mesh_bounds, candidate);
					const float direction_distance_squared = to_light.length_squared();
					if (direction_distance_squared <= static_cast<float>(CMP_EPSILON * CMP_EPSILON)) {
						continue;
					}

					const float distance = Math::sqrt(candidate.distance_squared);
					const float range = MAX(light->get_range(), 0.0001f);
					const float exponent = light->get_attenuation() > 0.0f ? light->get_attenuation() : 1.0f;
					const float attenuation = Math::pow(1.0f - Math::smoothstep(0.0f, range, distance), exponent);
					if (attenuation <= static_cast<float>(CMP_EPSILON)) {
						continue;
					}

					const Vector3 direction = to_light.normalized();
					light_vector_type[light_count] = Vector4(direction.x, direction.y, direction.z, 1.0f);
					light_color_energy[light_count] = Vector4(color.r, color.g, color.b, light->get_energy() * attenuation * candidate.camera_fade_factor);
					light_range[light_count] = 0.0f;
					light_attenuation[light_count] = 1.0f;
					light_spot_direction_inner[light_count] = Vector4();
					light_spot_outer_cos[light_count] = -1.0f;
				} else {
					light_vector_type[light_count] = Vector4(position.x, position.y, position.z, 0.0f);
					light_color_energy[light_count] = Vector4(color.r, color.g, color.b, light->get_energy() * candidate.camera_fade_factor);
					light_range[light_count] = light->get_range();
					light_attenuation[light_count] = light->get_attenuation();
					light_spot_direction_inner[light_count] = Vector4();
					light_spot_outer_cos[light_count] = -1.0f;
				}
			} else {
				RLS_SpotLight3D *light = candidate.spot_light;
				const Vector3 position = light->get_global_transform().origin;
				const Color color = light->get_color();
				if (light->is_fake_spot_light() && !p_geometry->is_ignoring_fake_lights()) {
					const Vector3 to_light = get_fake_light_direction_vector(position, mesh_bounds, candidate);
					const float direction_distance_squared = to_light.length_squared();
					if (direction_distance_squared <= static_cast<float>(CMP_EPSILON * CMP_EPSILON)) {
						continue;
					}

					const float distance = Math::sqrt(candidate.distance_squared);
					const float range = MAX(light->get_range(), 0.0001f);
					const float exponent = light->get_attenuation() > 0.0f ? light->get_attenuation() : 1.0f;
					const float distance_attenuation = Math::pow(1.0f - Math::smoothstep(0.0f, range, distance), exponent);
					const float cone_attenuation = compute_spot_cone_attenuation(light, candidate.reference_position);
					const float final_attenuation = distance_attenuation * cone_attenuation;
					if (final_attenuation <= static_cast<float>(CMP_EPSILON)) {
						continue;
					}

					const Vector3 direction = to_light.normalized();
					light_vector_type[light_count] = Vector4(direction.x, direction.y, direction.z, 1.0f);
					light_color_energy[light_count] = Vector4(color.r, color.g, color.b, light->get_energy() * final_attenuation * candidate.camera_fade_factor);
					light_range[light_count] = 0.0f;
					light_attenuation[light_count] = 1.0f;
					light_spot_direction_inner[light_count] = Vector4();
					light_spot_outer_cos[light_count] = -1.0f;
				} else {
					const Vector3 direction = light->get_light_direction();
					const float outer_angle_radians = Math::deg_to_rad(light->get_spot_angle());
					const float inner_angle_radians = outer_angle_radians * (1.0f - light->get_spot_blend());
					const float inner_cos = Math::cos(inner_angle_radians);
					const float outer_cos = Math::cos(outer_angle_radians);

					light_vector_type[light_count] = Vector4(position.x, position.y, position.z, 2.0f);
					light_color_energy[light_count] = Vector4(color.r, color.g, color.b, light->get_energy() * candidate.camera_fade_factor);
					light_range[light_count] = light->get_range();
					light_attenuation[light_count] = light->get_attenuation();
					light_spot_direction_inner[light_count] = Vector4(direction.x, direction.y, direction.z, inner_cos);
					light_spot_outer_cos[light_count] = outer_cos;
				}
			}

			light_count++;
		}
	}

	PackedVector4Array packed_vector_type;
	PackedVector4Array packed_color_energy;
	PackedVector4Array packed_spot_direction_inner;
	PackedFloat32Array packed_range;
	PackedFloat32Array packed_attenuation;
	PackedFloat32Array packed_spot_outer_cos;
	packed_vector_type.resize(MAX_SUPPORTED_LIGHTS);
	packed_color_energy.resize(MAX_SUPPORTED_LIGHTS);
	packed_spot_direction_inner.resize(MAX_SUPPORTED_LIGHTS);
	packed_range.resize(MAX_SUPPORTED_LIGHTS);
	packed_attenuation.resize(MAX_SUPPORTED_LIGHTS);
	packed_spot_outer_cos.resize(MAX_SUPPORTED_LIGHTS);

	for (int32_t i = 0; i < MAX_SUPPORTED_LIGHTS; i++) {
		packed_vector_type.set(i, light_vector_type[i]);
		packed_color_energy.set(i, light_color_energy[i]);
		packed_spot_direction_inner.set(i, light_spot_direction_inner[i]);
		packed_range.set(i, light_range[i]);
		packed_attenuation.set(i, light_attenuation[i]);
		packed_spot_outer_cos.set(i, light_spot_outer_cos[i]);
	}

	const Vector4 global_ambient(ambient_color.r, ambient_color.g, ambient_color.b, ambient_energy);
	if (!p_geometry->update_cached_light_state(light_count, packed_vector_type, packed_color_energy, packed_spot_direction_inner, packed_range, packed_attenuation, packed_spot_outer_cos, global_ambient)) {
		return;
	}

	if (material.is_valid()) {
		material->set_shader_parameter(StringName("light_count"), light_count);
		material->set_shader_parameter(StringName("light_vector_type"), packed_vector_type);
		material->set_shader_parameter(StringName("light_color_energy"), packed_color_energy);
		material->set_shader_parameter(StringName("light_spot_direction_inner"), packed_spot_direction_inner);
		material->set_shader_parameter(StringName("light_range"), packed_range);
		material->set_shader_parameter(StringName("light_attenuation"), packed_attenuation);
		material->set_shader_parameter(StringName("light_spot_outer_cos"), packed_spot_outer_cos);
		material->set_shader_parameter(StringName("global_ambient"), global_ambient);
	}

	for (const Ref<ShaderMaterial> &surface_material : surface_materials) {
		if (surface_material.is_null()) {
			continue;
		}
		surface_material->set_shader_parameter(StringName("light_count"), light_count);
		surface_material->set_shader_parameter(StringName("light_vector_type"), packed_vector_type);
		surface_material->set_shader_parameter(StringName("light_color_energy"), packed_color_energy);
		surface_material->set_shader_parameter(StringName("light_spot_direction_inner"), packed_spot_direction_inner);
		surface_material->set_shader_parameter(StringName("light_range"), packed_range);
		surface_material->set_shader_parameter(StringName("light_attenuation"), packed_attenuation);
		surface_material->set_shader_parameter(StringName("light_spot_outer_cos"), packed_spot_outer_cos);
		surface_material->set_shader_parameter(StringName("global_ambient"), global_ambient);
	}
}

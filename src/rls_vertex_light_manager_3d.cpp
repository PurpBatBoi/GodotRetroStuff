#include "rls_vertex_light_manager_3d.h"

#include "rls_directional_light_3d.h"
#include "rls_lit_mesh_instance_3d.h"
#include "rls_point_light_3d.h"
#include "rls_spot_light_3d.h"

#include <godot_cpp/classes/mesh.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/math.hpp>

#include <algorithm>
#include <array>
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

struct LocalLightCandidate {
	enum class Type {
		POINT,
		SPOT
	};

	Type type = Type::POINT;
	RLS_PointLight3D *point_light = nullptr;
	RLS_SpotLight3D *spot_light = nullptr;
	float contribution_score = 0.0f;
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

MeshInfluenceBounds build_mesh_influence_bounds(RLS_LitMeshInstance3D *p_mesh) {
	MeshInfluenceBounds bounds;
	if (p_mesh == nullptr) {
		return bounds;
	}

	bounds.global_transform = p_mesh->get_global_transform();
	bounds.inverse_global_transform = bounds.global_transform.affine_inverse();
	bounds.local_aabb = p_mesh->get_aabb();
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
			dirty_meshes.clear();
			point_lights.clear();
			spot_lights.clear();
			directional_lights.clear();
			lit_meshes.clear();
			break;
		case Node::NOTIFICATION_PROCESS:
			if (lights_dirty) {
				_rebuild_all_meshes();
			} else {
				_rebuild_dirty_meshes();
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

void RLS_VertexLightManager3D::register_lit_mesh(RLS_LitMeshInstance3D *p_mesh) {
	if (p_mesh == nullptr || lit_meshes.find(p_mesh) != -1) {
		return;
	}
	lit_meshes.push_back(p_mesh);
	dirty_meshes.insert(p_mesh);
}

void RLS_VertexLightManager3D::unregister_lit_mesh(RLS_LitMeshInstance3D *p_mesh) {
	if (_remove_lit_mesh(lit_meshes, p_mesh)) {
		dirty_meshes.erase(p_mesh);
	}
}

void RLS_VertexLightManager3D::notify_light_changed() {
	lights_dirty = true;
}

void RLS_VertexLightManager3D::notify_mesh_changed(RLS_LitMeshInstance3D *p_mesh) {
	if (p_mesh == nullptr) {
		return;
	}
	dirty_meshes.insert(p_mesh);
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

bool RLS_VertexLightManager3D::_remove_lit_mesh(Vector<RLS_LitMeshInstance3D *> &p_meshes, RLS_LitMeshInstance3D *p_mesh) {
	return remove_from_vector(p_meshes, p_mesh);
}

void RLS_VertexLightManager3D::_mark_all_meshes_dirty() {
	for (RLS_LitMeshInstance3D *mesh : lit_meshes) {
		if (mesh != nullptr) {
			dirty_meshes.insert(mesh);
		}
	}
}

void RLS_VertexLightManager3D::_rebuild_all_meshes() {
	_mark_all_meshes_dirty();
	lights_dirty = false;
	_rebuild_dirty_meshes();
}

void RLS_VertexLightManager3D::_rebuild_dirty_meshes() {
	if (dirty_meshes.is_empty()) {
		return;
	}

	Vector<RLS_LitMeshInstance3D *> pending_meshes;
	for (RLS_LitMeshInstance3D *mesh : dirty_meshes) {
		pending_meshes.push_back(mesh);
	}
	dirty_meshes.clear();

	for (RLS_LitMeshInstance3D *mesh : pending_meshes) {
		if (mesh == nullptr || !mesh->is_inside_tree()) {
			continue;
		}
		_apply_mesh_lighting(mesh);
	}
}

void RLS_VertexLightManager3D::_apply_mesh_lighting(RLS_LitMeshInstance3D *p_mesh) {
	Ref<ShaderMaterial> material = p_mesh->get_runtime_shader_material();
	const Vector<Ref<ShaderMaterial>> &surface_materials = p_mesh->get_runtime_surface_shader_materials();
	if (material.is_null() && surface_materials.is_empty()) {
		return;
	}

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
	const Vector3 mesh_origin = p_mesh->get_global_transform().origin;

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
		const MeshInfluenceBounds mesh_bounds = build_mesh_influence_bounds(p_mesh);

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

				if (light->is_fake_point_light() && !p_mesh->is_ignoring_fake_lights()) {
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
					light_color_energy[light_count] = Vector4(color.r, color.g, color.b, light->get_energy() * attenuation);
					light_range[light_count] = 0.0f;
					light_attenuation[light_count] = 1.0f;
					light_spot_direction_inner[light_count] = Vector4();
					light_spot_outer_cos[light_count] = -1.0f;
				} else {
					light_vector_type[light_count] = Vector4(position.x, position.y, position.z, 0.0f);
					light_color_energy[light_count] = Vector4(color.r, color.g, color.b, light->get_energy());
					light_range[light_count] = light->get_range();
					light_attenuation[light_count] = light->get_attenuation();
					light_spot_direction_inner[light_count] = Vector4();
					light_spot_outer_cos[light_count] = -1.0f;
				}
			} else {
				RLS_SpotLight3D *light = candidate.spot_light;
				const Vector3 position = light->get_global_transform().origin;
				const Color color = light->get_color();
				if (light->is_fake_spot_light() && !p_mesh->is_ignoring_fake_lights()) {
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
					light_color_energy[light_count] = Vector4(color.r, color.g, color.b, light->get_energy() * final_attenuation);
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
					light_color_energy[light_count] = Vector4(color.r, color.g, color.b, light->get_energy());
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
	if (!p_mesh->update_cached_light_state(light_count, packed_vector_type, packed_color_energy, packed_spot_direction_inner, packed_range, packed_attenuation, packed_spot_outer_cos, global_ambient)) {
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

#include "n64_vertex_light_manager_3d.h"

#include "n64_directional_light_3d.h"
#include "n64_lit_mesh_instance_3d.h"
#include "n64_point_light_3d.h"
#include "n64_spot_light_3d.h"

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
	N64PointLight3D *point_light = nullptr;
	N64SpotLight3D *spot_light = nullptr;
	float distance_squared = 0.0f;
};

} // namespace

void N64VertexLightManager3D::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_ambient_color", "color"), &N64VertexLightManager3D::set_ambient_color);
	ClassDB::bind_method(D_METHOD("get_ambient_color"), &N64VertexLightManager3D::get_ambient_color);
	ClassDB::bind_method(D_METHOD("set_ambient_energy", "energy"), &N64VertexLightManager3D::set_ambient_energy);
	ClassDB::bind_method(D_METHOD("get_ambient_energy"), &N64VertexLightManager3D::get_ambient_energy);
	ClassDB::bind_method(D_METHOD("set_max_lights", "max_lights"), &N64VertexLightManager3D::set_max_lights);
	ClassDB::bind_method(D_METHOD("get_max_lights"), &N64VertexLightManager3D::get_max_lights);

	ADD_PROPERTY(PropertyInfo(Variant::COLOR, "ambient_color"), "set_ambient_color", "get_ambient_color");
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "ambient_energy", PROPERTY_HINT_RANGE, "0.0,8.0,0.01,or_greater"), "set_ambient_energy", "get_ambient_energy");
	ADD_PROPERTY(PropertyInfo(Variant::INT, "max_lights", PROPERTY_HINT_RANGE, "1,8,1"), "set_max_lights", "get_max_lights");
}

void N64VertexLightManager3D::_notification(int p_what) {
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

void N64VertexLightManager3D::set_ambient_color(const Color &p_color) {
	if (ambient_color == p_color) {
		return;
	}
	ambient_color = p_color;
	notify_light_changed();
}

Color N64VertexLightManager3D::get_ambient_color() const {
	return ambient_color;
}

void N64VertexLightManager3D::set_ambient_energy(float p_energy) {
	if (Math::is_equal_approx(ambient_energy, p_energy)) {
		return;
	}
	ambient_energy = p_energy;
	notify_light_changed();
}

float N64VertexLightManager3D::get_ambient_energy() const {
	return ambient_energy;
}

void N64VertexLightManager3D::set_max_lights(int32_t p_max_lights) {
	const int32_t clamped = CLAMP(p_max_lights, 1, MAX_SUPPORTED_LIGHTS);
	if (max_lights == clamped) {
		return;
	}
	max_lights = clamped;
	notify_light_changed();
}

int32_t N64VertexLightManager3D::get_max_lights() const {
	return max_lights;
}

void N64VertexLightManager3D::register_point_light(N64PointLight3D *p_light) {
	if (p_light == nullptr || point_lights.find(p_light) != -1) {
		return;
	}
	point_lights.push_back(p_light);
	notify_light_changed();
}

void N64VertexLightManager3D::unregister_point_light(N64PointLight3D *p_light) {
	if (_remove_point_light(point_lights, p_light)) {
		notify_light_changed();
	}
}

void N64VertexLightManager3D::register_spot_light(N64SpotLight3D *p_light) {
	if (p_light == nullptr || spot_lights.find(p_light) != -1) {
		return;
	}
	spot_lights.push_back(p_light);
	notify_light_changed();
}

void N64VertexLightManager3D::unregister_spot_light(N64SpotLight3D *p_light) {
	if (_remove_spot_light(spot_lights, p_light)) {
		notify_light_changed();
	}
}

void N64VertexLightManager3D::register_directional_light(N64DirectionalLight3D *p_light) {
	if (p_light == nullptr || directional_lights.find(p_light) != -1) {
		return;
	}
	directional_lights.push_back(p_light);
	notify_light_changed();
}

void N64VertexLightManager3D::unregister_directional_light(N64DirectionalLight3D *p_light) {
	if (_remove_directional_light(directional_lights, p_light)) {
		notify_light_changed();
	}
}

void N64VertexLightManager3D::register_lit_mesh(N64LitMeshInstance3D *p_mesh) {
	if (p_mesh == nullptr || lit_meshes.find(p_mesh) != -1) {
		return;
	}
	lit_meshes.push_back(p_mesh);
	dirty_meshes.insert(p_mesh);
}

void N64VertexLightManager3D::unregister_lit_mesh(N64LitMeshInstance3D *p_mesh) {
	if (_remove_lit_mesh(lit_meshes, p_mesh)) {
		dirty_meshes.erase(p_mesh);
	}
}

void N64VertexLightManager3D::notify_light_changed() {
	lights_dirty = true;
}

void N64VertexLightManager3D::notify_mesh_changed(N64LitMeshInstance3D *p_mesh) {
	if (p_mesh == nullptr) {
		return;
	}
	dirty_meshes.insert(p_mesh);
}

bool N64VertexLightManager3D::_remove_point_light(Vector<N64PointLight3D *> &p_lights, N64PointLight3D *p_light) {
	return remove_from_vector(p_lights, p_light);
}

bool N64VertexLightManager3D::_remove_spot_light(Vector<N64SpotLight3D *> &p_lights, N64SpotLight3D *p_light) {
	return remove_from_vector(p_lights, p_light);
}

bool N64VertexLightManager3D::_remove_directional_light(Vector<N64DirectionalLight3D *> &p_lights, N64DirectionalLight3D *p_light) {
	return remove_from_vector(p_lights, p_light);
}

bool N64VertexLightManager3D::_remove_lit_mesh(Vector<N64LitMeshInstance3D *> &p_meshes, N64LitMeshInstance3D *p_mesh) {
	return remove_from_vector(p_meshes, p_mesh);
}

void N64VertexLightManager3D::_mark_all_meshes_dirty() {
	for (N64LitMeshInstance3D *mesh : lit_meshes) {
		if (mesh != nullptr) {
			dirty_meshes.insert(mesh);
		}
	}
}

void N64VertexLightManager3D::_rebuild_all_meshes() {
	_mark_all_meshes_dirty();
	lights_dirty = false;
	_rebuild_dirty_meshes();
}

void N64VertexLightManager3D::_rebuild_dirty_meshes() {
	if (dirty_meshes.is_empty()) {
		return;
	}

	Vector<N64LitMeshInstance3D *> pending_meshes;
	for (N64LitMeshInstance3D *mesh : dirty_meshes) {
		pending_meshes.push_back(mesh);
	}
	dirty_meshes.clear();

	for (N64LitMeshInstance3D *mesh : pending_meshes) {
		if (mesh == nullptr || !mesh->is_inside_tree()) {
			continue;
		}
		_apply_mesh_lighting(mesh);
	}
}

void N64VertexLightManager3D::_apply_mesh_lighting(N64LitMeshInstance3D *p_mesh) {
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

	for (N64DirectionalLight3D *light : directional_lights) {
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

		for (N64PointLight3D *light : point_lights) {
			if (light == nullptr || !light->is_enabled()) {
				continue;
			}

			LocalLightCandidate candidate;
			candidate.type = LocalLightCandidate::Type::POINT;
			candidate.point_light = light;
			candidate.distance_squared = mesh_origin.distance_squared_to(light->get_global_transform().origin);
			local_candidates.push_back(candidate);
		}

		for (N64SpotLight3D *light : spot_lights) {
			if (light == nullptr || !light->is_enabled()) {
				continue;
			}

			LocalLightCandidate candidate;
			candidate.type = LocalLightCandidate::Type::SPOT;
			candidate.spot_light = light;
			candidate.distance_squared = mesh_origin.distance_squared_to(light->get_global_transform().origin);
			local_candidates.push_back(candidate);
		}

		std::sort(local_candidates.begin(), local_candidates.end(), [](const LocalLightCandidate &p_a, const LocalLightCandidate &p_b) {
			return p_a.distance_squared < p_b.distance_squared;
		});

		for (const LocalLightCandidate &candidate : local_candidates) {
			if (light_count >= max_lights) {
				break;
			}

			if (candidate.type == LocalLightCandidate::Type::POINT) {
				N64PointLight3D *light = candidate.point_light;
				const Vector3 position = light->get_global_transform().origin;
				const Color color = light->get_color();

				if (light->is_fake_point_light() && !p_mesh->is_ignoring_fake_point_lights()) {
					const Vector3 to_light = position - mesh_origin;
					const float distance_squared = to_light.length_squared();
					if (distance_squared <= static_cast<float>(CMP_EPSILON * CMP_EPSILON)) {
						continue;
					}

					const float distance = Math::sqrt(distance_squared);
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
				N64SpotLight3D *light = candidate.spot_light;
				const Vector3 position = light->get_global_transform().origin;
				const Vector3 direction = light->get_light_direction();
				const Color color = light->get_color();
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

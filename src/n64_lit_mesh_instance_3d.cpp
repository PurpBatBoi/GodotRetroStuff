#include "n64_lit_mesh_instance_3d.h"

#include "n64_vertex_light_manager_3d.h"

#include <godot_cpp/classes/mesh.hpp>
#include <godot_cpp/classes/material.hpp>
#include <godot_cpp/classes/resource.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/object.hpp>

using namespace godot;

namespace {

N64VertexLightManager3D *find_manager_ancestor(Node *p_node) {
	Node *current = p_node == nullptr ? nullptr : p_node->get_parent();
	while (current != nullptr) {
		if (N64VertexLightManager3D *manager = Object::cast_to<N64VertexLightManager3D>(current)) {
			return manager;
		}
		current = current->get_parent();
	}
	return nullptr;
}

} // namespace

N64LitMeshInstance3D::N64LitMeshInstance3D() {
	set_notify_transform(true);
}

void N64LitMeshInstance3D::_bind_methods() {
}

void N64LitMeshInstance3D::_notification(int p_what) {
	switch (p_what) {
		case Node::NOTIFICATION_ENTER_TREE:
			set_process_internal(true);
			_sync_runtime_shader_material();
			cached_ignore_fake_lights = _compute_ignore_fake_lights();
			_reconnect_manager();
			notify_runtime_material_changed();
			break;
		case Node::NOTIFICATION_EXIT_TREE:
			set_process_internal(false);
			if (manager != nullptr) {
				manager->unregister_lit_mesh(this);
				manager = nullptr;
			}
			runtime_shader_material.unref();
			runtime_surface_shader_materials.clear();
			last_material_instance_id = 0;
			last_surface_material_instance_ids.clear();
			cached_ignore_fake_lights = false;
			clear_cached_light_state();
			break;
		case Node::NOTIFICATION_PARENTED:
			_reconnect_manager();
			break;
		case Node::NOTIFICATION_UNPARENTED:
			if (manager != nullptr) {
				manager->unregister_lit_mesh(this);
				manager = nullptr;
			}
			break;
		case Node::NOTIFICATION_INTERNAL_PROCESS:
			if (_sync_runtime_shader_material()) {
				cached_ignore_fake_lights = _compute_ignore_fake_lights();
				notify_runtime_material_changed();
			} else {
				const bool ignore_fake_lights = _compute_ignore_fake_lights();
				if (ignore_fake_lights != cached_ignore_fake_lights) {
					cached_ignore_fake_lights = ignore_fake_lights;
					notify_runtime_material_changed();
				}
			}
			break;
		case Node3D::NOTIFICATION_TRANSFORM_CHANGED:
			if (manager != nullptr) {
				manager->notify_mesh_changed(this);
			}
			break;
		default:
			break;
	}
}

Ref<ShaderMaterial> N64LitMeshInstance3D::get_runtime_shader_material() const {
	return runtime_shader_material;
}

const Vector<Ref<ShaderMaterial>> &N64LitMeshInstance3D::get_runtime_surface_shader_materials() const {
	return runtime_surface_shader_materials;
}

bool N64LitMeshInstance3D::is_ignoring_fake_lights() const {
	return cached_ignore_fake_lights;
}

bool N64LitMeshInstance3D::update_cached_light_state(int32_t p_light_count, const PackedVector4Array &p_light_vector_type, const PackedVector4Array &p_light_color_energy, const PackedVector4Array &p_light_spot_direction_inner, const PackedFloat32Array &p_light_range, const PackedFloat32Array &p_light_attenuation, const PackedFloat32Array &p_light_spot_outer_cos, const Vector4 &p_global_ambient) {
	if (cached_light_count == p_light_count &&
			cached_light_vector_type == p_light_vector_type &&
			cached_light_color_energy == p_light_color_energy &&
			cached_light_spot_direction_inner == p_light_spot_direction_inner &&
			cached_light_range == p_light_range &&
			cached_light_attenuation == p_light_attenuation &&
			cached_light_spot_outer_cos == p_light_spot_outer_cos &&
			cached_global_ambient == p_global_ambient) {
		return false;
	}

	cached_light_count = p_light_count;
	cached_light_vector_type = p_light_vector_type;
	cached_light_color_energy = p_light_color_energy;
	cached_light_spot_direction_inner = p_light_spot_direction_inner;
	cached_light_range = p_light_range;
	cached_light_attenuation = p_light_attenuation;
	cached_light_spot_outer_cos = p_light_spot_outer_cos;
	cached_global_ambient = p_global_ambient;
	return true;
}

void N64LitMeshInstance3D::clear_cached_light_state() {
	cached_light_count = -1;
	cached_light_vector_type.clear();
	cached_light_color_energy.clear();
	cached_light_spot_direction_inner.clear();
	cached_light_range.clear();
	cached_light_attenuation.clear();
	cached_light_spot_outer_cos.clear();
	cached_global_ambient = Vector4();
}

void N64LitMeshInstance3D::notify_runtime_material_changed() {
	clear_cached_light_state();
	if (manager != nullptr) {
		manager->notify_mesh_changed(this);
	}
}

void N64LitMeshInstance3D::_reconnect_manager() {
	N64VertexLightManager3D *new_manager = find_manager_ancestor(this);
	if (new_manager == manager) {
		return;
	}
	if (manager != nullptr) {
		manager->unregister_lit_mesh(this);
	}
	manager = new_manager;
	if (manager != nullptr) {
		manager->register_lit_mesh(this);
	}
}

bool N64LitMeshInstance3D::_sync_runtime_shader_material() {
	bool changed = false;

	Ref<Material> current_material = get_material_override();
	const uint64_t current_id = current_material.is_valid() ? current_material->get_instance_id() : 0;

	if (current_id != last_material_instance_id) {
		last_material_instance_id = current_id;
		changed = true;

		if (current_material.is_null()) {
			runtime_shader_material.unref();
		} else {
			Ref<ShaderMaterial> shader_material = current_material;
			if (shader_material.is_null()) {
				runtime_shader_material.unref();
			} else {
				Ref<ShaderMaterial> unique_material;
				Ref<Resource> duplicated = shader_material->duplicate(false);
				unique_material = duplicated;
				if (unique_material.is_null()) {
					unique_material = shader_material;
				}
				unique_material->set_local_to_scene(true);

				set_material_override(unique_material);
				runtime_shader_material = unique_material;
				last_material_instance_id = unique_material->get_instance_id();
			}
		}
	}

	if (_sync_surface_shader_materials()) {
		changed = true;
	}

	if (changed) {
		clear_cached_light_state();
	}

	return changed;
}

bool N64LitMeshInstance3D::_sync_surface_shader_materials() {
	const Ref<Mesh> mesh = get_mesh();
	const int32_t mesh_surface_count = mesh.is_valid() ? mesh->get_surface_count() : 0;
	const int32_t override_surface_count = get_surface_override_material_count();
	const int32_t surface_count = MAX(mesh_surface_count, override_surface_count);

	Vector<uint64_t> observed_surface_material_ids;
	observed_surface_material_ids.resize(surface_count);

	for (int32_t i = 0; i < surface_count; i++) {
		Ref<Material> material;
		if (i < override_surface_count) {
			material = get_surface_override_material(i);
		}
		if (material.is_null() && mesh.is_valid() && i < mesh_surface_count) {
			material = mesh->surface_get_material(i);
		}

		observed_surface_material_ids.set(i, material.is_valid() ? material->get_instance_id() : 0);
	}

	if (observed_surface_material_ids == last_surface_material_instance_ids) {
		return false;
	}

	runtime_surface_shader_materials.clear();
	runtime_surface_shader_materials.resize(surface_count);
	Vector<uint64_t> synced_surface_material_ids;
	synced_surface_material_ids.resize(surface_count);

	// Surface lighting should work no matter where the shader material was
	// authored. Mesh-surface materials get duplicated into per-instance surface
	// overrides here, which makes them behave like explicit overrides afterward.
	for (int32_t i = 0; i < surface_count; i++) {
		Ref<Material> material;
		if (i < override_surface_count) {
			material = get_surface_override_material(i);
		}
		if (material.is_null() && mesh.is_valid() && i < mesh_surface_count) {
			material = mesh->surface_get_material(i);
		}

		if (material.is_null()) {
			synced_surface_material_ids.set(i, 0);
			continue;
		}

		Ref<ShaderMaterial> shader_material = material;
		if (shader_material.is_null()) {
			synced_surface_material_ids.set(i, material->get_instance_id());
			continue;
		}

		Ref<ShaderMaterial> unique_material;
		Ref<Resource> duplicated = shader_material->duplicate(false);
		unique_material = duplicated;
		if (unique_material.is_null()) {
			unique_material = shader_material;
		}
		unique_material->set_local_to_scene(true);

		set_surface_override_material(i, unique_material);
		runtime_surface_shader_materials.set(i, unique_material);
		synced_surface_material_ids.set(i, unique_material->get_instance_id());
	}

	last_surface_material_instance_ids = synced_surface_material_ids;
	return true;
}

bool N64LitMeshInstance3D::_compute_ignore_fake_lights() const {
	static const StringName IGNORE_FAKE_LIGHTS = StringName("ignore_fake_lights");

	if (runtime_shader_material.is_valid()) {
		const Variant value = runtime_shader_material->get_shader_parameter(IGNORE_FAKE_LIGHTS);
		if (value.get_type() == Variant::BOOL && static_cast<bool>(value)) {
			return true;
		}
	}

	for (const Ref<ShaderMaterial> &material : runtime_surface_shader_materials) {
		if (material.is_null()) {
			continue;
		}

		const Variant value = material->get_shader_parameter(IGNORE_FAKE_LIGHTS);
		if (value.get_type() == Variant::BOOL && static_cast<bool>(value)) {
			return true;
		}
	}

	return false;
}

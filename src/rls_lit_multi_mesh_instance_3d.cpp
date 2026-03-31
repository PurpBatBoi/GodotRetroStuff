#include "rls_lit_multi_mesh_instance_3d.h"

#include <godot_cpp/classes/material.hpp>
#include <godot_cpp/classes/mesh.hpp>
#include <godot_cpp/classes/multi_mesh.hpp>
#include <godot_cpp/classes/resource.hpp>
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

RLS_LitMultiMeshInstance3D::RLS_LitMultiMeshInstance3D() {
	set_notify_transform(true);
}

void RLS_LitMultiMeshInstance3D::_bind_methods() {
}

void RLS_LitMultiMeshInstance3D::_notification(int p_what) {
	switch (p_what) {
		case Node::NOTIFICATION_ENTER_TREE:
			set_process_internal(true);
			handle_enter_tree();
			break;
		case Node::NOTIFICATION_EXIT_TREE:
			set_process_internal(false);
			runtime_shader_material.unref();
			runtime_surface_shader_materials.clear();
			last_material_instance_id = 0;
			last_multimesh_instance_id = 0;
			last_mesh_instance_id = 0;
			last_surface_material_instance_ids.clear();
			has_last_local_aabb = false;
			last_local_aabb = AABB();
			handle_exit_tree();
			break;
		case Node::NOTIFICATION_PARENTED:
			handle_parented();
			break;
		case Node::NOTIFICATION_UNPARENTED:
			handle_unparented();
			break;
		case Node::NOTIFICATION_INTERNAL_PROCESS:
			handle_internal_process();
			break;
		case Node3D::NOTIFICATION_TRANSFORM_CHANGED:
			handle_transform_changed();
			break;
		default:
			break;
	}
}

Node3D *RLS_LitMultiMeshInstance3D::get_geometry_node() {
	return this;
}

const Node3D *RLS_LitMultiMeshInstance3D::get_geometry_node() const {
	return this;
}

AABB RLS_LitMultiMeshInstance3D::get_geometry_local_aabb() const {
	const Ref<MultiMesh> multimesh = get_multimesh();
	if (multimesh.is_null()) {
		return AABB();
	}
	return multimesh->get_aabb();
}

Ref<ShaderMaterial> RLS_LitMultiMeshInstance3D::get_runtime_shader_material() const {
	return runtime_shader_material;
}

const Vector<Ref<ShaderMaterial>> &RLS_LitMultiMeshInstance3D::get_runtime_surface_shader_materials() const {
	return runtime_surface_shader_materials;
}

bool RLS_LitMultiMeshInstance3D::sync_runtime_materials() {
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

	if (_sync_multimesh_surface_shader_materials()) {
		changed = true;
	}

	const AABB current_local_aabb = get_geometry_local_aabb();
	if (!has_last_local_aabb || last_local_aabb != current_local_aabb) {
		last_local_aabb = current_local_aabb;
		has_last_local_aabb = true;
		changed = true;
	}

	if (changed) {
		clear_cached_light_state();
	}

	return changed;
}

bool RLS_LitMultiMeshInstance3D::_sync_multimesh_surface_shader_materials() {
	const Ref<MultiMesh> current_multimesh = get_multimesh();
	if (current_multimesh.is_null()) {
		const bool had_state = last_multimesh_instance_id != 0 || last_mesh_instance_id != 0 || !last_surface_material_instance_ids.is_empty() || !runtime_surface_shader_materials.is_empty();
		runtime_surface_shader_materials.clear();
		last_multimesh_instance_id = 0;
		last_mesh_instance_id = 0;
		last_surface_material_instance_ids.clear();
		return had_state;
	}

	Ref<Mesh> current_mesh = current_multimesh->get_mesh();
	const int32_t surface_count = current_mesh.is_valid() ? current_mesh->get_surface_count() : 0;

	Vector<uint64_t> observed_surface_material_ids;
	observed_surface_material_ids.resize(surface_count);
	bool has_shader_surface_material = false;

	for (int32_t i = 0; i < surface_count; i++) {
		const Ref<Material> material = current_mesh->surface_get_material(i);
		observed_surface_material_ids.set(i, material.is_valid() ? material->get_instance_id() : 0);
		if (!has_shader_surface_material) {
			Ref<ShaderMaterial> shader_material = material;
			has_shader_surface_material = shader_material.is_valid();
		}
	}

	const uint64_t current_multimesh_id = current_multimesh->get_instance_id();
	const uint64_t current_mesh_id = current_mesh.is_valid() ? current_mesh->get_instance_id() : 0;
	if (current_multimesh_id == last_multimesh_instance_id &&
			current_mesh_id == last_mesh_instance_id &&
			observed_surface_material_ids == last_surface_material_instance_ids) {
		return false;
	}

	Ref<MultiMesh> target_multimesh = current_multimesh;
	Ref<Mesh> target_mesh = current_mesh;

	if (has_shader_surface_material && current_mesh.is_valid()) {
		Ref<MultiMesh> unique_multimesh;
		Ref<Resource> duplicated_multimesh = current_multimesh->duplicate(false);
		unique_multimesh = duplicated_multimesh;
		if (unique_multimesh.is_null()) {
			unique_multimesh = current_multimesh;
		}
		unique_multimesh->set_local_to_scene(true);

		Ref<Mesh> unique_mesh;
		Ref<Resource> duplicated_mesh = current_mesh->duplicate(false);
		unique_mesh = duplicated_mesh;
		if (unique_mesh.is_null()) {
			unique_mesh = current_mesh;
		}
		unique_mesh->set_local_to_scene(true);

		unique_multimesh->set_mesh(unique_mesh);
		set_multimesh(unique_multimesh);

		target_multimesh = unique_multimesh;
		target_mesh = unique_mesh;
	}

	runtime_surface_shader_materials.clear();
	runtime_surface_shader_materials.resize(surface_count);
	Vector<uint64_t> synced_surface_material_ids;
	synced_surface_material_ids.resize(surface_count);

	for (int32_t i = 0; i < surface_count; i++) {
		if (target_mesh.is_null()) {
			synced_surface_material_ids.set(i, 0);
			continue;
		}

		Ref<Material> material = target_mesh->surface_get_material(i);
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
		Ref<Resource> duplicated_material = shader_material->duplicate(false);
		unique_material = duplicated_material;
		if (unique_material.is_null()) {
			unique_material = shader_material;
		}
		unique_material->set_local_to_scene(true);

		target_mesh->surface_set_material(i, unique_material);
		runtime_surface_shader_materials.set(i, unique_material);
		synced_surface_material_ids.set(i, unique_material->get_instance_id());
	}

	last_multimesh_instance_id = target_multimesh.is_valid() ? target_multimesh->get_instance_id() : 0;
	last_mesh_instance_id = target_mesh.is_valid() ? target_mesh->get_instance_id() : 0;
	last_surface_material_instance_ids = synced_surface_material_ids;
	return true;
}

bool RLS_LitMultiMeshInstance3D::compute_ignore_fake_lights() const {
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

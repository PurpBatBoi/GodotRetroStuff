#include "rls_lit_geometry_instance.h"

#include "rls_vertex_light_manager_3d.h"

#include <godot_cpp/core/object.hpp>

using namespace godot;

namespace {

RLS_VertexLightManager3D *find_manager_ancestor(Node *p_node) {
	Node *current = p_node == nullptr ? nullptr : p_node->get_parent();
	while (current != nullptr) {
		if (RLS_VertexLightManager3D *found_manager = Object::cast_to<RLS_VertexLightManager3D>(current)) {
			return found_manager;
		}
		current = current->get_parent();
	}
	return nullptr;
}

} // namespace

void RLS_LitGeometryInstance::handle_enter_tree() {
	sync_runtime_materials();
	cached_ignore_fake_lights = compute_ignore_fake_lights();
	reconnect_manager();
	notify_runtime_material_changed();
}

void RLS_LitGeometryInstance::handle_exit_tree() {
	if (manager != nullptr) {
		manager->unregister_lit_geometry(this);
		manager = nullptr;
	}
	cached_ignore_fake_lights = false;
	clear_cached_light_state();
}

void RLS_LitGeometryInstance::handle_parented() {
	reconnect_manager();
}

void RLS_LitGeometryInstance::handle_unparented() {
	if (manager != nullptr) {
		manager->unregister_lit_geometry(this);
		manager = nullptr;
	}
}

void RLS_LitGeometryInstance::handle_internal_process() {
	if (sync_runtime_materials()) {
		cached_ignore_fake_lights = compute_ignore_fake_lights();
		notify_runtime_material_changed();
		return;
	}

	const bool ignore_fake_lights = compute_ignore_fake_lights();
	if (ignore_fake_lights != cached_ignore_fake_lights) {
		cached_ignore_fake_lights = ignore_fake_lights;
		notify_runtime_material_changed();
	}
}

void RLS_LitGeometryInstance::handle_transform_changed() {
	if (manager != nullptr) {
		manager->notify_geometry_changed(this);
	}
}

bool RLS_LitGeometryInstance::is_ignoring_fake_lights() const {
	return cached_ignore_fake_lights;
}

bool RLS_LitGeometryInstance::update_cached_light_state(int32_t p_light_count, const PackedVector4Array &p_light_vector_type, const PackedVector4Array &p_light_color_energy, const PackedVector4Array &p_light_spot_direction_inner, const PackedFloat32Array &p_light_range, const PackedFloat32Array &p_light_attenuation, const PackedFloat32Array &p_light_spot_outer_cos, const Vector4 &p_global_ambient) {
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

void RLS_LitGeometryInstance::clear_cached_light_state() {
	cached_light_count = -1;
	cached_light_vector_type.clear();
	cached_light_color_energy.clear();
	cached_light_spot_direction_inner.clear();
	cached_light_range.clear();
	cached_light_attenuation.clear();
	cached_light_spot_outer_cos.clear();
	cached_global_ambient = Vector4();
}

void RLS_LitGeometryInstance::notify_runtime_material_changed() {
	clear_cached_light_state();
	if (manager != nullptr) {
		manager->notify_geometry_changed(this);
	}
}

void RLS_LitGeometryInstance::reconnect_manager() {
	Node3D *geometry_node = get_geometry_node();
	RLS_VertexLightManager3D *new_manager = find_manager_ancestor(geometry_node);
	if (new_manager == manager) {
		return;
	}

	if (manager != nullptr) {
		manager->unregister_lit_geometry(this);
	}

	manager = new_manager;
	if (manager != nullptr) {
		manager->register_lit_geometry(this);
	}
}

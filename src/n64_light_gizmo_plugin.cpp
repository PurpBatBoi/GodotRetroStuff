#include "n64_light_gizmo_plugin.h"

#include "n64_directional_light_3d.h"
#include "n64_point_light_3d.h"

#include <godot_cpp/classes/editor_node3d_gizmo.hpp>
#include <godot_cpp/classes/material.hpp>
#include <godot_cpp/classes/resource.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/standard_material3d.hpp>
#include <godot_cpp/classes/texture2d.hpp>
#include <godot_cpp/core/object.hpp>
#include <godot_cpp/variant/color.hpp>

using namespace godot;

void N64LightGizmoPlugin::_bind_methods() {
}

void N64LightGizmoPlugin::_ensure_materials() {
	if (point_material_ready && directional_material_ready) {
		return;
	}

	ResourceLoader *resource_loader = ResourceLoader::get_singleton();
	if (resource_loader == nullptr) {
		return;
	}

	if (!point_material_ready) {
		const Ref<Texture2D> point_icon = resource_loader->load(String(POINT_ICON_PATH), "Texture2D");
		if (point_icon.is_valid()) {
			create_icon_material(String(POINT_MATERIAL_NAME), point_icon, true);
			point_material_ready = true;
		}
	}

	if (!directional_material_ready) {
		const Ref<Texture2D> directional_icon = resource_loader->load(String(DIRECTIONAL_ICON_PATH), "Texture2D");
		if (directional_icon.is_valid()) {
			create_icon_material(String(DIRECTIONAL_MATERIAL_NAME), directional_icon, true);
			directional_material_ready = true;
		}
	}
}

bool N64LightGizmoPlugin::_has_gizmo(Node3D *p_for_node_3d) const {
	return Object::cast_to<N64PointLight3D>(p_for_node_3d) != nullptr ||
			Object::cast_to<N64DirectionalLight3D>(p_for_node_3d) != nullptr;
}

String N64LightGizmoPlugin::_get_gizmo_name() const {
	return "N64LightIcons";
}

int32_t N64LightGizmoPlugin::_get_priority() const {
	return -1;
}

void N64LightGizmoPlugin::_redraw(const Ref<EditorNode3DGizmo> &p_gizmo) {
	if (p_gizmo.is_null()) {
		return;
	}

	_ensure_materials();
	p_gizmo->clear();

	Node3D *node = p_gizmo->get_node_3d();
	if (node == nullptr) {
		return;
	}

	Ref<StandardMaterial3D> material;
	if (Object::cast_to<N64PointLight3D>(node) != nullptr) {
		material = get_material(String(POINT_MATERIAL_NAME), p_gizmo);
	} else if (Object::cast_to<N64DirectionalLight3D>(node) != nullptr) {
		material = get_material(String(DIRECTIONAL_MATERIAL_NAME), p_gizmo);
	}

	if (material.is_valid()) {
		p_gizmo->add_unscaled_billboard(material, ICON_SCALE);
	}
}

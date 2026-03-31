#include "n64_light_gizmo_plugin.h"

#include "n64_directional_light_3d.h"
#include "n64_point_light_3d.h"
#include "n64_spot_light_3d.h"

#include <godot_cpp/classes/camera3d.hpp>
#include <godot_cpp/classes/editor_node3d_gizmo.hpp>
#include <godot_cpp/classes/editor_undo_redo_manager.hpp>
#include <godot_cpp/classes/material.hpp>
#include <godot_cpp/classes/resource.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/standard_material3d.hpp>
#include <godot_cpp/classes/texture2d.hpp>
#include <godot_cpp/core/math.hpp>
#include <godot_cpp/core/object.hpp>
#include <godot_cpp/variant/color.hpp>
#include <godot_cpp/variant/packed_int32_array.hpp>
#include <godot_cpp/variant/packed_vector3_array.hpp>
#include <godot_cpp/variant/plane.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/variant/vector3.hpp>

using namespace godot;

namespace {

constexpr int32_t HANDLE_RANGE = 0;
constexpr int32_t HANDLE_SPOT_ANGLE = 1;
constexpr int32_t CIRCLE_SEGMENTS = 32;
constexpr float DIRECTIONAL_ARROW_LENGTH = 1.4f;
constexpr float DIRECTIONAL_ARROW_HEAD = 0.35f;

Color get_node_color(Node3D *p_node) {
	if (const N64PointLight3D *point = Object::cast_to<N64PointLight3D>(p_node)) {
		return point->is_enabled() ? point->get_color() : point->get_color().darkened(0.45);
	}
	if (const N64DirectionalLight3D *directional = Object::cast_to<N64DirectionalLight3D>(p_node)) {
		return directional->is_enabled() ? directional->get_color() : directional->get_color().darkened(0.45);
	}
	if (const N64SpotLight3D *spot = Object::cast_to<N64SpotLight3D>(p_node)) {
		return spot->is_enabled() ? spot->get_color() : spot->get_color().darkened(0.45);
	}
	return Color(1.0, 1.0, 1.0, 1.0);
}

void append_circle(PackedVector3Array &p_lines, const Vector3 &p_center, const Vector3 &p_axis_a, const Vector3 &p_axis_b, float p_radius) {
	for (int32_t i = 0; i < CIRCLE_SEGMENTS; i++) {
		const float t0 = Math_TAU * static_cast<float>(i) / static_cast<float>(CIRCLE_SEGMENTS);
		const float t1 = Math_TAU * static_cast<float>(i + 1) / static_cast<float>(CIRCLE_SEGMENTS);
		const Vector3 p0 = p_center + (p_axis_a * Math::cos(t0) + p_axis_b * Math::sin(t0)) * p_radius;
		const Vector3 p1 = p_center + (p_axis_a * Math::cos(t1) + p_axis_b * Math::sin(t1)) * p_radius;
		p_lines.push_back(p0);
		p_lines.push_back(p1);
	}
}

void append_directional_arrow(PackedVector3Array &p_lines) {
	const Vector3 tip(0.0f, 0.0f, -DIRECTIONAL_ARROW_LENGTH);
	const Vector3 head_left(-DIRECTIONAL_ARROW_HEAD, 0.0f, -DIRECTIONAL_ARROW_LENGTH + DIRECTIONAL_ARROW_HEAD);
	const Vector3 head_right(DIRECTIONAL_ARROW_HEAD, 0.0f, -DIRECTIONAL_ARROW_LENGTH + DIRECTIONAL_ARROW_HEAD);
	const Vector3 head_up(0.0f, DIRECTIONAL_ARROW_HEAD, -DIRECTIONAL_ARROW_LENGTH + DIRECTIONAL_ARROW_HEAD);
	const Vector3 head_down(0.0f, -DIRECTIONAL_ARROW_HEAD, -DIRECTIONAL_ARROW_LENGTH + DIRECTIONAL_ARROW_HEAD);

	p_lines.push_back(Vector3());
	p_lines.push_back(tip);
	p_lines.push_back(tip);
	p_lines.push_back(head_left);
	p_lines.push_back(tip);
	p_lines.push_back(head_right);
	p_lines.push_back(tip);
	p_lines.push_back(head_up);
	p_lines.push_back(tip);
	p_lines.push_back(head_down);
}

void append_spot_cone(PackedVector3Array &p_lines, float p_range, float p_angle_degrees) {
	const float radius = Math::tan(Math::deg_to_rad(p_angle_degrees)) * p_range;
	const Vector3 base_center(0.0f, 0.0f, -p_range);
	append_circle(p_lines, base_center, Vector3(1.0f, 0.0f, 0.0f), Vector3(0.0f, 1.0f, 0.0f), radius);

	for (int32_t i = 0; i < 4; i++) {
		const float angle = Math_TAU * static_cast<float>(i) * 0.25f;
		const Vector3 rim = base_center + Vector3(Math::cos(angle) * radius, Math::sin(angle) * radius, 0.0f);
		p_lines.push_back(Vector3());
		p_lines.push_back(rim);
	}
}

bool intersect_ray_with_plane(Camera3D *p_camera, const Vector2 &p_screen_pos, const Plane &p_plane, Vector3 &r_intersection) {
	if (p_camera == nullptr) {
		return false;
	}
	const Vector3 ray_origin = p_camera->project_ray_origin(p_screen_pos);
	const Vector3 ray_direction = p_camera->project_ray_normal(p_screen_pos);
	return p_plane.intersects_ray(ray_origin, ray_direction, &r_intersection);
}

} // namespace

void N64LightGizmoPlugin::_bind_methods() {
}

void N64LightGizmoPlugin::set_editor_plugin(EditorPlugin *p_editor_plugin) {
	editor_plugin = p_editor_plugin;
}

void N64LightGizmoPlugin::_ensure_materials() {
	if (point_material_ready && directional_material_ready && spot_material_ready && line_materials_ready) {
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

	if (!spot_material_ready) {
		const Ref<Texture2D> spot_icon = resource_loader->load(String(SPOT_ICON_PATH), "Texture2D");
		if (spot_icon.is_valid()) {
			create_icon_material(String(SPOT_MATERIAL_NAME), spot_icon, true);
			spot_material_ready = true;
		}
	}

	if (!line_materials_ready) {
		create_material(String(POINT_LINES_MATERIAL_NAME), Color(1.0, 1.0, 1.0, 1.0), false, true);
		create_material(String(DIRECTIONAL_LINES_MATERIAL_NAME), Color(1.0, 1.0, 1.0, 1.0), false, true);
		create_material(String(SPOT_LINES_MATERIAL_NAME), Color(1.0, 1.0, 1.0, 1.0), false, true);
		create_handle_material(String(HANDLE_MATERIAL_NAME), true);
		line_materials_ready = true;
	}
}

void N64LightGizmoPlugin::_commit_property_change(Object *p_object, const String &p_action_name, const StringName &p_property, const Variant &p_do_value, const Variant &p_undo_value) const {
	if (p_object == nullptr) {
		return;
	}

	if (editor_plugin == nullptr) {
		p_object->set(p_property, p_do_value);
		return;
	}

	EditorUndoRedoManager *undo_redo = editor_plugin->get_undo_redo();
	if (undo_redo == nullptr) {
		p_object->set(p_property, p_do_value);
		return;
	}

	undo_redo->create_action(p_action_name);
	undo_redo->add_do_property(p_object, p_property, p_do_value);
	undo_redo->add_undo_property(p_object, p_property, p_undo_value);
	undo_redo->commit_action();
}

bool N64LightGizmoPlugin::_has_gizmo(Node3D *p_for_node_3d) const {
	return Object::cast_to<N64PointLight3D>(p_for_node_3d) != nullptr ||
			Object::cast_to<N64DirectionalLight3D>(p_for_node_3d) != nullptr ||
			Object::cast_to<N64SpotLight3D>(p_for_node_3d) != nullptr;
}

String N64LightGizmoPlugin::_get_gizmo_name() const {
	return "N64Lights";
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

	const Color gizmo_color = get_node_color(node);
	Ref<StandardMaterial3D> material;
	if (Object::cast_to<N64PointLight3D>(node) != nullptr) {
		material = get_material(String(POINT_MATERIAL_NAME), p_gizmo);
	} else if (Object::cast_to<N64DirectionalLight3D>(node) != nullptr) {
		material = get_material(String(DIRECTIONAL_MATERIAL_NAME), p_gizmo);
	} else if (Object::cast_to<N64SpotLight3D>(node) != nullptr) {
		material = get_material(String(SPOT_MATERIAL_NAME), p_gizmo);
	}

	if (material.is_valid()) {
		p_gizmo->add_unscaled_billboard(material, ICON_SCALE, gizmo_color);
	}

	if (N64PointLight3D *point_light = Object::cast_to<N64PointLight3D>(node)) {
		PackedVector3Array lines;
		append_circle(lines, Vector3(), Vector3(1.0f, 0.0f, 0.0f), Vector3(0.0f, 1.0f, 0.0f), point_light->get_range());
		append_circle(lines, Vector3(), Vector3(1.0f, 0.0f, 0.0f), Vector3(0.0f, 0.0f, 1.0f), point_light->get_range());
		append_circle(lines, Vector3(), Vector3(0.0f, 1.0f, 0.0f), Vector3(0.0f, 0.0f, 1.0f), point_light->get_range());
		p_gizmo->add_lines(lines, get_material(String(POINT_LINES_MATERIAL_NAME), p_gizmo), false, gizmo_color);
		p_gizmo->add_collision_segments(lines);

		PackedVector3Array handles;
		PackedInt32Array ids;
		handles.push_back(Vector3(point_light->get_range(), 0.0f, 0.0f));
		ids.push_back(HANDLE_RANGE);
		p_gizmo->add_handles(handles, get_material(String(HANDLE_MATERIAL_NAME), p_gizmo), ids, true);
		return;
	}

	if (Object::cast_to<N64DirectionalLight3D>(node) != nullptr) {
		PackedVector3Array lines;
		append_directional_arrow(lines);
		p_gizmo->add_lines(lines, get_material(String(DIRECTIONAL_LINES_MATERIAL_NAME), p_gizmo), false, gizmo_color);
		p_gizmo->add_collision_segments(lines);
		return;
	}

	if (N64SpotLight3D *spot_light = Object::cast_to<N64SpotLight3D>(node)) {
		PackedVector3Array lines;
		append_spot_cone(lines, spot_light->get_range(), spot_light->get_spot_angle());
		p_gizmo->add_lines(lines, get_material(String(SPOT_LINES_MATERIAL_NAME), p_gizmo), false, gizmo_color);
		p_gizmo->add_collision_segments(lines);

		const float radius = Math::tan(Math::deg_to_rad(spot_light->get_spot_angle())) * spot_light->get_range();
		PackedVector3Array handles;
		PackedInt32Array ids;
		handles.push_back(Vector3(0.0f, 0.0f, -spot_light->get_range()));
		ids.push_back(HANDLE_RANGE);
		handles.push_back(Vector3(radius, 0.0f, -spot_light->get_range()));
		ids.push_back(HANDLE_SPOT_ANGLE);
		p_gizmo->add_handles(handles, get_material(String(HANDLE_MATERIAL_NAME), p_gizmo), ids, true);
	}
}

String N64LightGizmoPlugin::_get_handle_name(const Ref<EditorNode3DGizmo> &p_gizmo, int32_t p_handle_id, bool p_secondary) const {
	Node3D *node = p_gizmo.is_valid() ? p_gizmo->get_node_3d() : nullptr;
	if (node == nullptr || p_secondary) {
		return "";
	}

	if (Object::cast_to<N64PointLight3D>(node) != nullptr) {
		return p_handle_id == HANDLE_RANGE ? "Range" : "";
	}
	if (Object::cast_to<N64SpotLight3D>(node) != nullptr) {
		if (p_handle_id == HANDLE_RANGE) {
			return "Range";
		}
		if (p_handle_id == HANDLE_SPOT_ANGLE) {
			return "Spot Angle";
		}
	}

	return "";
}

Variant N64LightGizmoPlugin::_get_handle_value(const Ref<EditorNode3DGizmo> &p_gizmo, int32_t p_handle_id, bool p_secondary) const {
	Node3D *node = p_gizmo.is_valid() ? p_gizmo->get_node_3d() : nullptr;
	if (node == nullptr || p_secondary) {
		return Variant();
	}

	if (const N64PointLight3D *point_light = Object::cast_to<N64PointLight3D>(node)) {
		if (p_handle_id == HANDLE_RANGE) {
			return point_light->get_range();
		}
	}

	if (const N64SpotLight3D *spot_light = Object::cast_to<N64SpotLight3D>(node)) {
		if (p_handle_id == HANDLE_RANGE) {
			return spot_light->get_range();
		}
		if (p_handle_id == HANDLE_SPOT_ANGLE) {
			return spot_light->get_spot_angle();
		}
	}

	return Variant();
}

void N64LightGizmoPlugin::_set_handle(const Ref<EditorNode3DGizmo> &p_gizmo, int32_t p_handle_id, bool p_secondary, Camera3D *p_camera, const Vector2 &p_screen_pos) {
	Node3D *node = p_gizmo.is_valid() ? p_gizmo->get_node_3d() : nullptr;
	if (node == nullptr || p_secondary || p_camera == nullptr) {
		return;
	}

	const Transform3D global_transform = node->get_global_transform();
	const Vector3 world_origin = global_transform.origin;
	Vector3 intersection;

	if (N64PointLight3D *point_light = Object::cast_to<N64PointLight3D>(node)) {
		const Vector3 plane_normal = p_camera->get_global_transform().basis.get_column(2).normalized();
		if (!intersect_ray_with_plane(p_camera, p_screen_pos, Plane(plane_normal, world_origin), intersection)) {
			return;
		}

		if (p_handle_id == HANDLE_RANGE) {
			point_light->set_range(MAX(world_origin.distance_to(intersection), 0.01f));
		}
		return;
	}

	if (N64SpotLight3D *spot_light = Object::cast_to<N64SpotLight3D>(node)) {
		const Vector3 plane_normal = global_transform.basis.get_column(1).normalized();
		if (!intersect_ray_with_plane(p_camera, p_screen_pos, Plane(plane_normal, world_origin), intersection)) {
			return;
		}

		const Vector3 local_point = node->to_local(intersection);
		if (p_handle_id == HANDLE_RANGE) {
			spot_light->set_range(MAX(-local_point.z, 0.01f));
		} else if (p_handle_id == HANDLE_SPOT_ANGLE) {
			const float depth = MAX(-local_point.z, 0.001f);
			const float angle = Math::rad_to_deg(Math::atan2(Math::abs(local_point.x), depth));
			spot_light->set_spot_angle(CLAMP(angle, 1.0f, 89.0f));
		}
	}
}

void N64LightGizmoPlugin::_commit_handle(const Ref<EditorNode3DGizmo> &p_gizmo, int32_t p_handle_id, bool p_secondary, const Variant &p_restore, bool p_cancel) {
	Node3D *node = p_gizmo.is_valid() ? p_gizmo->get_node_3d() : nullptr;
	if (node == nullptr || p_secondary) {
		return;
	}

	if (N64PointLight3D *point_light = Object::cast_to<N64PointLight3D>(node)) {
		if (p_handle_id != HANDLE_RANGE) {
			return;
		}

		const float restore = p_restore;
		if (p_cancel) {
			point_light->set_range(restore);
			return;
		}

		const float current = point_light->get_range();
		if (!Math::is_equal_approx(current, restore)) {
			_commit_property_change(point_light, "Change N64 Point Light Range", StringName("range"), current, restore);
		}
		return;
	}

	if (N64SpotLight3D *spot_light = Object::cast_to<N64SpotLight3D>(node)) {
		if (p_handle_id == HANDLE_RANGE) {
			const float restore = p_restore;
			if (p_cancel) {
				spot_light->set_range(restore);
				return;
			}

			const float current = spot_light->get_range();
			if (!Math::is_equal_approx(current, restore)) {
				_commit_property_change(spot_light, "Change N64 Spot Light Range", StringName("range"), current, restore);
			}
			return;
		}

		if (p_handle_id == HANDLE_SPOT_ANGLE) {
			const float restore = p_restore;
			if (p_cancel) {
				spot_light->set_spot_angle(restore);
				return;
			}

			const float current = spot_light->get_spot_angle();
			if (!Math::is_equal_approx(current, restore)) {
				_commit_property_change(spot_light, "Change N64 Spot Light Angle", StringName("spot_angle"), current, restore);
			}
		}
	}
}

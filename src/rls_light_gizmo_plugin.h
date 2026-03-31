#pragma once

#include <godot_cpp/classes/camera3d.hpp>
#include <godot_cpp/classes/editor_node3d_gizmo_plugin.hpp>
#include <godot_cpp/classes/editor_plugin.hpp>
#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/classes/ref.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/variant/variant.hpp>

namespace godot {

class EditorNode3DGizmo;
class EditorPlugin;
class Texture2D;

class RLSLightGizmoPlugin : public EditorNode3DGizmoPlugin {
	GDCLASS(RLSLightGizmoPlugin, EditorNode3DGizmoPlugin)

	static constexpr const char *POINT_ICON_PATH = "res://addons/rls_visuals_billboards/icons/OmniLight3D.svg";
	static constexpr const char *DIRECTIONAL_ICON_PATH = "res://addons/rls_visuals_billboards/icons/DirectionalLight3D.svg";
	static constexpr const char *SPOT_ICON_PATH = "res://addons/rls_visuals_billboards/icons/DirectionalLight3D.svg";
	static constexpr const char *POINT_MATERIAL_NAME = "rls_point_light_icon";
	static constexpr const char *DIRECTIONAL_MATERIAL_NAME = "rls_directional_light_icon";
	static constexpr const char *SPOT_MATERIAL_NAME = "rls_spot_light_icon";
	static constexpr const char *POINT_LINES_MATERIAL_NAME = "rls_point_light_lines";
	static constexpr const char *DIRECTIONAL_LINES_MATERIAL_NAME = "rls_directional_light_lines";
	static constexpr const char *SPOT_LINES_MATERIAL_NAME = "rls_spot_light_lines";
	static constexpr const char *HANDLE_MATERIAL_NAME = "rls_light_handle";
	static constexpr float ICON_SCALE = 0.06f;

	bool point_material_ready = false;
	bool directional_material_ready = false;
	bool spot_material_ready = false;
	bool line_materials_ready = false;
	EditorPlugin *editor_plugin = nullptr;

	void _ensure_materials();
	void _commit_property_change(Object *p_object, const String &p_action_name, const StringName &p_property, const Variant &p_do_value, const Variant &p_undo_value) const;

protected:
	static void _bind_methods();

public:
	RLSLightGizmoPlugin() = default;
	~RLSLightGizmoPlugin() override = default;

	void set_editor_plugin(EditorPlugin *p_editor_plugin);
	bool _has_gizmo(Node3D *p_for_node_3d) const override;
	String _get_gizmo_name() const override;
	int32_t _get_priority() const override;
	void _redraw(const Ref<EditorNode3DGizmo> &p_gizmo) override;
	String _get_handle_name(const Ref<EditorNode3DGizmo> &p_gizmo, int32_t p_handle_id, bool p_secondary) const override;
	Variant _get_handle_value(const Ref<EditorNode3DGizmo> &p_gizmo, int32_t p_handle_id, bool p_secondary) const override;
	void _set_handle(const Ref<EditorNode3DGizmo> &p_gizmo, int32_t p_handle_id, bool p_secondary, Camera3D *p_camera, const Vector2 &p_screen_pos) override;
	void _commit_handle(const Ref<EditorNode3DGizmo> &p_gizmo, int32_t p_handle_id, bool p_secondary, const Variant &p_restore, bool p_cancel) override;
};

} // namespace godot

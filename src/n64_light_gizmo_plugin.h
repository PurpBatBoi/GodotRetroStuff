#pragma once

#include <godot_cpp/classes/editor_node3d_gizmo_plugin.hpp>
#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/classes/ref.hpp>

namespace godot {

class EditorNode3DGizmo;
class Texture2D;

class N64LightGizmoPlugin : public EditorNode3DGizmoPlugin {
	GDCLASS(N64LightGizmoPlugin, EditorNode3DGizmoPlugin)

	static constexpr const char *POINT_ICON_PATH = "res://assets/icons/OmniLight3D.svg";
	static constexpr const char *DIRECTIONAL_ICON_PATH = "res://assets/icons/DirectionalLight3D.svg";
	static constexpr const char *POINT_MATERIAL_NAME = "n64_point_light_icon";
	static constexpr const char *DIRECTIONAL_MATERIAL_NAME = "n64_directional_light_icon";
	static constexpr float ICON_SCALE = 0.06f;

	bool point_material_ready = false;
	bool directional_material_ready = false;

	void _ensure_materials();

protected:
	static void _bind_methods();

public:
	N64LightGizmoPlugin() = default;
	~N64LightGizmoPlugin() override = default;

	bool _has_gizmo(Node3D *p_for_node_3d) const override;
	String _get_gizmo_name() const override;
	int32_t _get_priority() const override;
	void _redraw(const Ref<EditorNode3DGizmo> &p_gizmo) override;
};

} // namespace godot

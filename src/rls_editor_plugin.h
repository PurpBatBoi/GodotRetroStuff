#pragma once

#include <godot_cpp/classes/editor_plugin.hpp>
#include <godot_cpp/classes/ref.hpp>

namespace godot {

class RLSLightGizmoPlugin;
class Texture2D;

class RLSEditorPlugin : public EditorPlugin {
	GDCLASS(RLSEditorPlugin, EditorPlugin)

	Ref<RLSLightGizmoPlugin> light_gizmo_plugin;

protected:
	static void _bind_methods();

public:
	RLSEditorPlugin() = default;
	~RLSEditorPlugin() override = default;

	String _get_plugin_name() const override;
	Ref<Texture2D> _get_plugin_icon() const override;
	bool _has_main_screen() const override;
	void _enable_plugin() override;
	void _disable_plugin() override;
};

} // namespace godot

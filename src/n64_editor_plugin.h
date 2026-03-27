#pragma once

#include <godot_cpp/classes/editor_plugin.hpp>
#include <godot_cpp/classes/ref.hpp>

namespace godot {

class N64LightGizmoPlugin;
class Texture2D;

class N64EditorPlugin : public EditorPlugin {
	GDCLASS(N64EditorPlugin, EditorPlugin)

	Ref<N64LightGizmoPlugin> light_gizmo_plugin;

protected:
	static void _bind_methods();

public:
	N64EditorPlugin() = default;
	~N64EditorPlugin() override = default;

	String _get_plugin_name() const override;
	Ref<Texture2D> _get_plugin_icon() const override;
	bool _has_main_screen() const override;
	void _enable_plugin() override;
	void _disable_plugin() override;
};

} // namespace godot

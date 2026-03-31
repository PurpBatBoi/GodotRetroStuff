#include "n64_editor_plugin.h"

#include "n64_light_gizmo_plugin.h"

#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/texture2d.hpp>

using namespace godot;

void N64EditorPlugin::_bind_methods() {
}

String N64EditorPlugin::_get_plugin_name() const {
	return "N64 Visuals";
}

Ref<Texture2D> N64EditorPlugin::_get_plugin_icon() const {
	ResourceLoader *resource_loader = ResourceLoader::get_singleton();
	if (resource_loader == nullptr) {
		return Ref<Texture2D>();
	}
	return resource_loader->load("res://icon.svg", "Texture2D");
}

bool N64EditorPlugin::_has_main_screen() const {
	return false;
}

void N64EditorPlugin::_enable_plugin() {
	if (light_gizmo_plugin.is_null()) {
		light_gizmo_plugin.instantiate();
	}

	light_gizmo_plugin->set_editor_plugin(this);
	add_node_3d_gizmo_plugin(light_gizmo_plugin);
}

void N64EditorPlugin::_disable_plugin() {
	if (light_gizmo_plugin.is_valid()) {
		light_gizmo_plugin->set_editor_plugin(nullptr);
		remove_node_3d_gizmo_plugin(light_gizmo_plugin);
		light_gizmo_plugin.unref();
	}
}

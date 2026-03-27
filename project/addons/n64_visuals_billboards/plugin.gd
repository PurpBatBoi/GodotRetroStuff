@tool
extends EditorPlugin

const N64_LIGHT_GIZMO_PLUGIN_SCRIPT = preload("res://addons/n64_visuals_billboards/n64_light_gizmo_plugin.gd")

var light_gizmo_plugin: EditorNode3DGizmoPlugin


func _enter_tree() -> void:
	light_gizmo_plugin = N64_LIGHT_GIZMO_PLUGIN_SCRIPT.new()
	add_node_3d_gizmo_plugin(light_gizmo_plugin)


func _exit_tree() -> void:
	if light_gizmo_plugin != null:
		remove_node_3d_gizmo_plugin(light_gizmo_plugin)
		light_gizmo_plugin = null

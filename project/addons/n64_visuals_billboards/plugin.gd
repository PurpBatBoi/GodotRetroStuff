@tool
extends EditorPlugin

const N64_LIGHT_GIZMO_PLUGIN_SCRIPT = preload("res://addons/n64_visuals_billboards/n64_light_gizmo_plugin.gd")
const POINT_SCRIPT := preload("res://addons/n64_visuals_billboards/types/n64_point_light_3d.gd")
const DIRECTIONAL_SCRIPT := preload("res://addons/n64_visuals_billboards/types/n64_directional_light_3d.gd")
const SPOT_SCRIPT := preload("res://addons/n64_visuals_billboards/types/n64_spot_light_3d.gd")
const MANAGER_SCRIPT := preload("res://addons/n64_visuals_billboards/types/n64_vertex_light_manager_3d.gd")

const POINT_ICON_PATH := "res://addons/n64_visuals_billboards/icons/OmniLight3D.png"
const DIRECTIONAL_ICON_PATH := "res://addons/n64_visuals_billboards/icons/DirectionalLight3D.png"
const SPOT_ICON_PATH := "res://addons/n64_visuals_billboards/icons/SpotLight3D.png"
const MANAGER_ICON_PATH := "res://addons/n64_visuals_billboards/icons/WorldEnvironment.png"

var light_gizmo_plugin: EditorNode3DGizmoPlugin
var _point_icon: Texture2D
var _directional_icon: Texture2D
var _spot_icon: Texture2D
var _manager_icon: Texture2D


func _enter_tree() -> void:
	_point_icon = _load_png_texture(POINT_ICON_PATH)
	_directional_icon = _load_png_texture(DIRECTIONAL_ICON_PATH)
	_spot_icon = _load_png_texture(SPOT_ICON_PATH)
	_manager_icon = _load_png_texture(MANAGER_ICON_PATH)

	add_custom_type("N64PointLight3D", "N64PointLight3D", POINT_SCRIPT, _point_icon)
	add_custom_type("N64DirectionalLight3D", "N64DirectionalLight3D", DIRECTIONAL_SCRIPT, _directional_icon)
	add_custom_type("N64SpotLight3D", "N64SpotLight3D", SPOT_SCRIPT, _spot_icon)
	add_custom_type("N64VertexLightManager3D", "N64VertexLightManager3D", MANAGER_SCRIPT, _manager_icon)

	light_gizmo_plugin = N64_LIGHT_GIZMO_PLUGIN_SCRIPT.new()
	if light_gizmo_plugin.has_method("set_editor_plugin"):
		light_gizmo_plugin.set_editor_plugin(self)
	if light_gizmo_plugin.has_method("set_icon_textures"):
		light_gizmo_plugin.set_icon_textures(_point_icon, _directional_icon, _spot_icon)
	add_node_3d_gizmo_plugin(light_gizmo_plugin)


func _exit_tree() -> void:
	if light_gizmo_plugin != null:
		if light_gizmo_plugin.has_method("set_editor_plugin"):
			light_gizmo_plugin.set_editor_plugin(null)
		remove_node_3d_gizmo_plugin(light_gizmo_plugin)
		light_gizmo_plugin = null

	remove_custom_type("N64VertexLightManager3D")
	remove_custom_type("N64SpotLight3D")
	remove_custom_type("N64DirectionalLight3D")
	remove_custom_type("N64PointLight3D")


func _load_png_texture(path: String) -> Texture2D:
	var imported_resource := ResourceLoader.load(path)
	if imported_resource is Texture2D:
		return imported_resource

	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.is_empty():
		push_warning("Could not read icon PNG: %s" % path)
		return null

	var image := Image.new()
	var error := image.load_png_from_buffer(bytes)
	if error != OK:
		push_warning("Could not decode icon PNG: %s (error %d)" % [path, error])
		return null

	return ImageTexture.create_from_image(image)

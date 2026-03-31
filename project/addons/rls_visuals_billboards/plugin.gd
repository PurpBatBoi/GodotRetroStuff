@tool
extends EditorPlugin

const POINT_ICON_FILE := "icons/OmniLight3D.png"
const DIRECTIONAL_ICON_FILE := "icons/DirectionalLight3D.png"
const SPOT_ICON_FILE := "icons/SpotLight3D.png"
const MANAGER_ICON_FILE := "icons/WorldEnvironment.png"

var light_gizmo_plugin: EditorNode3DGizmoPlugin
var _point_icon: Texture2D
var _directional_icon: Texture2D
var _spot_icon: Texture2D
var _manager_icon: Texture2D


func _enter_tree() -> void:
	var point_script := _load_script("types/rls_point_light_3d.gd")
	var directional_script := _load_script("types/rls_directional_light_3d.gd")
	var spot_script := _load_script("types/rls_spot_light_3d.gd")
	var manager_script := _load_script("types/rls_vertex_light_manager_3d.gd")
	var lit_mesh_script := _load_script("types/rls_lit_mesh_instance_3d.gd")
	var gizmo_plugin_script := _load_script("rls_light_gizmo_plugin.gd")

	_point_icon = _load_png_texture(_addon_path(POINT_ICON_FILE))
	_directional_icon = _load_png_texture(_addon_path(DIRECTIONAL_ICON_FILE))
	_spot_icon = _load_png_texture(_addon_path(SPOT_ICON_FILE))
	_manager_icon = _load_png_texture(_addon_path(MANAGER_ICON_FILE))

	if point_script == null or directional_script == null or spot_script == null or manager_script == null or lit_mesh_script == null or gizmo_plugin_script == null:
		push_error("RLS Vertex Lighting failed to load one or more addon scripts.")
		return

	add_custom_type("RLS_PointLight3D", "RLS_PointLight3D", point_script, _point_icon)
	add_custom_type("RLS_DirectionalLight3D", "RLS_DirectionalLight3D", directional_script, _directional_icon)
	add_custom_type("RLS_SpotLight3D", "RLS_SpotLight3D", spot_script, _spot_icon)
	add_custom_type("RLS_VertexLightManager3D", "RLS_VertexLightManager3D", manager_script, _manager_icon)
	add_custom_type("RLS_LitMeshInstance3D", "RLS_LitMeshInstance3D", lit_mesh_script, null)

	light_gizmo_plugin = gizmo_plugin_script.new()
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

	remove_custom_type("RLS_LitMeshInstance3D")
	remove_custom_type("RLS_VertexLightManager3D")
	remove_custom_type("RLS_SpotLight3D")
	remove_custom_type("RLS_DirectionalLight3D")
	remove_custom_type("RLS_PointLight3D")


func _addon_path(relative_path: String) -> String:
	var script := get_script() as Script
	if script == null:
		return relative_path
	return "%s/%s" % [script.resource_path.get_base_dir(), relative_path]


func _load_script(relative_path: String) -> Script:
	var resource := ResourceLoader.load(_addon_path(relative_path))
	if resource is Script:
		return resource

	push_error("Could not load addon script: %s" % _addon_path(relative_path))
	return null


func _load_png_texture(path: String) -> Texture2D:
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

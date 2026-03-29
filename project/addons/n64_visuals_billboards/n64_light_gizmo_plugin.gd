@tool
extends EditorNode3DGizmoPlugin

const POINT_ICON := preload("res://addons/n64_visuals_billboards/icons/OmniLight3D.svg")
const DIRECTIONAL_ICON := preload("res://addons/n64_visuals_billboards/icons/DirectionalLight3D.svg")
const POINT_MATERIAL := "n64_point_light_icon"
const DIRECTIONAL_MATERIAL := "n64_directional_light_icon"
const ICON_SCALE := 0.06

var _materials_ready := false


func _get_gizmo_name() -> String:
	return "N64LightIcons"


func _has_gizmo(for_node_3d: Node3D) -> bool:
	return for_node_3d != null and (
		for_node_3d.is_class("N64PointLight3D") or
		for_node_3d.is_class("N64DirectionalLight3D")
	)


func _redraw(gizmo: EditorNode3DGizmo) -> void:
	if gizmo == null:
		return

	_ensure_materials()
	gizmo.clear()

	var node := gizmo.get_node_3d()
	if node == null:
		return

	var material: Material = null
	if node.is_class("N64PointLight3D"):
		material = get_material(POINT_MATERIAL, gizmo)
	elif node.is_class("N64DirectionalLight3D"):
		material = get_material(DIRECTIONAL_MATERIAL, gizmo)

	if material != null:
		gizmo.add_unscaled_billboard(material, ICON_SCALE)


func _ensure_materials() -> void:
	if _materials_ready:
		return

	create_icon_material(POINT_MATERIAL, POINT_ICON, true)
	create_icon_material(DIRECTIONAL_MATERIAL, DIRECTIONAL_ICON, true)
	_materials_ready = true

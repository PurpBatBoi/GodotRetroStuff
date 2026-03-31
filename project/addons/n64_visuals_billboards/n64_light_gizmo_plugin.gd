@tool
extends EditorNode3DGizmoPlugin

const POINT_MATERIAL := "n64_point_light_icon"
const DIRECTIONAL_MATERIAL := "n64_directional_light_icon"
const SPOT_MATERIAL := "n64_spot_light_icon"
const LINES_PRIMARY := "n64_lines_primary"
const LINES_SECONDARY := "n64_lines_secondary"
const LINES_BILLBOARD := "n64_lines_billboard"
const HANDLES := "n64_handles"
const HANDLES_BILLBOARD := "n64_handles_billboard"
const ICON_SCALE := 0.06
const HANDLE_RANGE := 0
const HANDLE_SPOT_ANGLE := 1
const CIRCLE_STEPS := 120

var _materials_ready := false
var _editor_plugin: EditorPlugin
var _point_icon: Texture2D
var _directional_icon: Texture2D
var _spot_icon: Texture2D


func set_editor_plugin(editor_plugin: EditorPlugin) -> void:
	_editor_plugin = editor_plugin


func set_icon_textures(point_icon: Texture2D, directional_icon: Texture2D, spot_icon: Texture2D) -> void:
	_point_icon = point_icon
	_directional_icon = directional_icon
	_spot_icon = spot_icon
	_materials_ready = false


func _get_gizmo_name() -> String:
	return "N64Lights"


func _has_gizmo(for_node_3d: Node3D) -> bool:
	return for_node_3d != null and (
		for_node_3d.is_class("N64PointLight3D") or
		for_node_3d.is_class("N64DirectionalLight3D") or
		for_node_3d.is_class("N64SpotLight3D")
	)


func _redraw(gizmo: EditorNode3DGizmo) -> void:
	if gizmo == null:
		return

	_ensure_materials()
	gizmo.clear()

	var node := gizmo.get_node_3d()
	if node == null:
		return

	var color := _get_node_color(node)
	var icon_material: Material = null
	if node.is_class("N64PointLight3D"):
		icon_material = get_material(POINT_MATERIAL, gizmo)
	elif node.is_class("N64DirectionalLight3D"):
		icon_material = get_material(DIRECTIONAL_MATERIAL, gizmo)
	elif node.is_class("N64SpotLight3D"):
		icon_material = get_material(SPOT_MATERIAL, gizmo)

	if icon_material != null:
		gizmo.add_unscaled_billboard(icon_material, ICON_SCALE, color)

	if node.is_class("N64DirectionalLight3D"):
		if _is_node_selected(node):
			var lines := PackedVector3Array()
			_append_directional_arrow(lines)
			gizmo.add_lines(lines, get_material(LINES_PRIMARY, gizmo), false, color)
		return

	if node.is_class("N64PointLight3D"):
		if _is_node_selected(node):
			var r: float = node.get_range()
			var points := PackedVector3Array()
			var points_billboard := PackedVector3Array()

			for i in range(CIRCLE_STEPS):
				var ra := deg_to_rad(float(i * 3))
				var rb := deg_to_rad(float((i + 1) * 3))
				var a := Vector2(sin(ra), cos(ra)) * r
				var b := Vector2(sin(rb), cos(rb)) * r

				points.append(Vector3(a.x, 0.0, a.y))
				points.append(Vector3(b.x, 0.0, b.y))
				points.append(Vector3(0.0, a.x, a.y))
				points.append(Vector3(0.0, b.x, b.y))
				points.append(Vector3(a.x, a.y, 0.0))
				points.append(Vector3(b.x, b.y, 0.0))

				points_billboard.append(Vector3(a.x, a.y, 0.0))
				points_billboard.append(Vector3(b.x, b.y, 0.0))

			gizmo.add_lines(points, get_material(LINES_SECONDARY, gizmo), true, color)
			gizmo.add_lines(points_billboard, get_material(LINES_BILLBOARD, gizmo), true, color)
			gizmo.add_handles(
				PackedVector3Array([Vector3(r, 0.0, 0.0)]),
				get_material(HANDLES_BILLBOARD, gizmo),
				PackedInt32Array([HANDLE_RANGE]),
				true
			)
		return

	if node.is_class("N64SpotLight3D") and _is_node_selected(node):
		var r: float = node.get_range()
		var angle: float = node.get_spot_angle()
		var w := r * sin(deg_to_rad(angle))
		var d := r * cos(deg_to_rad(angle))

		var points_primary := PackedVector3Array()
		var points_secondary := PackedVector3Array()

		for i in range(CIRCLE_STEPS):
			var ra := deg_to_rad(float(i * 3))
			var rb := deg_to_rad(float((i + 1) * 3))
			var a := Vector2(sin(ra), cos(ra)) * w
			var b := Vector2(sin(rb), cos(rb)) * w

			points_primary.append(Vector3(a.x, a.y, -d))
			points_primary.append(Vector3(b.x, b.y, -d))

			if i % 15 == 0:
				points_secondary.append(Vector3(a.x, a.y, -d))
				points_secondary.append(Vector3.ZERO)

		points_primary.append(Vector3(0.0, 0.0, -r))
		points_primary.append(Vector3.ZERO)

		gizmo.add_lines(points_primary, get_material(LINES_PRIMARY, gizmo), false, color)
		gizmo.add_lines(points_secondary, get_material(LINES_SECONDARY, gizmo), false, color)
		gizmo.add_handles(
			PackedVector3Array([
				Vector3(0.0, 0.0, -r),
				Vector3(w, 0.0, -d)
			]),
			get_material(HANDLES, gizmo),
			PackedInt32Array([HANDLE_RANGE, HANDLE_SPOT_ANGLE])
		)


func _get_handle_name(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool) -> String:
	if secondary or gizmo == null:
		return ""

	var node := gizmo.get_node_3d()
	if node == null:
		return ""

	if handle_id == HANDLE_RANGE:
		return "Radius"
	if node.is_class("N64SpotLight3D") and handle_id == HANDLE_SPOT_ANGLE:
		return "Aperture"
	return ""


func _get_handle_value(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool) -> Variant:
	if secondary or gizmo == null:
		return null

	var node := gizmo.get_node_3d()
	if node == null:
		return null

	if handle_id == HANDLE_RANGE and (node.is_class("N64PointLight3D") or node.is_class("N64SpotLight3D")):
		return node.get_range()
	if handle_id == HANDLE_SPOT_ANGLE and node.is_class("N64SpotLight3D"):
		return node.get_spot_angle()
	return null


func _set_handle(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool, camera: Camera3D, point: Vector2) -> void:
	if secondary or gizmo == null or camera == null:
		return

	var node := gizmo.get_node_3d()
	if node == null:
		return

	var gt: Transform3D = node.global_transform
	var ray_from := camera.project_ray_origin(point)
	var ray_dir := camera.project_ray_normal(point)

	if node.is_class("N64PointLight3D"):
		var plane := Plane(camera.global_transform.basis.z, gt.origin)
		var hit = plane.intersects_ray(ray_from, ray_dir)
		if hit == null:
			return
		node.set_range(max((hit as Vector3).distance_to(gt.origin), 0.01))
		return

	if node.is_class("N64SpotLight3D"):
		var gi := gt.affine_inverse()
		var s0: Vector3 = gi * ray_from
		var s1: Vector3 = gi * (ray_from + ray_dir * 4096.0)

		if handle_id == HANDLE_RANGE:
			var result := Geometry3D.get_closest_points_between_segments(Vector3.ZERO, Vector3(0.0, 0.0, -4096.0), s0, s1)
			if result.size() >= 1:
				node.set_range(max(-result[0].z, 0.01))
		elif handle_id == HANDLE_SPOT_ANGLE:
			node.set_spot_angle(clampf(_find_closest_angle_to_half_pi_arc(s0, s1, node.get_range()), 0.01, 89.99))


func _commit_handle(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool, restore: Variant, cancel: bool) -> void:
	if secondary or gizmo == null:
		return

	var node := gizmo.get_node_3d()
	if node == null:
		return

	var property_name := ""
	var action_name := ""
	var current_value: Variant = null

	if handle_id == HANDLE_RANGE and (node.is_class("N64PointLight3D") or node.is_class("N64SpotLight3D")):
		property_name = "range"
		action_name = "Change N64 Light Radius"
		current_value = node.get_range()
	elif handle_id == HANDLE_SPOT_ANGLE and node.is_class("N64SpotLight3D"):
		property_name = "spot_angle"
		action_name = "Change N64 Spot Aperture"
		current_value = node.get_spot_angle()
	else:
		return

	if cancel:
		node.set(property_name, restore)
		return

	if current_value == restore:
		return

	if _editor_plugin == null:
		node.set(property_name, current_value)
		return

	var undo_redo := _editor_plugin.get_undo_redo()
	if undo_redo == null:
		node.set(property_name, current_value)
		return

	undo_redo.create_action(action_name)
	undo_redo.add_do_property(node, property_name, current_value)
	undo_redo.add_undo_property(node, property_name, restore)
	undo_redo.commit_action()


func _ensure_materials() -> void:
	if _materials_ready:
		return

	create_material(LINES_PRIMARY, Color(1, 1, 1), false, false, true)
	create_material(LINES_SECONDARY, Color(1, 1, 1, 0.35), false, false, true)
	create_material(LINES_BILLBOARD, Color(1, 1, 1), true, false, true)
	if _point_icon != null:
		create_icon_material(POINT_MATERIAL, _point_icon, false)
	if _directional_icon != null:
		create_icon_material(DIRECTIONAL_MATERIAL, _directional_icon, false)
	if _spot_icon != null:
		create_icon_material(SPOT_MATERIAL, _spot_icon, false)
	create_handle_material(HANDLES)
	create_handle_material(HANDLES_BILLBOARD, true)
	_materials_ready = true


func _get_node_color(node: Node3D) -> Color:
	var color: Color = node.get_color()
	if not node.is_enabled():
		color = color.darkened(0.45)
	return color.lerp(Color.WHITE, 0.2)


func _is_node_selected(node: Node3D) -> bool:
	if node == null:
		return false
	if _editor_plugin == null:
		return true

	var editor_interface := _editor_plugin.get_editor_interface()
	if editor_interface == null:
		return true

	var selection := editor_interface.get_selection()
	if selection == null:
		return true

	return selection.get_selected_nodes().has(node)


func _append_directional_arrow(lines: PackedVector3Array) -> void:
	var arrow_points := [
		Vector3(0.0, 0.0, -1.0),
		Vector3(0.0, 0.8, 0.0),
		Vector3(0.0, 0.3, 0.0),
		Vector3(0.0, 0.3, 1.5),
		Vector3(0.0, -0.3, 1.5),
		Vector3(0.0, -0.3, 0.0),
		Vector3(0.0, -0.8, 0.0)
	]

	for side in range(2):
		var basis := Basis(Vector3(0.0, 0.0, 1.0), PI * float(side) * 0.5)
		for i in range(arrow_points.size()):
			var v1: Vector3 = basis * (arrow_points[i] - Vector3(0.0, 0.0, 1.5))
			var v2: Vector3 = basis * (arrow_points[(i + 1) % arrow_points.size()] - Vector3(0.0, 0.0, 1.5))
			v1.z = -v1.z
			v2.z = -v2.z
			lines.append(v1)
			lines.append(v2)


func _find_closest_angle_to_half_pi_arc(from_point: Vector3, to_point: Vector3, arc_radius: float) -> float:
	const ARC_TEST_POINTS := 64
	var min_distance := 1.0e20
	var min_point := Vector3.ZERO

	for i in range(ARC_TEST_POINTS):
		var a := float(i) * PI * 0.5 / float(ARC_TEST_POINTS)
		var an := float(i + 1) * PI * 0.5 / float(ARC_TEST_POINTS)
		var p := Vector3(cos(a), 0.0, -sin(a)) * arc_radius
		var n := Vector3(cos(an), 0.0, -sin(an)) * arc_radius
		var result := Geometry3D.get_closest_points_between_segments(p, n, from_point, to_point)
		if result.size() < 2:
			continue

		var distance := result[0].distance_to(result[1])
		if distance < min_distance:
			min_distance = distance
			min_point = result[0]

	var angle := (PI * 0.5) - Vector2(min_point.x, -min_point.z).angle()
	return rad_to_deg(angle)

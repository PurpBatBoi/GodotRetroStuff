@tool
extends Node3D

const COMB_SHADER := preload("res://shaders/n64combinertest/n64comb_test.gdshader")
const LIT_SHADER := preload("res://shaders/n64_vertex_lit.gdshader")
const ICON_TEXTURE := preload("res://icon.svg")

const COLOR_A_COMBINED := 0
const COLOR_A_TEX0 := 1
const COLOR_A_TEX1 := 2
const COLOR_A_PRIM := 3
const COLOR_A_SHADE := 4
const COLOR_A_ENV := 5
const COLOR_A_ONE := 6
const COLOR_A_NOISE := 7
const COLOR_A_ZERO := 8

const COLOR_B_COMBINED := 0
const COLOR_B_TEX0 := 1
const COLOR_B_TEX1 := 2
const COLOR_B_PRIM := 3
const COLOR_B_SHADE := 4
const COLOR_B_ENV := 5
const COLOR_B_CENTER := 6
const COLOR_B_ZERO := 7

const COLOR_C_COMBINED := 0
const COLOR_C_TEX0 := 1
const COLOR_C_TEX1 := 2
const COLOR_C_PRIM := 3
const COLOR_C_SHADE := 4
const COLOR_C_ENV := 5
const COLOR_C_SCALE := 6
const COLOR_C_COMB_ALPHA := 7
const COLOR_C_TEX0_ALPHA := 8
const COLOR_C_TEX1_ALPHA := 9
const COLOR_C_PRIM_ALPHA := 10
const COLOR_C_SHADE_ALPHA := 11
const COLOR_C_ENV_ALPHA := 12
const COLOR_C_LOD_FRAC := 13
const COLOR_C_PRIM_LOD_FRAC := 14
const COLOR_C_ZERO := 15

const COLOR_D_COMBINED := 0
const COLOR_D_TEX0 := 1
const COLOR_D_TEX1 := 2
const COLOR_D_PRIM := 3
const COLOR_D_SHADE := 4
const COLOR_D_ENV := 5
const COLOR_D_ONE := 6
const COLOR_D_ZERO := 7

const ALPHA_ABD_COMBINED := 0
const ALPHA_ABD_TEX0 := 1
const ALPHA_ABD_TEX1 := 2
const ALPHA_ABD_PRIM := 3
const ALPHA_ABD_SHADE := 4
const ALPHA_ABD_ENV := 5
const ALPHA_ABD_ONE := 6
const ALPHA_ABD_ZERO := 7

const ALPHA_C_LOD_FRAC := 0
const ALPHA_C_COMBINED := 1
const ALPHA_C_TEX0 := 2
const ALPHA_C_TEX1 := 3
const ALPHA_C_PRIM := 4
const ALPHA_C_SHADE := 5
const ALPHA_C_ENV := 6
const ALPHA_C_PRIM_LOD_FRAC := 7
const ALPHA_C_ZERO := 8

func _enter_tree() -> void:
	if Engine.is_editor_hint():
		call_deferred("_apply_visual_test_materials")


func _ready() -> void:
	_apply_visual_test_materials()


func _apply_visual_test_materials() -> void:
	if not is_inside_tree():
		return

	_setup_backdrop($"Alpha/BackdropClip", Color(0.18, 0.44, 0.72, 1.0))
	_setup_backdrop($"Alpha/BackdropShade", Color(0.78, 0.35, 0.24, 1.0))
	_setup_backdrop($"Alpha/BackdropCombined", Color(0.18, 0.62, 0.32, 1.0))

	_assign($"Alpha/Tex0Clip", _make_alpha_tex0_clip_material())
	_assign($"Alpha/ShadeAlpha", _make_alpha_shade_alpha_material())
	_assign($"Alpha/CombinedAlphaTint", _make_alpha_combined_tint_material())

	_assign($"LOD/Large", _make_lod_visual_material())
	_assign($"LOD/Medium", _make_lod_visual_material())
	_assign($"LOD/Small", _make_lod_visual_material())
	_assign($"LOD/PrimFrac", _make_prim_lod_visual_material())

	_assign($"TwoCycle/ModulateAdd", _make_two_cycle_modulate_add_material())
	_assign($"TwoCycle/PrimShadeTex", _make_two_cycle_prim_shade_tex_material())
	_assign($"TwoCycle/CombinedAlphaTint", _make_two_cycle_combined_alpha_tint_material())

	_assign($"Manager/Box", _make_lit_tex_shade_material())
	_assign($"Manager/Sphere", _make_lit_two_cycle_material())


func _assign(mesh: GeometryInstance3D, material: Material) -> void:
	mesh.material_override = material


func _setup_backdrop(mesh: MeshInstance3D, color: Color) -> void:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.material_override = material


func _make_base_combiner_material(shader: Shader) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = shader

	var defaults := {
		"use_vertex_color": false,
		"shade_color": Color.WHITE,
		"Texture0": ICON_TEXTURE,
		"Texture1": ICON_TEXTURE,
		"Texture0_Mask": Vector2(256, 256),
		"Texture0_Scale": Vector2.ONE,
		"Texture0_Offset": Vector2.ZERO,
		"Texture0_ClampX": false,
		"Texture0_ClampY": false,
		"Texture0_MirrorX": false,
		"Texture0_MirrorY": false,
		"Texture0_Scroll": Vector2.ZERO,
		"Texture1_Mask": Vector2(256, 256),
		"Texture1_Scale": Vector2.ONE,
		"Texture1_Offset": Vector2.ZERO,
		"Texture1_ClampX": false,
		"Texture1_ClampY": false,
		"Texture1_MirrorX": false,
		"Texture1_MirrorY": false,
		"Texture1_Scroll": Vector2.ZERO,
		"material_prim_r": 1.0,
		"material_prim_g": 1.0,
		"material_prim_b": 1.0,
		"material_prim_a": 1.0,
		"material_env_r": 0.18,
		"material_env_g": 0.2,
		"material_env_b": 0.34,
		"material_env_a": 1.0,
		"chroma_key_center": Vector3.ZERO,
		"chroma_key_scale": Vector3.ZERO,
		"prim_lod_frac": 0.0,
		"prim_lod_min": 0.0,
		"mip_count": 4,
		"alpha_clip": 0.0,
		"atlas_region_0": Vector2i.ZERO,
		"atlas_offset_0": Vector2i.ZERO,
		"atlas_region_1": Vector2i.ZERO,
		"atlas_offset_1": Vector2i.ZERO,
		"atlas_seam_hiding": 0,
		"atlas_seam_zoom": 0.0,
		"use_tex_gen": false,
		"filter_mode": 1,
		"use_two_cycle": false,
		"use_texture_lod": false,
		"texture_detail_mode": 0,
		"tex0_mono": false,
		"tex1_mono": false,
		"tex0_quantize": 0,
		"tex1_quantize": 0,
	}

	for key in defaults:
		material.set_shader_parameter(key, defaults[key])

	return material


func _set_cycle0(material: ShaderMaterial, color: Vector4i, alpha: Vector4i) -> void:
	material.set_shader_parameter("cc0_color_a", color.x)
	material.set_shader_parameter("cc0_color_b", color.y)
	material.set_shader_parameter("cc0_color_c", color.z)
	material.set_shader_parameter("cc0_color_d", color.w)
	material.set_shader_parameter("cc0_alpha_a", alpha.x)
	material.set_shader_parameter("cc0_alpha_b", alpha.y)
	material.set_shader_parameter("cc0_alpha_c", alpha.z)
	material.set_shader_parameter("cc0_alpha_d", alpha.w)


func _set_cycle1(material: ShaderMaterial, color: Vector4i, alpha: Vector4i) -> void:
	material.set_shader_parameter("cc1_color_a", color.x)
	material.set_shader_parameter("cc1_color_b", color.y)
	material.set_shader_parameter("cc1_color_c", color.z)
	material.set_shader_parameter("cc1_color_d", color.w)
	material.set_shader_parameter("cc1_alpha_a", alpha.x)
	material.set_shader_parameter("cc1_alpha_b", alpha.y)
	material.set_shader_parameter("cc1_alpha_c", alpha.z)
	material.set_shader_parameter("cc1_alpha_d", alpha.w)


func _make_alpha_tex0_clip_material() -> ShaderMaterial:
	var material := _make_base_combiner_material(COMB_SHADER)
	_set_cycle0(
		material,
		Vector4i(COLOR_A_ZERO, COLOR_B_ZERO, COLOR_C_ZERO, COLOR_D_TEX0),
		Vector4i(ALPHA_ABD_ONE, ALPHA_ABD_ZERO, ALPHA_C_TEX0, ALPHA_ABD_ZERO)
	)
	_set_cycle1(
		material,
		Vector4i(COLOR_A_ZERO, COLOR_B_ZERO, COLOR_C_ZERO, COLOR_D_ZERO),
		Vector4i(ALPHA_ABD_ZERO, ALPHA_ABD_ZERO, ALPHA_C_ZERO, ALPHA_ABD_ZERO)
	)
	material.set_shader_parameter("alpha_clip", 0.5)
	return material


func _make_alpha_shade_alpha_material() -> ShaderMaterial:
	var material := _make_base_combiner_material(COMB_SHADER)
	_set_cycle0(
		material,
		Vector4i(COLOR_A_ZERO, COLOR_B_ZERO, COLOR_C_ZERO, COLOR_D_TEX0),
		Vector4i(ALPHA_ABD_ONE, ALPHA_ABD_ZERO, ALPHA_C_SHADE, ALPHA_ABD_ZERO)
	)
	_set_cycle1(
		material,
		Vector4i(COLOR_A_ZERO, COLOR_B_ZERO, COLOR_C_ZERO, COLOR_D_ZERO),
		Vector4i(ALPHA_ABD_ZERO, ALPHA_ABD_ZERO, ALPHA_C_ZERO, ALPHA_ABD_ZERO)
	)
	material.set_shader_parameter("shade_color", Color(1.0, 1.0, 1.0, 0.35))
	return material


func _make_alpha_combined_tint_material() -> ShaderMaterial:
	var material := _make_base_combiner_material(COMB_SHADER)
	_set_cycle0(
		material,
		Vector4i(COLOR_A_ZERO, COLOR_B_ZERO, COLOR_C_ZERO, COLOR_D_TEX0),
		Vector4i(ALPHA_ABD_ONE, ALPHA_ABD_ZERO, ALPHA_C_TEX0, ALPHA_ABD_ZERO)
	)
	_set_cycle1(
		material,
		Vector4i(COLOR_A_PRIM, COLOR_B_ENV, COLOR_C_COMB_ALPHA, COLOR_D_ENV),
		Vector4i(ALPHA_ABD_ZERO, ALPHA_ABD_ZERO, ALPHA_C_ZERO, ALPHA_ABD_ONE)
	)
	material.set_shader_parameter("use_two_cycle", true)
	material.set_shader_parameter("material_prim_r", 1.0)
	material.set_shader_parameter("material_prim_g", 0.24)
	material.set_shader_parameter("material_prim_b", 0.14)
	material.set_shader_parameter("material_env_r", 0.08)
	material.set_shader_parameter("material_env_g", 0.1)
	material.set_shader_parameter("material_env_b", 0.42)
	return material


func _make_lod_visual_material() -> ShaderMaterial:
	var material := _make_base_combiner_material(COMB_SHADER)
	_set_cycle0(
		material,
		Vector4i(COLOR_A_ONE, COLOR_B_ZERO, COLOR_C_LOD_FRAC, COLOR_D_ZERO),
		Vector4i(ALPHA_ABD_ZERO, ALPHA_ABD_ZERO, ALPHA_C_ZERO, ALPHA_ABD_ONE)
	)
	_set_cycle1(
		material,
		Vector4i(COLOR_A_ZERO, COLOR_B_ZERO, COLOR_C_ZERO, COLOR_D_ZERO),
		Vector4i(ALPHA_ABD_ZERO, ALPHA_ABD_ZERO, ALPHA_C_ZERO, ALPHA_ABD_ZERO)
	)
	material.set_shader_parameter("use_texture_lod", true)
	material.set_shader_parameter("mip_count", 4)
	return material


func _make_prim_lod_visual_material() -> ShaderMaterial:
	var material := _make_base_combiner_material(COMB_SHADER)
	_set_cycle0(
		material,
		Vector4i(COLOR_A_ONE, COLOR_B_ZERO, COLOR_C_PRIM_LOD_FRAC, COLOR_D_ZERO),
		Vector4i(ALPHA_ABD_ZERO, ALPHA_ABD_ZERO, ALPHA_C_ZERO, ALPHA_ABD_ONE)
	)
	_set_cycle1(
		material,
		Vector4i(COLOR_A_ZERO, COLOR_B_ZERO, COLOR_C_ZERO, COLOR_D_ZERO),
		Vector4i(ALPHA_ABD_ZERO, ALPHA_ABD_ZERO, ALPHA_C_ZERO, ALPHA_ABD_ZERO)
	)
	material.set_shader_parameter("prim_lod_frac", 0.75)
	return material


func _make_two_cycle_modulate_add_material() -> ShaderMaterial:
	var material := _make_base_combiner_material(COMB_SHADER)
	_set_cycle0(
		material,
		Vector4i(COLOR_A_TEX0, COLOR_B_ZERO, COLOR_C_SHADE, COLOR_D_ZERO),
		Vector4i(ALPHA_ABD_ONE, ALPHA_ABD_ZERO, ALPHA_C_TEX0, ALPHA_ABD_ZERO)
	)
	_set_cycle1(
		material,
		Vector4i(COLOR_A_ONE, COLOR_B_ZERO, COLOR_C_COMBINED, COLOR_D_ENV),
		Vector4i(ALPHA_ABD_ZERO, ALPHA_ABD_ZERO, ALPHA_C_ZERO, ALPHA_ABD_ONE)
	)
	material.set_shader_parameter("use_two_cycle", true)
	material.set_shader_parameter("shade_color", Color(1.0, 0.45, 0.28, 1.0))
	material.set_shader_parameter("material_env_r", 0.16)
	material.set_shader_parameter("material_env_g", 0.08)
	material.set_shader_parameter("material_env_b", 0.22)
	return material


func _make_two_cycle_prim_shade_tex_material() -> ShaderMaterial:
	var material := _make_base_combiner_material(COMB_SHADER)
	_set_cycle0(
		material,
		Vector4i(COLOR_A_PRIM, COLOR_B_ZERO, COLOR_C_SHADE, COLOR_D_ZERO),
		Vector4i(ALPHA_ABD_ONE, ALPHA_ABD_ZERO, ALPHA_C_SHADE, ALPHA_ABD_ZERO)
	)
	_set_cycle1(
		material,
		Vector4i(COLOR_A_COMBINED, COLOR_B_ZERO, COLOR_C_TEX0, COLOR_D_ZERO),
		Vector4i(ALPHA_ABD_COMBINED, ALPHA_ABD_ZERO, ALPHA_C_TEX0, ALPHA_ABD_ZERO)
	)
	material.set_shader_parameter("use_two_cycle", true)
	material.set_shader_parameter("shade_color", Color(0.48, 1.0, 0.42, 1.0))
	material.set_shader_parameter("material_prim_r", 1.0)
	material.set_shader_parameter("material_prim_g", 0.92)
	material.set_shader_parameter("material_prim_b", 0.2)
	return material


func _make_two_cycle_combined_alpha_tint_material() -> ShaderMaterial:
	var material := _make_base_combiner_material(COMB_SHADER)
	_set_cycle0(
		material,
		Vector4i(COLOR_A_ZERO, COLOR_B_ZERO, COLOR_C_ZERO, COLOR_D_TEX0),
		Vector4i(ALPHA_ABD_ONE, ALPHA_ABD_ZERO, ALPHA_C_SHADE, ALPHA_ABD_ZERO)
	)
	_set_cycle1(
		material,
		Vector4i(COLOR_A_ENV, COLOR_B_PRIM, COLOR_C_COMB_ALPHA, COLOR_D_PRIM),
		Vector4i(ALPHA_ABD_ZERO, ALPHA_ABD_ZERO, ALPHA_C_ZERO, ALPHA_ABD_ONE)
	)
	material.set_shader_parameter("use_two_cycle", true)
	material.set_shader_parameter("shade_color", Color(1.0, 1.0, 1.0, 0.4))
	material.set_shader_parameter("material_prim_r", 0.18)
	material.set_shader_parameter("material_prim_g", 0.1)
	material.set_shader_parameter("material_prim_b", 0.5)
	material.set_shader_parameter("material_env_r", 0.95)
	material.set_shader_parameter("material_env_g", 0.2)
	material.set_shader_parameter("material_env_b", 0.1)
	return material


func _make_lit_tex_shade_material() -> ShaderMaterial:
	var material := _make_base_combiner_material(LIT_SHADER)
	_set_cycle0(
		material,
		Vector4i(COLOR_A_TEX0, COLOR_B_ZERO, COLOR_C_SHADE, COLOR_D_ZERO),
		Vector4i(ALPHA_ABD_ONE, ALPHA_ABD_ZERO, ALPHA_C_TEX0, ALPHA_ABD_ZERO)
	)
	_set_cycle1(
		material,
		Vector4i(COLOR_A_ZERO, COLOR_B_ZERO, COLOR_C_ZERO, COLOR_D_ZERO),
		Vector4i(ALPHA_ABD_ZERO, ALPHA_ABD_ZERO, ALPHA_C_ZERO, ALPHA_ABD_ZERO)
	)
	material.set_shader_parameter("shade_color", Color(1.0, 0.96, 0.82, 1.0))
	return material


func _make_lit_two_cycle_material() -> ShaderMaterial:
	var material := _make_base_combiner_material(LIT_SHADER)
	_set_cycle0(
		material,
		Vector4i(COLOR_A_TEX0, COLOR_B_ZERO, COLOR_C_SHADE, COLOR_D_ZERO),
		Vector4i(ALPHA_ABD_ONE, ALPHA_ABD_ZERO, ALPHA_C_TEX0, ALPHA_ABD_ZERO)
	)
	_set_cycle1(
		material,
		Vector4i(COLOR_A_ONE, COLOR_B_ZERO, COLOR_C_COMBINED, COLOR_D_ENV),
		Vector4i(ALPHA_ABD_ZERO, ALPHA_ABD_ZERO, ALPHA_C_ZERO, ALPHA_ABD_ONE)
	)
	material.set_shader_parameter("use_two_cycle", true)
	material.set_shader_parameter("shade_color", Color(0.62, 1.0, 0.56, 1.0))
	material.set_shader_parameter("material_env_r", 0.12)
	material.set_shader_parameter("material_env_g", 0.18)
	material.set_shader_parameter("material_env_b", 0.42)
	return material

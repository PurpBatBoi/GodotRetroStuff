shader_type spatial;
render_mode unshaded, cull_back;

#define RLS_FILTER_3POINT
#define RLS_TWO_CYCLE
#define RLS_INPUT_TEX1
#define RLS_INPUT_SHADE_ALPHA 
#define RLS_VERTEX_COLOR_GAMMA
#define RLS_ATLAS

#include "res://shaders/shaderinclude/RDPcombiner.gdshaderinc"

// ── Light count cap ────────────────────────────────────────────────────────────
// Override the shared fallback (8) for this material variant.
#ifndef RLS_MAX_LIGHTS
#define RLS_MAX_LIGHTS 2
#endif

#include "res://shaders/shaderinclude/vertexLightProcess.gdshaderinc"

// ── Varyings ───────────────────────────────────────────────────────────────────
varying vec3 additive_light;

// ── Material ───────────────────────────────────────────────────────────────────
group_uniforms Material;
	/** Use vertex color RGB as shade instead of shade_color. */
	uniform bool use_vertex_color = false;
	/** Use vertex color alpha channel. */
	uniform bool use_vertex_alpha = false;
	/** Flat shade color used when vertex color is disabled. */
	uniform vec4 shade_color : source_color = vec4(1.0);
group_uniforms;

// ── Vertex ─────────────────────────────────────────────────────────────────────
void vertex()
{
	vec3 world_pos    = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);

	vec4 base_shade = vec4(
		use_vertex_color ? COLOR.rgb : shade_color.rgb,
		(use_vertex_color || use_vertex_alpha) ? COLOR.a : shade_color.a
	);

	vec4 shaded_input;
	vec3 additive_light_value;
	rls_vertex_light_process(world_pos, world_normal, base_shade, shaded_input, additive_light_value);
	additive_light = additive_light_value;

	RLSCombVertexData cd = rlscomb_vertex_data(
		NORMAL, shaded_input,
		use_vertex_color ? 1.0 : 0.0,
		UV, VIEW_MATRIX, MODEL_NORMAL_MATRIX
	);
	cc_shade                   = cd.cc_shade;
	cc_shade_from_vertex_color = cd.cc_shade_from_vertex_color;
	uv                         = cd.uv;
	tileSize                   = cd.tileSize;
}

// ── Fragment ───────────────────────────────────────────────────────────────────
void fragment()
{
	vec4 result = rlscomb_fragment(SCREEN_UV);
	ALBEDO = clamp(result.rgb + additive_light, 0.0, 1.0);
}

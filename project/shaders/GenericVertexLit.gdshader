shader_type spatial;
render_mode unshaded, cull_back;

#define N64_FILTER_3POINT
#define N64_VERTEX_COLOR_GAMMA
#define N64_ATLAS

#include "res://shaders/shaderinclude/RDPcombiner.gdshaderinc"

// ── Light count cap ────────────────────────────────────────────────────────────
// Set to however many lights this material needs. The loop bound becomes a
// compile-time constant, letting the GPU unroll it completely.
// Valid range: 1–8. Default 4 covers most N64-style scenes.
#ifndef N64_MAX_LIGHTS
#define N64_MAX_LIGHTS 1
#endif

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

// ── Lighting ───────────────────────────────────────────────────────────────────
group_uniforms Lighting;
	/** Use material_ambient instead of global_ambient. */
	uniform bool use_material_ambient = false;
	uniform vec4 material_ambient : source_color = vec4(0.12, 0.12, 0.16, 1.0);
	uniform vec4 global_ambient   : source_color = vec4(0.12, 0.12, 0.16, 1.0);

	/** 0 = direct light fully multiplied into shade (classic N64).
	 *  1 = direct light fully additive on top of combiner output. */
	uniform float direct_light_additive_mix : hint_range(0.0, 1.0) = 0.0;

	// Light arrays are always declared at max size (8) to satisfy GLSL's
	// requirement for fixed array sizes. Only the first N64_MAX_LIGHTS
	// entries are read at runtime.
	/** Number of active lights (capped to N64_MAX_LIGHTS at runtime). */
	uniform int  light_count = 0;
	/** xyz = direction (directional) or world position (point). w > 0.5 = directional. */
	uniform vec4 light_vector_type[8];
	/** rgb = color, a = energy. */
	uniform vec4 light_color_energy[8];
	/** Attenuation range for point lights (ignored for directional). */
	uniform float light_range[8];
	/** Attenuation falloff exponent for point lights. */
	uniform float light_attenuation[8];
group_uniforms;

// ── Lighting helpers ───────────────────────────────────────────────────────────
vec3 compute_ambient()
{
	vec4 a = use_material_ambient ? material_ambient : global_ambient;
	return a.rgb * a.a;
}

vec3 compute_direct(vec3 world_pos, vec3 world_normal)
{
	vec3  acc        = vec3(0.0);
	// Clamp at runtime too — guards against light_count > N64_MAX_LIGHTS in data.
	int   count      = min(light_count, N64_MAX_LIGHTS);

	// N64_MAX_LIGHTS is a compile-time constant, so this loop can be fully
	// unrolled by the driver. The inner `if (i >= count) break` becomes a
	// series of predicated instructions rather than a real branch.
	for (int i = 0; i < N64_MAX_LIGHTS; i++) {
		if (i >= count) break;

		vec4  info       = light_vector_type[i];
		vec4  data       = light_color_energy[i];
		vec3  light_dir;
		float attenuation = 1.0;

		if (info.w > 0.5) {
			// Directional light
			light_dir = normalize(info.xyz);
		} else {
			// Point light
			vec3  to_light = info.xyz - world_pos;
			float dist     = length(to_light);
			if (dist <= 0.0001) continue;
			float range    = max(light_range[i], 0.0001);
			float exponent = light_attenuation[i] > 0.0 ? light_attenuation[i] : 1.0;
			light_dir      = to_light / dist;
			attenuation    = pow(1.0 - smoothstep(0.0, range, dist), exponent);
		}

		float diffuse = max(dot(world_normal, light_dir), 0.0);
		acc += data.rgb * data.a * diffuse * attenuation;
	}
	return acc;
}

// ── Vertex ─────────────────────────────────────────────────────────────────────
void vertex()
{
	vec3 world_pos    = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);

	vec4 base_shade = vec4(
		use_vertex_color ? COLOR.rgb : shade_color.rgb,
		(use_vertex_color || use_vertex_alpha) ? COLOR.a : shade_color.a
	);

	vec3  ambient      = compute_ambient();
	vec3  direct       = compute_direct(world_pos, world_normal);
	float add_mix      = clamp(direct_light_additive_mix, 0.0, 1.0);
	vec3  shaded_light = ambient + direct * (1.0 - add_mix);

	vec4 shaded_input = vec4(base_shade.rgb * shaded_light, base_shade.a);
	additive_light    = direct * add_mix;

	N64CombVertexData cd = n64comb_vertex_data(
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
	vec4 result = n64comb_fragment(SCREEN_UV);
	ALBEDO = clamp(result.rgb + additive_light, 0.0, 1.0);
}

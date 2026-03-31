// vertexLightProcess.gdshaderinc
// Shared N64-style vertex lighting uniforms and helpers.

// Keep a fallback here so Godot can validate this include on its own.
// Main shaders can still override it by defining N64_MAX_LIGHTS first.
// Default to the full supported array size, then let materials opt down.
#ifndef N64_MAX_LIGHTS
#define N64_MAX_LIGHTS 8
#endif

group_uniforms Lighting;
	/** Use material_ambient instead of global_ambient. */
	uniform bool use_material_ambient = false;
	uniform vec4 material_ambient : source_color = vec4(0.12, 0.12, 0.16, 1.0);
	uniform vec4 global_ambient   : source_color = vec4(0.12, 0.12, 0.16, 1.0);

	/** 0 = direct light fully multiplied into shade (classic N64).
	 *  1 = direct light fully additive on top of combiner output. */
	uniform float direct_light_additive_mix : hint_range(0.0, 1.0) = 0.0;
	/** Treat fake local lights as normal lights for this material/mesh. */
	uniform bool ignore_fake_lights = false;

	// Light arrays are always declared at max size (8) to satisfy GLSL's
	// requirement for fixed array sizes. Only the first N64_MAX_LIGHTS
	// entries are read at runtime.
	/** Number of active lights (capped to N64_MAX_LIGHTS at runtime). */
	uniform int  light_count = 0;
	/** xyz = direction (directional/fake point) or world position (point/spot). w: 0 = point, 1 = directional, 2 = spotlight. */
	uniform vec4 light_vector_type[8];
	/** rgb = color, a = energy. */
	uniform vec4 light_color_energy[8];
	/** xyz = spotlight direction, w = cos(inner angle). Ignored by non-spot lights. */
	uniform vec4 light_spot_direction_inner[8];
	/** Attenuation range for point lights (ignored for directional). */
	uniform float light_range[8];
	/** Attenuation falloff exponent for point and spot lights. */
	uniform float light_attenuation[8];
	/** cos(outer angle) for spotlights. Ignored by other light types. */
	uniform float light_spot_outer_cos[8];
group_uniforms;

vec3 n64_compute_ambient()
{
	vec4 a = use_material_ambient ? material_ambient : global_ambient;
	return a.rgb * a.a;
}

vec3 n64_compute_direct(vec3 world_pos, vec3 world_normal)
{
	vec3  acc        = vec3(0.0);
	int   count      = min(light_count, N64_MAX_LIGHTS);

	for (int i = 0; i < N64_MAX_LIGHTS; i++) {
		if (i >= count) break;

		vec4  info        = light_vector_type[i];
		vec4  data        = light_color_energy[i];
		vec3  light_dir;
		float attenuation = 1.0;

		if (info.w > 1.5) {
			vec3  to_light = info.xyz - world_pos;
			float dist     = length(to_light);
			if (dist <= 0.0001) continue;
			float range    = max(light_range[i], 0.0001);
			float exponent = light_attenuation[i] > 0.0 ? light_attenuation[i] : 1.0;
			light_dir      = to_light / dist;
			attenuation    = pow(1.0 - smoothstep(0.0, range, dist), exponent);

			vec4  spot_data = light_spot_direction_inner[i];
			float inner_cos = clamp(spot_data.w, -1.0, 1.0);
			float outer_cos = clamp(light_spot_outer_cos[i], -1.0, 1.0);
			float cone_dot  = dot(normalize(spot_data.xyz), -light_dir);
			if (inner_cos <= outer_cos + 0.0001) {
				attenuation *= cone_dot >= outer_cos ? 1.0 : 0.0;
			} else {
				attenuation *= smoothstep(outer_cos, inner_cos, cone_dot);
			}
		} else if (info.w > 0.5) {
			light_dir = normalize(info.xyz);
		} else {
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

void n64_vertex_light_process(vec3 world_pos, vec3 world_normal, vec4 base_shade, out vec4 shaded_input, out vec3 additive_light_out)
{
	vec3  ambient      = n64_compute_ambient();
	vec3  direct       = n64_compute_direct(world_pos, world_normal);
	float add_mix      = clamp(direct_light_additive_mix, 0.0, 1.0);
	vec3  shaded_light = ambient + direct * (1.0 - add_mix);

	shaded_input       = vec4(base_shade.rgb * shaded_light, base_shade.a);
	additive_light_out = direct * add_mix;
}

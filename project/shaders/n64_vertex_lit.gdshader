shader_type spatial;
render_mode unshaded, cull_back;

#include "res://shaders/n64combinertest/n64comb.gdshaderinc"

group_uniforms Material;
uniform bool use_vertex_color = false;
uniform bool use_vertex_alpha = false;
uniform vec4 shade_color : source_color = vec4(1.0);
group_uniforms;

group_uniforms Lighting;
uniform bool use_material_ambient = false;
uniform vec4 material_ambient : source_color = vec4(0.12, 0.12, 0.16, 1.0);
uniform vec4 global_ambient : source_color = vec4(0.12, 0.12, 0.16, 1.0);

uniform int light_count = 0;
uniform vec4 light_vector_type[8];
uniform vec4 light_color_energy[8];
uniform float light_range[8];
uniform float light_attenuation[8];
group_uniforms;

vec3 compute_vertex_light(vec3 world_pos, vec3 world_normal) {
	vec4 ambient = use_material_ambient ? material_ambient : global_ambient;
	vec3 accumulated = ambient.rgb * ambient.a;

	for (int i = 0; i < 8; i++) {
		if (i >= light_count) {
			break;
		}

		vec4 light_info = light_vector_type[i];
		vec4 light_data = light_color_energy[i];
		vec3 light_dir = vec3(0.0);
		float attenuation = 1.0;

		if (light_info.w > 0.5) {
			light_dir = normalize(light_info.xyz);
		} else {
			vec3 to_light = light_info.xyz - world_pos;
			float distance_to_light = length(to_light);
			if (distance_to_light <= 0.0001) {
				continue;
			}

			float range = max(light_range[i], 0.0001);
			float attenuation_exponent = light_attenuation[i] > 0.0 ? light_attenuation[i] : 1.0;
			light_dir = to_light / distance_to_light;
			attenuation = pow(1.0 - smoothstep(0.0, range, distance_to_light), attenuation_exponent);
		}

		float diffuse = max(dot(world_normal, light_dir), 0.0);
		accumulated += light_data.rgb * light_data.a * diffuse * attenuation;
	}

	return accumulated;
}

void vertex() {
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	vec4 base_shade = vec4(
		use_vertex_color ? COLOR.rgb : shade_color.rgb,
		(use_vertex_color || use_vertex_alpha) ? COLOR.a : shade_color.a
	);
	vec3 lit = compute_vertex_light(world_pos, world_normal);
	vec4 shaded_input = vec4(base_shade.rgb * lit, base_shade.a);

	N64CombVertexData comb_data = n64comb_vertex_data(NORMAL, shaded_input, use_vertex_color ? 1.0 : 0.0, UV, VIEW_MATRIX, MODEL_NORMAL_MATRIX);
	cc_shade = comb_data.cc_shade;
	cc_shade_from_vertex_color = comb_data.cc_shade_from_vertex_color;
	uv = comb_data.uv;
	tileSize = comb_data.tileSize;
}

void fragment() {
	vec4 comb_color = n64comb_fragment(SCREEN_UV);
	ALBEDO = comb_color.rgb;
}

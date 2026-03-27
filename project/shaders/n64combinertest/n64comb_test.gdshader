shader_type spatial;
render_mode unshaded, cull_disabled;

#include "res://shaders/n64combinertest/n64comb.gdshaderinc"

group_uniforms Harness;
uniform bool use_vertex_color = false;
uniform bool use_vertex_alpha = false;
uniform vec4 shade_color : source_color = vec4(1.0);
group_uniforms;

void vertex() {
	vec4 input_shade = vec4(
		use_vertex_color ? COLOR.rgb : shade_color.rgb,
		(use_vertex_color || use_vertex_alpha) ? COLOR.a : shade_color.a
	);
	N64CombVertexData comb_data = n64comb_vertex_data(NORMAL, input_shade, use_vertex_color ? 1.0 : 0.0, UV, VIEW_MATRIX, MODEL_NORMAL_MATRIX);
	cc_shade = comb_data.cc_shade;
	cc_shade_from_vertex_color = comb_data.cc_shade_from_vertex_color;
	uv = comb_data.uv;
	tileSize = comb_data.tileSize;
}

void fragment() {
	vec4 comb_color = n64comb_fragment(SCREEN_UV);
	ALBEDO = comb_color.rgb;
	ALPHA = comb_color.a;
}

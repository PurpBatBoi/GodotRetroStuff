shader_type spatial;
render_mode unshaded;

uniform sampler2D tex : source_color; // 'source_color' tells Godot this is sRGB

// Keep your function at the top level (outside of fragment/vertex)
vec3 fromLinear(vec3 linearRGB)
{
    bvec3 cutoff = lessThan(linearRGB, vec3(0.0031308));
    vec3 higher = vec3(1.055) * pow(linearRGB, vec3(1.0/2.4)) - vec3(0.055);
    vec3 lower = linearRGB * 12.92;

    return mix(higher, lower, cutoff);
}

void fragment() {
    // 1. Sample the texture using the built-in UV coordinates
    vec4 tex_color = texture(tex, UV);
    
    // 2. Convert vertex COLOR from linear to sRGB
    vec3 corrected_vertex_color = fromLinear(COLOR.rgb);
    
    // 3. Multiply them together and assign to ALBEDO
    ALBEDO = corrected_vertex_color * tex_color.rgb;
}

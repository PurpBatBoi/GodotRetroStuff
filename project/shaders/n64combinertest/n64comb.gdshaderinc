// CC Color inputs
const int CC_C_1             = 1;
const int CC_C_COMB          = 2;
const int CC_C_TEX0          = 3;
const int CC_C_TEX1          = 4;
const int CC_C_PRIM          = 5;
const int CC_C_SHADE         = 6;
const int CC_C_ENV           = 7;
const int CC_C_COMB_ALPHA    = 10;
const int CC_C_TEX0_ALPHA    = 11;
const int CC_C_TEX1_ALPHA    = 12;
const int CC_C_PRIM_ALPHA    = 13;
const int CC_C_SHADE_ALPHA   = 14;
const int CC_C_ENV_ALPHA     = 15;
const int CC_C_LOD_FRAC      = 16;
const int CC_C_PRIM_LOD_FRAC = 17;
const int CC_C_NOISE         = 18;
	const int CC_C_CHROMA_KEY_CENTER = 19;
	const int CC_C_CHROMA_KEY_SCALE  = 20;

// CC Alpha inputs
const int CC_A_1             = 1;
const int CC_A_COMB          = 2;
const int CC_A_TEX0          = 3;
const int CC_A_TEX1          = 4;
const int CC_A_PRIM          = 5;
const int CC_A_SHADE         = 6;
const int CC_A_ENV           = 7;
const int CC_A_LOD_FRAC      = 8;
const int CC_A_PRIM_LOD_FRAC = 9;

// Per-slot UI index -> CC constant lookup tables.
// Each slot exposes only the inputs valid for that position per the N64 RDP spec.
//
// Color A:  Combined, Tex0, Tex1, Prim, Shade, Env, 1, Noise, 0  (9 options)
const int CC_COLOR_A_TABLE[9] = int[](CC_C_COMB, CC_C_TEX0, CC_C_TEX1, CC_C_PRIM, CC_C_SHADE, CC_C_ENV, CC_C_1, CC_C_NOISE, 0);
	// Color B:  Combined, Tex0, Tex1, Prim, Shade, Env, Chroma Key Center, 0  (8 options)
	const int CC_COLOR_B_TABLE[8] = int[](CC_C_COMB, CC_C_TEX0, CC_C_TEX1, CC_C_PRIM, CC_C_SHADE, CC_C_ENV, CC_C_CHROMA_KEY_CENTER, 0);
	// Color C:  Combined, Tex0, Tex1, Prim, Shade, Env, Chroma Key Scale, Comb Alpha,
	//           Tex0 Alpha, Tex1 Alpha, Prim Alpha, Shade Alpha, Env Alpha,
	//           LOD Frac, Prim LOD Frac, 0  (16 options)
	const int CC_COLOR_C_TABLE[16] = int[](CC_C_COMB, CC_C_TEX0, CC_C_TEX1, CC_C_PRIM, CC_C_SHADE, CC_C_ENV, CC_C_CHROMA_KEY_SCALE, CC_C_COMB_ALPHA, CC_C_TEX0_ALPHA, CC_C_TEX1_ALPHA, CC_C_PRIM_ALPHA, CC_C_SHADE_ALPHA, CC_C_ENV_ALPHA, CC_C_LOD_FRAC, CC_C_PRIM_LOD_FRAC, 0);
// Color D:  Combined, Tex0, Tex1, Prim, Shade, Env, 1, 0          (8 options)
const int CC_COLOR_D_TABLE[8] = int[](CC_C_COMB, CC_C_TEX0, CC_C_TEX1, CC_C_PRIM, CC_C_SHADE, CC_C_ENV, CC_C_1, 0);

// Alpha A/B/D: Comb Alpha, Tex0 Alpha, Tex1 Alpha, Prim Alpha, Shade Alpha, Env Alpha, 1, 0  (8 options)
const int CC_ALPHA_ABD_TABLE[8] = int[](CC_A_COMB, CC_A_TEX0, CC_A_TEX1, CC_A_PRIM, CC_A_SHADE, CC_A_ENV, CC_A_1, 0);
// Alpha C:  LOD Frac, Comb Alpha, Tex0 Alpha, Tex1 Alpha, Prim Alpha, Shade Alpha, Env Alpha, Prim LOD Frac, 0  (9 options)
const int CC_ALPHA_C_TABLE[9]  = int[](CC_A_LOD_FRAC, CC_A_COMB, CC_A_TEX0, CC_A_TEX1, CC_A_PRIM, CC_A_SHADE, CC_A_ENV, CC_A_PRIM_LOD_FRAC, 0);

int cc_color_a_from_ui(int idx) { return CC_COLOR_A_TABLE[clamp(idx, 0, 8)]; }
	int cc_color_b_from_ui(int idx) { return CC_COLOR_B_TABLE[clamp(idx, 0, 7)]; }
	int cc_color_c_from_ui(int idx) { return CC_COLOR_C_TABLE[clamp(idx, 0, 15)]; }
	int cc_color_d_from_ui(int idx) { return CC_COLOR_D_TABLE[clamp(idx, 0, 7)]; }
	int cc_alpha_abd_from_ui(int idx) { return CC_ALPHA_ABD_TABLE[clamp(idx, 0, 7)]; }
	int cc_alpha_c_from_ui(int idx)   { return CC_ALPHA_C_TABLE[clamp(idx, 0, 8)]; }

group_uniforms Texture0_Settings;
		/** Texture 0 source image. */
		uniform sampler2D Texture0 : source_color;
		/** Tex0 wrap mask in pixels (x,y). */
		uniform vec2 Texture0_Mask;
		/** Tex0 UV scale (tile rate). */
		uniform vec2 Texture0_Scale;
		/** Tex0 UV offset (pixel-space pan). */
		uniform vec2 Texture0_Offset;
		/** Clamp Tex0 on X (no wrapping). */
		uniform bool Texture0_ClampX;
		/** Clamp Tex0 on Y (no wrapping). */
		uniform bool Texture0_ClampY;
		/** Mirror Tex0 on X when wrapping. */
		uniform bool Texture0_MirrorX;
		/** Mirror Tex0 on Y when wrapping. */
		uniform bool Texture0_MirrorY;
		/** Tex0 UV scroll speed (pixels per second, x/y). */
		uniform vec2 Texture0_Scroll = vec2(0.0, 0.0);
group_uniforms;

group_uniforms Texture1_Settings;
		/** Texture 1 source image. */
		uniform sampler2D Texture1 : source_color;
		/** Tex1 wrap mask in pixels (x,y). */
		uniform vec2 Texture1_Mask;
		/** Tex1 UV scale (tile rate). */
		uniform vec2 Texture1_Scale;
		/** Tex1 UV offset (pixel-space pan). */
		uniform vec2 Texture1_Offset;
		/** Clamp Tex1 on X (no wrapping). */
		uniform bool Texture1_ClampX;
		/** Clamp Tex1 on Y (no wrapping). */
		uniform bool Texture1_ClampY;
		/** Mirror Tex1 on X when wrapping. */
		uniform bool Texture1_MirrorX;
		/** Mirror Tex1 on Y when wrapping. */
		uniform bool Texture1_MirrorY;
		/** Tex1 UV scroll speed (pixels per second, x/y). */
		uniform vec2 Texture1_Scroll = vec2(0.0, 0.0);
group_uniforms;

group_uniforms Cycle0_Combiner_Settings;
	// Cycle 0 color: (A, B, C, D)
	/** Cycle 0 color input A. */
	uniform int cc0_color_a : hint_enum("Combined,Tex0,Tex1,Prim,Shade,Env,1,Noise,0") = 1;
	/** Cycle 0 color input B. */
	uniform int cc0_color_b : hint_enum("Combined,Tex0,Tex1,Prim,Shade,Env,Chroma Key Center,0") = 7;
	/** Cycle 0 color input C. */
	uniform int cc0_color_c : hint_enum("Combined,Tex0,Tex1,Prim,Shade,Env,Chroma Key Scale,Comb Alpha,Tex0 Alpha,Tex1 Alpha,Prim Alpha,Shade Alpha,Env Alpha,LOD Frac,Prim LOD Frac,0") = 4;
	/** Cycle 0 color input D. */
	uniform int cc0_color_d : hint_enum("Combined,Tex0,Tex1,Prim,Shade,Env,1,0") = 7;

	// Cycle 0 alpha: (A, B, C, D)
	/** Cycle 0 alpha input A. */
	uniform int cc0_alpha_a : hint_enum("Comb Alpha,Tex0 Alpha,Tex1 Alpha,Prim Alpha,Shade Alpha,Env Alpha,1,0") = 7;
	/** Cycle 0 alpha input B. */
	uniform int cc0_alpha_b : hint_enum("Comb Alpha,Tex0 Alpha,Tex1 Alpha,Prim Alpha,Shade Alpha,Env Alpha,1,0") = 7;
	/** Cycle 0 alpha input C. */
	uniform int cc0_alpha_c : hint_enum("LOD Frac,Comb Alpha,Tex0 Alpha,Tex1 Alpha,Prim Alpha,Shade Alpha,Env Alpha,Prim LOD Frac,0") = 8;
	/** Cycle 0 alpha input D. */
	uniform int cc0_alpha_d : hint_enum("Comb Alpha,Tex0 Alpha,Tex1 Alpha,Prim Alpha,Shade Alpha,Env Alpha,1,0") = 5;
group_uniforms;

group_uniforms Cycle1_Combiner_Settings;
	// Cycle 1 color: (A, B, C, D)
	/** Cycle 1 color input A. */
	uniform int cc1_color_a : hint_enum("Combined,Tex0,Tex1,Prim,Shade,Env,1,Noise,0") = 1;
	/** Cycle 1 color input B. */
	uniform int cc1_color_b : hint_enum("Combined,Tex0,Tex1,Prim,Shade,Env,Chroma Key Center,0") = 7;
	/** Cycle 1 color input C. */
	uniform int cc1_color_c : hint_enum("Combined,Tex0,Tex1,Prim,Shade,Env,Chroma Key Scale,Comb Alpha,Tex0 Alpha,Tex1 Alpha,Prim Alpha,Shade Alpha,Env Alpha,LOD Frac,Prim LOD Frac,0") = 4;
	/** Cycle 1 color input D. */
	uniform int cc1_color_d : hint_enum("Combined,Tex0,Tex1,Prim,Shade,Env,1,0") = 7;

	// Cycle 1 alpha: (A, B, C, D)
	/** Cycle 1 alpha input A. */
	uniform int cc1_alpha_a : hint_enum("Comb Alpha,Tex0 Alpha,Tex1 Alpha,Prim Alpha,Shade Alpha,Env Alpha,1,0") = 7;
	/** Cycle 1 alpha input B. */
	uniform int cc1_alpha_b : hint_enum("Comb Alpha,Tex0 Alpha,Tex1 Alpha,Prim Alpha,Shade Alpha,Env Alpha,1,0") = 7;
	/** Cycle 1 alpha input C. */
	uniform int cc1_alpha_c : hint_enum("LOD Frac,Comb Alpha,Tex0 Alpha,Tex1 Alpha,Prim Alpha,Shade Alpha,Env Alpha,Prim LOD Frac,0") = 8;
	/** Cycle 1 alpha input D. */
	uniform int cc1_alpha_d : hint_enum("Comb Alpha,Tex0 Alpha,Tex1 Alpha,Prim Alpha,Shade Alpha,Env Alpha,1,0") = 5;
group_uniforms;

group_uniforms Material_Colors;
	/** Primitive color constant (R). Allows values <0 or >1. */
	uniform float material_prim_r = 1.0;
	/** Primitive color constant (G). Allows values <0 or >1. */
	uniform float material_prim_g = 1.0;
	/** Primitive color constant (B). Allows values <0 or >1. */
	uniform float material_prim_b = 1.0;
	/** Primitive color constant (A). Allows values <0 or >1. */
	uniform float material_prim_a = 1.0;

	/** Environment color constant (R). Allows values <0 or >1. */
	uniform float material_env_r = 1.0;
	/** Environment color constant (G). Allows values <0 or >1. */
	uniform float material_env_g = 1.0;
	/** Environment color constant (B). Allows values <0 or >1. */
	uniform float material_env_b = 1.0;
	/** Environment color constant (A). Allows values <0 or >1. */
	uniform float material_env_a = 1.0;
group_uniforms;

group_uniforms Extra_Inputs;
	/** Chroma key center color (RGB). Used as Color B input "Chroma Key Center". */
	uniform vec3 chroma_key_center = vec3(0.0);
	/** Chroma key scale factor (RGB). Used as Color C input "Chroma Key Scale". */
	uniform vec3 chroma_key_scale = vec3(0.0);
	/** Primitive LOD fraction (0–1). Used as Color C / Alpha C input "Prim LOD Frac".
	  * Set manually to control mip blend without relying on screen-space derivatives. */
	uniform float prim_lod_frac : hint_range(0.0, 1.0) = 0.0;
	/** Minimum LOD contribution used by the combiner's LOD path. */
	uniform float prim_lod_min : hint_range(0.0, 1.0) = 0.0;
	/** Number of mip levels assumed by the LOD approximation. */
	uniform int mip_count : hint_range(1, 8) = 1;
group_uniforms;

group_uniforms Alpha_Settings;
	/** Alpha cutout threshold (discard below). */
	uniform float alpha_clip : hint_range(0.0, 1.0) = 0.0;
group_uniforms;

group_uniforms Atlas_Settings;
	/** Size of Tex0 sub-region in the atlas (pixels). 0 = use full texture. */
	uniform ivec2 atlas_region_0 = ivec2(0, 0);
	/** Top-left corner of Tex0 sub-region in the atlas (pixels). */
	uniform ivec2 atlas_offset_0 = ivec2(0, 0);
	/** Size of Tex1 sub-region in the atlas (pixels). 0 = use full texture. */
	uniform ivec2 atlas_region_1 = ivec2(0, 0);
	/** Top-left corner of Tex1 sub-region in the atlas (pixels). */
	uniform ivec2 atlas_offset_1 = ivec2(0, 0);
	/** Texels to inset from region edges to prevent atlas bleeding. 0 = no inset. */
	uniform int atlas_seam_hiding = 0;
	/** Fractional UV inset per tile (like SEEM_HIDING). Slightly zooms into each
	  * tile to avoid sampling at the very edge. Typical value: 0.007 (1/128). */
	uniform float atlas_seam_zoom : hint_range(0.0, 0.1) = 0.0;
group_uniforms;

// Geometry mode bits
const int G_TEX_GEN      = (1 << 14);

// Other mode H bits (subset)
const int G_MDSFT_CYCLETYPE = 20;
const int G_CYC_2CYCLE      = (1 << G_MDSFT_CYCLETYPE);

// Draw flags (subset)
const int DRAW_FLAG_TEX0_MONO = (1 << 1);
const int DRAW_FLAG_TEX1_MONO = (1 << 2);
const int DRAW_FLAG_TEX0_4BIT = (1 << 5);
const int DRAW_FLAG_TEX1_4BIT = (1 << 6);
const int DRAW_FLAG_TEX0_3BIT = (1 << 7);
const int DRAW_FLAG_TEX1_3BIT = (1 << 8);

group_uniforms Mode_Toggles;
	// Geometry
	/** Generate UVs from normals (env/chrome mapping). */
	uniform bool use_tex_gen = false;

	// Other mode H
	/** Texture filtering mode. */
	uniform int filter_mode : hint_enum("Nearest,3-Point,Bilinear") = 1;
	/** Enable 2-cycle combiner. */
	uniform bool use_two_cycle = false;
	/** Enable the reference-style texture LOD path. */
	uniform bool use_texture_lod = false;
	/** Texture detail behavior. */
	uniform int texture_detail_mode : hint_enum("Clamp,Sharpen,Detail") = 0;

	// Draw flags
	/** Force Tex0 to grayscale (R channel). */
	uniform bool tex0_mono = false;
	/** Force Tex1 to grayscale (R channel). */
	uniform bool tex1_mono = false;
	/** Quantize Tex0 colors. */
	uniform int tex0_quantize : hint_enum("None,4-bit,3-bit") = 0;
	/** Quantize Tex1 colors. */
	uniform int tex1_quantize : hint_enum("None,4-bit,3-bit") = 0;
group_uniforms;

group_uniforms Range_Control;
	/** Clamp incoming SHADE to 0..1 before the combiner. */
	uniform bool clamp_shade_input = false;
	/** Clamp the final combiner output to 0..1 after overflow handling. */
	uniform bool clamp_combiner_output = false;
group_uniforms;

int build_geo_mode()
{
	return (use_tex_gen ? G_TEX_GEN : 0)
		;
}

int build_other_mode_h()
{
	return (use_two_cycle ? G_CYC_2CYCLE : 0);
}

int build_draw_flags()
{
	int flags = 0;
	flags |= (tex0_mono ? DRAW_FLAG_TEX0_MONO : 0);
	flags |= (tex1_mono ? DRAW_FLAG_TEX1_MONO : 0);
	flags |= (tex0_quantize == 1 ? DRAW_FLAG_TEX0_4BIT : 0);
	flags |= (tex0_quantize == 2 ? DRAW_FLAG_TEX0_3BIT : 0);
	flags |= (tex1_quantize == 1 ? DRAW_FLAG_TEX1_4BIT : 0);
	flags |= (tex1_quantize == 2 ? DRAW_FLAG_TEX1_3BIT : 0);
	return flags;
}

// --------------------------------------------------------------------
// Varyings
// --------------------------------------------------------------------
varying vec4 cc_shade;
varying float cc_shade_from_vertex_color;
varying vec4 uv;       // xy = tex0, zw = tex1 (pixel space)
varying vec4 tileSize; // per-tile size in pixels

struct N64CombVertexData {
	vec4 cc_shade;
	float cc_shade_from_vertex_color;
	vec4 uv;
	vec4 tileSize;
};

// --------------------------------------------------------------------
// Material vector builders (from UI fields)
// --------------------------------------------------------------------
vec4 build_material_mask()
{
	vec2 sign0 = vec2(Texture0_ClampX ? -1.0 : 1.0, Texture0_ClampY ? -1.0 : 1.0);
	vec2 sign1 = vec2(Texture1_ClampX ? -1.0 : 1.0, Texture1_ClampY ? -1.0 : 1.0);
	return vec4(Texture0_Mask * sign0, Texture1_Mask * sign1);
}

vec4 build_material_shift()
{
	return vec4(Texture0_Scale, Texture1_Scale);
}

vec4 build_material_low()
{
	return vec4(Texture0_Offset, Texture1_Offset);
}

vec4 build_material_high()
{
	vec2 sign0 = vec2(Texture0_MirrorX ? -1.0 : 1.0, Texture0_MirrorY ? -1.0 : 1.0);
	vec2 sign1 = vec2(Texture1_MirrorX ? -1.0 : 1.0, Texture1_MirrorY ? -1.0 : 1.0);
	return vec4(Texture0_Mask * sign0, Texture1_Mask * sign1);
}

vec4 build_material_prim_color()
{
	return vec4(material_prim_r, material_prim_g, material_prim_b, material_prim_a);
}

vec4 build_material_env_color()
{
	return vec4(material_env_r, material_env_g, material_env_b, material_env_a);
}

// --------------------------------------------------------------------
// Utils
// --------------------------------------------------------------------

vec3 gammaToLinear(in vec3 color)
{
	return mix(
		color * (1.0 / 12.92),
		pow((color + 0.055) * (1.0 / 1.055), vec3(2.4)),
		step(vec3(0.04045), color)
	);
}

vec3 linearToGamma(in vec3 color)
{
	vec3 safe = max(color, vec3(0.0));
	return mix(
		safe * 12.92,
		1.055 * pow(safe, vec3(1.0 / 2.4)) - 0.055,
		step(vec3(0.0031308), safe)
	);
}

float noise(in vec2 coords)
{
	return fract(sin(dot(coords, vec2(12.9898, 78.233))) * 43758.5453);
}

vec4 fromLinearCompatibility(vec4 linear_rgb)
{
	bvec3 cutoff = lessThan(linear_rgb.rgb, vec3(0.0031308));
	vec3 higher = vec3(1.055) * pow(max(linear_rgb.rgb, vec3(0.0)), vec3(1.0 / 2.4)) - vec3(0.055);
	vec3 lower = linear_rgb.rgb * vec3(12.92);
	return vec4(mix(higher, lower, cutoff), linear_rgb.a);
}

vec4 mirrorUV(vec4 uvEnd, vec4 uvIn)
{
	vec4 uvMod2 = mod(uvIn, uvEnd * 2.0 + 1.0);
	return mix(uvMod2, (uvEnd * 2.0) - uvMod2, step(uvEnd, uvMod2));
}

ivec4 wrappedMirror(ivec4 texSize, ivec4 uvIn, vec4 material_mask, vec4 material_high, vec4 tile_size)
{
	vec4 mask = abs(material_mask);

	vec4 isClamp      = step(material_mask, vec4(1.0));
	vec4 isMirror     = step(material_high, vec4(0.0));
	vec4 isForceClamp = step(mask, vec4(1.0));
	mask = mix(mask, vec4(256.0), isForceClamp);

	vec4 tc = vec4(uvIn);
	tc.yw = vec2(texSize.yw) - tc.yw;

	vec4 uvClamp = clamp(tc, vec4(0.0), tile_size);
	tc = mix(tc, uvClamp, isClamp);

	vec4 uvMirror = mirrorUV(mask - vec4(0.5), tc);
	tc = mix(tc, uvMirror, isMirror);

	tc = mod(tc, min(vec4(texSize + 1), mask));
	tc.yw = vec2(texSize.yw) - tc.yw;
	return ivec4(tc);
}

// Merged wrap: builds material_mask and material_high once, returns both
// tex A (xy) and tex B (zw) coords in a single call to avoid redundant
// uniform reads when both textures are sampled in the same filter pass.
ivec4 wrap_texel_ab(ivec2 coord_a, ivec2 size_a, ivec2 coord_b, ivec2 size_b)
{
	vec4 material_mask = build_material_mask();
	vec4 material_high = build_material_high();
	// Use atlas region sizes when set, otherwise full texture sizes.
	ivec2 eff_a = atlas_region_0.x > 0 ? atlas_region_0 : size_a;
	ivec2 eff_b = atlas_region_1.x > 0 ? atlas_region_1 : size_b;
	ivec4 wrapped = wrappedMirror(ivec4(eff_a, eff_b) - 1, ivec4(coord_a, coord_b), material_mask, material_high, tileSize);
	// Clamp to valid region range. With atlas_seam_hiding > 0, inset from edges
	// to prevent bleeding from adjacent atlas tiles.
	wrapped = clamp(wrapped, ivec4(atlas_seam_hiding), ivec4(eff_a - 1 - atlas_seam_hiding, eff_b - 1 - atlas_seam_hiding));
	// Offset into atlas after wrapping.
	return wrapped + ivec4(atlas_offset_0, atlas_offset_1);
}

ivec2 wrap_texel_a(ivec2 coord, ivec2 size)
{
	return wrap_texel_ab(coord, size, ivec2(0), ivec2(1)).xy;
}

ivec2 wrap_texel_b(ivec2 coord, ivec2 size)
{
	return wrap_texel_ab(ivec2(0), ivec2(1), coord, size).zw;
}

// Texture filter include (build 3 variants per texture).
#define TF_UV_IS_PIXEL

#define TF_SAMPLE_NAME sample_texA_nearest
#define TF_WRAP_TEXEL(coord, size) wrap_texel_a(coord, size)
#define FILTER_NONE
#ifndef TEXTUREFILTER_UTILS_INCLUDED
#define TEXTUREFILTER_UTILS_INCLUDED

#ifndef TF_GET_TEX_SIZE
#define TF_GET_TEX_SIZE(tex) textureSize(tex, 0)
#endif

#ifndef TF_WRAP_TEXEL
ivec2 tf_wrap_texel(ivec2 coord, ivec2 size) {
    return ivec2(
        (coord.x % size.x + size.x) % size.x,
        (coord.y % size.y + size.y) % size.y
    );
}
#define TF_WRAP_TEXEL(coord, size) tf_wrap_texel(coord, size)
#endif

#endif // TEXTUREFILTER_UTILS_INCLUDED

#ifndef TF_SAMPLE_NAME
#define TF_SAMPLE_NAME sample_filter
#endif

#ifdef TF_PIXEL_COORD
#undef TF_PIXEL_COORD
#endif
#ifdef TF_UV_IS_PIXEL
#define TF_PIXEL_COORD(uv, size) ((uv) - 0.5)
#else
#define TF_PIXEL_COORD(uv, size) ((uv) * vec2(size) - 0.5)
#endif

#ifdef FILTER_NONE
vec4 TF_SAMPLE_NAME(sampler2D tex, vec2 uv_in) {
    ivec2 texture_size = TF_GET_TEX_SIZE(tex);
    vec2 pixel_coord_float = TF_PIXEL_COORD(uv_in, texture_size);
    ivec2 texel_coord = ivec2(floor(pixel_coord_float + 0.5));
    return texelFetch(tex, TF_WRAP_TEXEL(texel_coord, texture_size), 0);
}
#endif

#ifdef FILTER_3POINT
vec4 TF_SAMPLE_NAME(sampler2D tex, vec2 uv_in) {
    ivec2 texture_size = TF_GET_TEX_SIZE(tex);
    vec2 pixel_coord_float = TF_PIXEL_COORD(uv_in, texture_size);
    
    ivec2 texel_coord = ivec2(floor(pixel_coord_float));
    vec2 frag_coord = fract(pixel_coord_float);
    
    vec4 t0 = texelFetch(tex, TF_WRAP_TEXEL(texel_coord, texture_size), 0);
    vec4 t1 = texelFetch(tex, TF_WRAP_TEXEL(texel_coord + ivec2(1, 0), texture_size), 0);
    vec4 t2 = texelFetch(tex, TF_WRAP_TEXEL(texel_coord + ivec2(0, 1), texture_size), 0);
    vec4 t3 = texelFetch(tex, TF_WRAP_TEXEL(texel_coord + ivec2(1, 1), texture_size), 0);

    if (frag_coord.x + frag_coord.y < 1.0) {
        return t0 + (t1 - t0) * frag_coord.x + (t2 - t0) * frag_coord.y;
    } else {
        vec2 weights = vec2(1.0 - frag_coord.x, 1.0 - frag_coord.y);
        return t3 + (t2 - t3) * weights.x + (t1 - t3) * weights.y;
    }
}
#endif

#ifdef FILTER_BOX
vec4 TF_SAMPLE_NAME(sampler2D tex, vec2 uv_in) {
    ivec2 texture_size = TF_GET_TEX_SIZE(tex);
    vec2 pixel_coord = TF_PIXEL_COORD(uv_in, texture_size);
    
    ivec2 texel_coord = ivec2(floor(pixel_coord));
    vec2 f = fract(pixel_coord);
    
    vec4 t0 = texelFetch(tex, TF_WRAP_TEXEL(texel_coord, texture_size), 0);
    vec4 t1 = texelFetch(tex, TF_WRAP_TEXEL(texel_coord + ivec2(1, 0), texture_size), 0);
    vec4 t2 = texelFetch(tex, TF_WRAP_TEXEL(texel_coord + ivec2(0, 1), texture_size), 0);
    vec4 t3 = texelFetch(tex, TF_WRAP_TEXEL(texel_coord + ivec2(1, 1), texture_size), 0);
    
    return mix(mix(t0, t1, f.x), mix(t2, t3, f.x), f.y);
}
#endif
#undef FILTER_NONE
#undef TF_WRAP_TEXEL
#undef TF_SAMPLE_NAME

#define TF_SAMPLE_NAME sample_texA_3point
#define TF_WRAP_TEXEL(coord, size) wrap_texel_a(coord, size)
#define FILTER_3POINT
#ifndef TEXTUREFILTER_UTILS_INCLUDED
#define TEXTUREFILTER_UTILS_INCLUDED

#ifndef TF_GET_TEX_SIZE
#define TF_GET_TEX_SIZE(tex) textureSize(tex, 0)
#endif

#ifndef TF_WRAP_TEXEL
ivec2 tf_wrap_texel(ivec2 coord, ivec2 size) {
    return ivec2(
        (coord.x % size.x + size.x) % size.x,
        (coord.y % size.y + size.y) % size.y
    );
}
#define TF_WRAP_TEXEL(coord, size) tf_wrap_texel(coord, size)
#endif

#endif // TEXTUREFILTER_UTILS_INCLUDED

#ifndef TF_SAMPLE_NAME
#define TF_SAMPLE_NAME sample_filter
#endif

#ifdef TF_PIXEL_COORD
#undef TF_PIXEL_COORD
#endif
#ifdef TF_UV_IS_PIXEL
#define TF_PIXEL_COORD(uv, size) ((uv) - 0.5)
#else
#define TF_PIXEL_COORD(uv, size) ((uv) * vec2(size) - 0.5)
#endif

#ifdef FILTER_NONE
vec4 TF_SAMPLE_NAME(sampler2D tex, vec2 uv_in) {
    ivec2 texture_size = TF_GET_TEX_SIZE(tex);
    vec2 pixel_coord_float = TF_PIXEL_COORD(uv_in, texture_size);
    ivec2 texel_coord = ivec2(floor(pixel_coord_float + 0.5));
    return texelFetch(tex, TF_WRAP_TEXEL(texel_coord, texture_size), 0);
}
#endif

#ifdef FILTER_3POINT
vec4 TF_SAMPLE_NAME(sampler2D tex, vec2 uv_in) {
    ivec2 texture_size = TF_GET_TEX_SIZE(tex);
    vec2 pixel_coord_float = TF_PIXEL_COORD(uv_in, texture_size);
    
    ivec2 texel_coord = ivec2(floor(pixel_coord_float));
    vec2 frag_coord = fract(pixel_coord_float);
    
    vec4 t0 = texelFetch(tex, TF_WRAP_TEXEL(texel_coord, texture_size), 0);
    vec4 t1 = texelFetch(tex, TF_WRAP_TEXEL(texel_coord + ivec2(1, 0), texture_size), 0);
    vec4 t2 = texelFetch(tex, TF_WRAP_TEXEL(texel_coord + ivec2(0, 1), texture_size), 0);
    vec4 t3 = texelFetch(tex, TF_WRAP_TEXEL(texel_coord + ivec2(1, 1), texture_size), 0);

    if (frag_coord.x + frag_coord.y < 1.0) {
        return t0 + (t1 - t0) * frag_coord.x + (t2 - t0) * frag_coord.y;
    } else {
        vec2 weights = vec2(1.0 - frag_coord.x, 1.0 - frag_coord.y);
        return t3 + (t2 - t3) * weights.x + (t1 - t3) * weights.y;
    }
}
#endif

#ifdef FILTER_BOX
vec4 TF_SAMPLE_NAME(sampler2D tex, vec2 uv_in) {
    ivec2 texture_size = TF_GET_TEX_SIZE(tex);
    vec2 pixel_coord = TF_PIXEL_COORD(uv_in, texture_size);
    
    ivec2 texel_coord = ivec2(floor(pixel_coord));
    vec2 f = fract(pixel_coord);
    
    vec4 t0 = texelFetch(tex, TF_WRAP_TEXEL(texel_coord, texture_size), 0);
    vec4 t1 = texelFetch(tex, TF_WRAP_TEXEL(texel_coord + ivec2(1, 0), texture_size), 0);
    vec4 t2 = texelFetch(tex, TF_WRAP_TEXEL(texel_coord + ivec2(0, 1), texture_size), 0);
    vec4 t3 = texelFetch(tex, TF_WRAP_TEXEL(texel_coord + ivec2(1, 1), texture_size), 0);
    
    return mix(mix(t0, t1, f.x), mix(t2, t3, f.x), f.y);
}
#endif
#undef FILTER_3POINT
#undef TF_WRAP_TEXEL
#undef TF_SAMPLE_NAME

#define TF_SAMPLE_NAME sample_texA_bilinear
#define TF_WRAP_TEXEL(coord, size) wrap_texel_a(coord, size)
#define FILTER_BOX
#ifndef TEXTUREFILTER_UTILS_INCLUDED
#define TEXTUREFILTER_UTILS_INCLUDED

#ifndef TF_GET_TEX_SIZE
#define TF_GET_TEX_SIZE(tex) textureSize(tex, 0)
#endif

#ifndef TF_WRAP_TEXEL
ivec2 tf_wrap_texel(ivec2 coord, ivec2 size) {
    return ivec2(
        (coord.x % size.x + size.x) % size.x,
        (coord.y % size.y + size.y) % size.y
    );
}
#define TF_WRAP_TEXEL(coord, size) tf_wrap_texel(coord, size)
#endif

#endif // TEXTUREFILTER_UTILS_INCLUDED

#ifndef TF_SAMPLE_NAME
#define TF_SAMPLE_NAME sample_filter
#endif

#ifdef TF_PIXEL_COORD
#undef TF_PIXEL_COORD
#endif
#ifdef TF_UV_IS_PIXEL
#define TF_PIXEL_COORD(uv, size) ((uv) - 0.5)
#else
#define TF_PIXEL_COORD(uv, size) ((uv) * vec2(size) - 0.5)
#endif

#ifdef FILTER_NONE
vec4 TF_SAMPLE_NAME(sampler2D tex, vec2 uv_in) {
    ivec2 texture_size = TF_GET_TEX_SIZE(tex);
    vec2 pixel_coord_float = TF_PIXEL_COORD(uv_in, texture_size);
    ivec2 texel_coord = ivec2(floor(pixel_coord_float + 0.5));
    return texelFetch(tex, TF_WRAP_TEXEL(texel_coord, texture_size), 0);
}
#endif

#ifdef FILTER_3POINT
vec4 TF_SAMPLE_NAME(sampler2D tex, vec2 uv_in) {
    ivec2 texture_size = TF_GET_TEX_SIZE(tex);
    vec2 pixel_coord_float = TF_PIXEL_COORD(uv_in, texture_size);
    
    ivec2 texel_coord = ivec2(floor(pixel_coord_float));
    vec2 frag_coord = fract(pixel_coord_float);
    
    vec4 t0 = texelFetch(tex, TF_WRAP_TEXEL(texel_coord, texture_size), 0);
    vec4 t1 = texelFetch(tex, TF_WRAP_TEXEL(texel_coord + ivec2(1, 0), texture_size), 0);
    vec4 t2 = texelFetch(tex, TF_WRAP_TEXEL(texel_coord + ivec2(0, 1), texture_size), 0);
    vec4 t3 = texelFetch(tex, TF_WRAP_TEXEL(texel_coord + ivec2(1, 1), texture_size), 0);

    if (frag_coord.x + frag_coord.y < 1.0) {
        return t0 + (t1 - t0) * frag_coord.x + (t2 - t0) * frag_coord.y;
    } else {
        vec2 weights = vec2(1.0 - frag_coord.x, 1.0 - frag_coord.y);
        return t3 + (t2 - t3) * weights.x + (t1 - t3) * weights.y;
    }
}
#endif

#ifdef FILTER_BOX
vec4 TF_SAMPLE_NAME(sampler2D tex, vec2 uv_in) {
    ivec2 texture_size = TF_GET_TEX_SIZE(tex);
    vec2 pixel_coord = TF_PIXEL_COORD(uv_in, texture_size);
    
    ivec2 texel_coord = ivec2(floor(pixel_coord));
    vec2 f = fract(pixel_coord);
    
    vec4 t0 = texelFetch(tex, TF_WRAP_TEXEL(texel_coord, texture_size), 0);
    vec4 t1 = texelFetch(tex, TF_WRAP_TEXEL(texel_coord + ivec2(1, 0), texture_size), 0);
    vec4 t2 = texelFetch(tex, TF_WRAP_TEXEL(texel_coord + ivec2(0, 1), texture_size), 0);
    vec4 t3 = texelFetch(tex, TF_WRAP_TEXEL(texel_coord + ivec2(1, 1), texture_size), 0);
    
    return mix(mix(t0, t1, f.x), mix(t2, t3, f.x), f.y);
}
#endif
#undef FILTER_BOX
#undef TF_WRAP_TEXEL
#undef TF_SAMPLE_NAME

#define TF_SAMPLE_NAME sample_texB_nearest
#define TF_WRAP_TEXEL(coord, size) wrap_texel_b(coord, size)
#define FILTER_NONE
#ifndef TEXTUREFILTER_UTILS_INCLUDED
#define TEXTUREFILTER_UTILS_INCLUDED

#ifndef TF_GET_TEX_SIZE
#define TF_GET_TEX_SIZE(tex) textureSize(tex, 0)
#endif

#ifndef TF_WRAP_TEXEL
ivec2 tf_wrap_texel(ivec2 coord, ivec2 size) {
    return ivec2(
        (coord.x % size.x + size.x) % size.x,
        (coord.y % size.y + size.y) % size.y
    );
}
#define TF_WRAP_TEXEL(coord, size) tf_wrap_texel(coord, size)
#endif

#endif // TEXTUREFILTER_UTILS_INCLUDED

#ifndef TF_SAMPLE_NAME
#define TF_SAMPLE_NAME sample_filter
#endif

#ifdef TF_PIXEL_COORD
#undef TF_PIXEL_COORD
#endif
#ifdef TF_UV_IS_PIXEL
#define TF_PIXEL_COORD(uv, size) ((uv) - 0.5)
#else
#define TF_PIXEL_COORD(uv, size) ((uv) * vec2(size) - 0.5)
#endif

#ifdef FILTER_NONE
vec4 TF_SAMPLE_NAME(sampler2D tex, vec2 uv_in) {
    ivec2 texture_size = TF_GET_TEX_SIZE(tex);
    vec2 pixel_coord_float = TF_PIXEL_COORD(uv_in, texture_size);
    ivec2 texel_coord = ivec2(floor(pixel_coord_float + 0.5));
    return texelFetch(tex, TF_WRAP_TEXEL(texel_coord, texture_size), 0);
}
#endif

#ifdef FILTER_3POINT
vec4 TF_SAMPLE_NAME(sampler2D tex, vec2 uv_in) {
    ivec2 texture_size = TF_GET_TEX_SIZE(tex);
    vec2 pixel_coord_float = TF_PIXEL_COORD(uv_in, texture_size);
    
    ivec2 texel_coord = ivec2(floor(pixel_coord_float));
    vec2 frag_coord = fract(pixel_coord_float);
    
    vec4 t0 = texelFetch(tex, TF_WRAP_TEXEL(texel_coord, texture_size), 0);
    vec4 t1 = texelFetch(tex, TF_WRAP_TEXEL(texel_coord + ivec2(1, 0), texture_size), 0);
    vec4 t2 = texelFetch(tex, TF_WRAP_TEXEL(texel_coord + ivec2(0, 1), texture_size), 0);
    vec4 t3 = texelFetch(tex, TF_WRAP_TEXEL(texel_coord + ivec2(1, 1), texture_size), 0);

    if (frag_coord.x + frag_coord.y < 1.0) {
        return t0 + (t1 - t0) * frag_coord.x + (t2 - t0) * frag_coord.y;
    } else {
        vec2 weights = vec2(1.0 - frag_coord.x, 1.0 - frag_coord.y);
        return t3 + (t2 - t3) * weights.x + (t1 - t3) * weights.y;
    }
}
#endif

#ifdef FILTER_BOX
vec4 TF_SAMPLE_NAME(sampler2D tex, vec2 uv_in) {
    ivec2 texture_size = TF_GET_TEX_SIZE(tex);
    vec2 pixel_coord = TF_PIXEL_COORD(uv_in, texture_size);
    
    ivec2 texel_coord = ivec2(floor(pixel_coord));
    vec2 f = fract(pixel_coord);
    
    vec4 t0 = texelFetch(tex, TF_WRAP_TEXEL(texel_coord, texture_size), 0);
    vec4 t1 = texelFetch(tex, TF_WRAP_TEXEL(texel_coord + ivec2(1, 0), texture_size), 0);
    vec4 t2 = texelFetch(tex, TF_WRAP_TEXEL(texel_coord + ivec2(0, 1), texture_size), 0);
    vec4 t3 = texelFetch(tex, TF_WRAP_TEXEL(texel_coord + ivec2(1, 1), texture_size), 0);
    
    return mix(mix(t0, t1, f.x), mix(t2, t3, f.x), f.y);
}
#endif
#undef FILTER_NONE
#undef TF_WRAP_TEXEL
#undef TF_SAMPLE_NAME

#define TF_SAMPLE_NAME sample_texB_3point
#define TF_WRAP_TEXEL(coord, size) wrap_texel_b(coord, size)
#define FILTER_3POINT
#ifndef TEXTUREFILTER_UTILS_INCLUDED
#define TEXTUREFILTER_UTILS_INCLUDED

#ifndef TF_GET_TEX_SIZE
#define TF_GET_TEX_SIZE(tex) textureSize(tex, 0)
#endif

#ifndef TF_WRAP_TEXEL
ivec2 tf_wrap_texel(ivec2 coord, ivec2 size) {
    return ivec2(
        (coord.x % size.x + size.x) % size.x,
        (coord.y % size.y + size.y) % size.y
    );
}
#define TF_WRAP_TEXEL(coord, size) tf_wrap_texel(coord, size)
#endif

#endif // TEXTUREFILTER_UTILS_INCLUDED

#ifndef TF_SAMPLE_NAME
#define TF_SAMPLE_NAME sample_filter
#endif

#ifdef TF_PIXEL_COORD
#undef TF_PIXEL_COORD
#endif
#ifdef TF_UV_IS_PIXEL
#define TF_PIXEL_COORD(uv, size) ((uv) - 0.5)
#else
#define TF_PIXEL_COORD(uv, size) ((uv) * vec2(size) - 0.5)
#endif

#ifdef FILTER_NONE
vec4 TF_SAMPLE_NAME(sampler2D tex, vec2 uv_in) {
    ivec2 texture_size = TF_GET_TEX_SIZE(tex);
    vec2 pixel_coord_float = TF_PIXEL_COORD(uv_in, texture_size);
    ivec2 texel_coord = ivec2(floor(pixel_coord_float + 0.5));
    return texelFetch(tex, TF_WRAP_TEXEL(texel_coord, texture_size), 0);
}
#endif

#ifdef FILTER_3POINT
vec4 TF_SAMPLE_NAME(sampler2D tex, vec2 uv_in) {
    ivec2 texture_size = TF_GET_TEX_SIZE(tex);
    vec2 pixel_coord_float = TF_PIXEL_COORD(uv_in, texture_size);
    
    ivec2 texel_coord = ivec2(floor(pixel_coord_float));
    vec2 frag_coord = fract(pixel_coord_float);
    
    vec4 t0 = texelFetch(tex, TF_WRAP_TEXEL(texel_coord, texture_size), 0);
    vec4 t1 = texelFetch(tex, TF_WRAP_TEXEL(texel_coord + ivec2(1, 0), texture_size), 0);
    vec4 t2 = texelFetch(tex, TF_WRAP_TEXEL(texel_coord + ivec2(0, 1), texture_size), 0);
    vec4 t3 = texelFetch(tex, TF_WRAP_TEXEL(texel_coord + ivec2(1, 1), texture_size), 0);

    if (frag_coord.x + frag_coord.y < 1.0) {
        return t0 + (t1 - t0) * frag_coord.x + (t2 - t0) * frag_coord.y;
    } else {
        vec2 weights = vec2(1.0 - frag_coord.x, 1.0 - frag_coord.y);
        return t3 + (t2 - t3) * weights.x + (t1 - t3) * weights.y;
    }
}
#endif

#ifdef FILTER_BOX
vec4 TF_SAMPLE_NAME(sampler2D tex, vec2 uv_in) {
    ivec2 texture_size = TF_GET_TEX_SIZE(tex);
    vec2 pixel_coord = TF_PIXEL_COORD(uv_in, texture_size);
    
    ivec2 texel_coord = ivec2(floor(pixel_coord));
    vec2 f = fract(pixel_coord);
    
    vec4 t0 = texelFetch(tex, TF_WRAP_TEXEL(texel_coord, texture_size), 0);
    vec4 t1 = texelFetch(tex, TF_WRAP_TEXEL(texel_coord + ivec2(1, 0), texture_size), 0);
    vec4 t2 = texelFetch(tex, TF_WRAP_TEXEL(texel_coord + ivec2(0, 1), texture_size), 0);
    vec4 t3 = texelFetch(tex, TF_WRAP_TEXEL(texel_coord + ivec2(1, 1), texture_size), 0);
    
    return mix(mix(t0, t1, f.x), mix(t2, t3, f.x), f.y);
}
#endif
#undef FILTER_3POINT
#undef TF_WRAP_TEXEL
#undef TF_SAMPLE_NAME

#define TF_SAMPLE_NAME sample_texB_bilinear
#define TF_WRAP_TEXEL(coord, size) wrap_texel_b(coord, size)
#define FILTER_BOX
#ifndef TEXTUREFILTER_UTILS_INCLUDED
#define TEXTUREFILTER_UTILS_INCLUDED

#ifndef TF_GET_TEX_SIZE
#define TF_GET_TEX_SIZE(tex) textureSize(tex, 0)
#endif

#ifndef TF_WRAP_TEXEL
ivec2 tf_wrap_texel(ivec2 coord, ivec2 size) {
    return ivec2(
        (coord.x % size.x + size.x) % size.x,
        (coord.y % size.y + size.y) % size.y
    );
}
#define TF_WRAP_TEXEL(coord, size) tf_wrap_texel(coord, size)
#endif

#endif // TEXTUREFILTER_UTILS_INCLUDED

#ifndef TF_SAMPLE_NAME
#define TF_SAMPLE_NAME sample_filter
#endif

#ifdef TF_PIXEL_COORD
#undef TF_PIXEL_COORD
#endif
#ifdef TF_UV_IS_PIXEL
#define TF_PIXEL_COORD(uv, size) ((uv) - 0.5)
#else
#define TF_PIXEL_COORD(uv, size) ((uv) * vec2(size) - 0.5)
#endif

#ifdef FILTER_NONE
vec4 TF_SAMPLE_NAME(sampler2D tex, vec2 uv_in) {
    ivec2 texture_size = TF_GET_TEX_SIZE(tex);
    vec2 pixel_coord_float = TF_PIXEL_COORD(uv_in, texture_size);
    ivec2 texel_coord = ivec2(floor(pixel_coord_float + 0.5));
    return texelFetch(tex, TF_WRAP_TEXEL(texel_coord, texture_size), 0);
}
#endif

#ifdef FILTER_3POINT
vec4 TF_SAMPLE_NAME(sampler2D tex, vec2 uv_in) {
    ivec2 texture_size = TF_GET_TEX_SIZE(tex);
    vec2 pixel_coord_float = TF_PIXEL_COORD(uv_in, texture_size);
    
    ivec2 texel_coord = ivec2(floor(pixel_coord_float));
    vec2 frag_coord = fract(pixel_coord_float);
    
    vec4 t0 = texelFetch(tex, TF_WRAP_TEXEL(texel_coord, texture_size), 0);
    vec4 t1 = texelFetch(tex, TF_WRAP_TEXEL(texel_coord + ivec2(1, 0), texture_size), 0);
    vec4 t2 = texelFetch(tex, TF_WRAP_TEXEL(texel_coord + ivec2(0, 1), texture_size), 0);
    vec4 t3 = texelFetch(tex, TF_WRAP_TEXEL(texel_coord + ivec2(1, 1), texture_size), 0);

    if (frag_coord.x + frag_coord.y < 1.0) {
        return t0 + (t1 - t0) * frag_coord.x + (t2 - t0) * frag_coord.y;
    } else {
        vec2 weights = vec2(1.0 - frag_coord.x, 1.0 - frag_coord.y);
        return t3 + (t2 - t3) * weights.x + (t1 - t3) * weights.y;
    }
}
#endif

#ifdef FILTER_BOX
vec4 TF_SAMPLE_NAME(sampler2D tex, vec2 uv_in) {
    ivec2 texture_size = TF_GET_TEX_SIZE(tex);
    vec2 pixel_coord = TF_PIXEL_COORD(uv_in, texture_size);
    
    ivec2 texel_coord = ivec2(floor(pixel_coord));
    vec2 f = fract(pixel_coord);
    
    vec4 t0 = texelFetch(tex, TF_WRAP_TEXEL(texel_coord, texture_size), 0);
    vec4 t1 = texelFetch(tex, TF_WRAP_TEXEL(texel_coord + ivec2(1, 0), texture_size), 0);
    vec4 t2 = texelFetch(tex, TF_WRAP_TEXEL(texel_coord + ivec2(0, 1), texture_size), 0);
    vec4 t3 = texelFetch(tex, TF_WRAP_TEXEL(texel_coord + ivec2(1, 1), texture_size), 0);
    
    return mix(mix(t0, t1, f.x), mix(t2, t3, f.x), f.y);
}
#endif
#undef FILTER_BOX
#undef TF_WRAP_TEXEL
#undef TF_SAMPLE_NAME

#undef TF_UV_IS_PIXEL

vec4 quantize3Bit(in vec4 color) { return vec4(round(color.rgb * 8.0) / 8.0, step(0.5, color.a)); }
vec4 quantize4Bit(in vec4 color) { return round(color * 16.0) / 16.0; }

vec4 finalizeTextureColor(vec4 color, bool mono)
{
	return mono ? color.rrrr : color;
}

vec4 quantizeTexture0(vec4 color, int draw_flags)
{
	vec4 colorQuant = ((draw_flags & DRAW_FLAG_TEX0_4BIT) != 0) ? quantize4Bit(color) : color;
	colorQuant = ((draw_flags & DRAW_FLAG_TEX0_3BIT) != 0) ? quantize3Bit(colorQuant) : colorQuant;
	return finalizeTextureColor(colorQuant, (draw_flags & DRAW_FLAG_TEX0_MONO) != 0);
}

vec4 quantizeTexture1(vec4 color, int draw_flags)
{
	vec4 colorQuant = ((draw_flags & DRAW_FLAG_TEX1_4BIT) != 0) ? quantize4Bit(color) : color;
	colorQuant = ((draw_flags & DRAW_FLAG_TEX1_3BIT) != 0) ? quantize3Bit(colorQuant) : colorQuant;
	return finalizeTextureColor(colorQuant, (draw_flags & DRAW_FLAG_TEX1_MONO) != 0);
}

float compute_lod_fraction(vec2 dx, vec2 dy)
{
	bool sharpen = texture_detail_mode == 1;
	bool clam = texture_detail_mode == 0;

	vec2 dfd = max(abs(dx), abs(dy));
	float max_dist = max(dfd.x, dfd.y);
	float mip_base = floor(log2(max(max_dist, 1e-8)));
	bool distant = max_dist >= 16384.0;
	bool above_count = mip_base >= float(max(mip_count, 1));
	bool max_distant = distant || above_count;
	bool magnify = max_dist < 1.0;

	float detail_frac = max(prim_lod_min, max_dist) - float(sharpen);
	float magnified_frac = mix(float(max_distant), detail_frac, float(!clam));
	float distant_frac = float(distant || (above_count && clam));
	float denom = max(pow(2.0, max(mip_base, 0.0)), 1.0);
	float not_clamped_frac = max(max_dist / denom - 1.0, prim_lod_min);
	float not_magnified_frac = mix(distant_frac, not_clamped_frac, float(!max_distant || !clam));
	float lod_frac = mix(not_magnified_frac, magnified_frac, float(!distant && magnify));

	if (!use_texture_lod) {
		return clamp(not_clamped_frac, 0.0, 1.0);
	}

	return clamp(lod_frac, 0.0, 1.0);
}

vec3 cc_fetchColor(
	in int val,
	in vec4 shade,
	in vec4 comb,
	in vec4 texData0,
	in vec4 texData1,
	in vec4 prim,
	in vec4 env,
	in vec2 screen_pos,
	in float lod_frac,
	in float prim_lod_frac_val,
	in vec3 chroma_center,
	in vec3 chroma_scale
)
{
	     if(val == CC_C_COMB            ) return comb.rgb;
	else if(val == CC_C_TEX0            ) return texData0.rgb;
	else if(val == CC_C_TEX1            ) return texData1.rgb;
	else if(val == CC_C_PRIM            ) return prim.rgb;
	else if(val == CC_C_SHADE           ) return shade.rgb;
	else if(val == CC_C_ENV             ) return env.rgb;
	else if(val == CC_C_COMB_ALPHA      ) return comb.aaa;
	else if(val == CC_C_TEX0_ALPHA      ) return texData0.aaa;
	else if(val == CC_C_TEX1_ALPHA      ) return texData1.aaa;
	else if(val == CC_C_PRIM_ALPHA      ) return prim.aaa;
	else if(val == CC_C_SHADE_ALPHA     ) return linearToGamma(shade.aaa);
	else if(val == CC_C_ENV_ALPHA       ) return env.aaa;
	else if(val == CC_C_LOD_FRAC        ) return vec3(lod_frac);
	else if(val == CC_C_PRIM_LOD_FRAC   ) return vec3(prim_lod_frac_val);
	else if(val == CC_C_NOISE           ) return vec3(noise(screen_pos * 0.25));
	else if(val == CC_C_CHROMA_KEY_CENTER) return chroma_center;
	else if(val == CC_C_CHROMA_KEY_SCALE ) return chroma_scale;
	else if(val == CC_C_1               ) return vec3(1.0);
	return vec3(0.0);
}

float cc_fetchAlpha(
	in int val,
	in vec4 shade,
	in vec4 comb,
	in vec4 texData0,
	in vec4 texData1,
	in vec4 prim,
	in vec4 env,
	in float lod_frac,
	in float prim_lod_frac_val
)
{
	     if(val == CC_A_COMB         ) return comb.a;
	else if(val == CC_A_TEX0         ) return texData0.a;
	else if(val == CC_A_TEX1         ) return texData1.a;
	else if(val == CC_A_PRIM         ) return prim.a;
	else if(val == CC_A_SHADE        ) return shade.a;
	else if(val == CC_A_ENV          ) return env.a;
	else if(val == CC_A_LOD_FRAC     ) return lod_frac;
	else if(val == CC_A_PRIM_LOD_FRAC) return prim_lod_frac_val;
	else if(val == CC_A_1            ) return 1.0;
	return 0.0;
}

vec4 cc_overflowValue(in vec4 value) { return mod(value + 0.5, 2.0) - 0.5; }
vec4 cc_clampValue(in vec4 value) { return clamp(value, 0.0, 1.0); }

N64CombVertexData n64comb_vertex_data(vec3 normal_in, vec4 color_in, float shade_from_vertex_color, vec2 uv_in, mat4 view_matrix, mat3 model_normal_matrix) {
	N64CombVertexData outv;
	vec4 material_shift = build_material_shift();
	vec4 material_low = build_material_low();
	vec4 material_high = build_material_high();

	int geo_mode = build_geo_mode();
	bool use_tex = (geo_mode & G_TEX_GEN) != 0;

	vec3 normScreen = normalize(mat3(view_matrix) * (model_normal_matrix * normal_in));

	// Pass through vertex color as shade
	outv.cc_shade = color_in;
	outv.cc_shade_from_vertex_color = shade_from_vertex_color;

	// UV generation: use mesh UVs, or generate from normals (env mapping)
	vec2 uvGen = use_tex ? (normScreen.xy * 0.5 + 0.5) : uv_in;

	// Use atlas region sizes when set, otherwise full texture sizes.
	ivec2 texSizeA = atlas_region_0.x > 0 ? atlas_region_0 : max(textureSize(Texture0, 0), ivec2(1));
	ivec2 texSizeB = atlas_region_1.x > 0 ? atlas_region_1 : max(textureSize(Texture1, 0), ivec2(1));
	vec4 texSize = vec4(vec2(texSizeA), vec2(texSizeB));

	vec4 uv_local = uvGen.xyxy * texSize.xyxy;

	uv_local.yw = texSize.yw - uv_local.yw - 1.0;
	uv_local *= material_shift;
	uv_local.yw = texSize.yw - uv_local.yw - 1.0;

	uv_local = uv_local - (material_shift * 0.5) - material_low;

	outv.uv = uv_local;
	outv.tileSize = abs(material_high) - abs(material_low);
	return outv;
}

vec4 n64comb_fragment(vec2 screen_uv) {
	int other_mode_h = build_other_mode_h();
	int draw_flags = build_draw_flags();

	// Build prim/env once per fragment instead of inside every cc_fetch call.
	vec4 primColor = build_material_prim_color();
	vec4 envColor  = build_material_env_color();

	vec4 cc0[4];
	vec4 cc1[4];
	vec4 ccValue = vec4(0.0);

	vec4 shade_input = cc_shade;
	if (cc_shade_from_vertex_color > 0.5) {
		shade_input = fromLinearCompatibility(shade_input);
	}
	vec4 ccShade = clamp_shade_input ? clamp(shade_input, 0.0, 1.0) : shade_input;

	vec4 texData0;
	vec4 texData1;

	// Atlas seam zoom: per-tile UV inset to avoid sampling exact edges.
	// Applied in fragment (not vertex) because mod breaks varying interpolation.
	vec4 uv_zoomed = uv;
	if (atlas_seam_zoom > 0.0) {
		float sz = atlas_seam_zoom;
		ivec2 rA = atlas_region_0.x > 0 ? atlas_region_0 : max(textureSize(Texture0, 0), ivec2(1));
		ivec2 rB = atlas_region_1.x > 0 ? atlas_region_1 : max(textureSize(Texture1, 0), ivec2(1));
		vec4 region = vec4(vec2(rA), vec2(rB));
		uv_zoomed = mod(uv, region) * (1.0 - sz * 2.0) + region * sz;
	}

	// Apply per-texture scroll (pixels per second, driven by TIME).
	uv_zoomed.xy += Texture0_Scroll * TIME;
	uv_zoomed.zw += Texture1_Scroll * TIME;

	if (filter_mode == 0) {
		texData0 = sample_texA_nearest(Texture0, uv_zoomed.xy);
		texData1 = sample_texB_nearest(Texture1, uv_zoomed.zw);
	} else if (filter_mode == 1) {
		texData0 = sample_texA_3point(Texture0, uv_zoomed.xy);
		texData1 = sample_texB_3point(Texture1, uv_zoomed.zw);
	} else {
		texData0 = sample_texA_bilinear(Texture0, uv_zoomed.xy);
		texData1 = sample_texB_bilinear(Texture1, uv_zoomed.zw);
	}

	texData0 = quantizeTexture0(texData0, draw_flags);
	texData1 = quantizeTexture1(texData1, draw_flags);

	vec2 dx = abs(vec2(dFdx(uv.x), dFdy(uv.x)));
	vec2 dy = abs(vec2(dFdx(uv.y), dFdy(uv.y)));
	float lod_frac = compute_lod_fraction(dx, dy);
	vec2 screen_pos = vec2(screen_uv.x, 1.0 - screen_uv.y);

	ivec4 cc0Color = ivec4(
		cc_color_a_from_ui(cc0_color_a),
		cc_color_b_from_ui(cc0_color_b),
		cc_color_c_from_ui(cc0_color_c),
		cc_color_d_from_ui(cc0_color_d)
	);
	ivec4 cc0Alpha = ivec4(
		cc_alpha_abd_from_ui(cc0_alpha_a),
		cc_alpha_abd_from_ui(cc0_alpha_b),
		cc_alpha_c_from_ui(cc0_alpha_c),
		cc_alpha_abd_from_ui(cc0_alpha_d)
	);

	ivec4 cc1Color = ivec4(
		cc_color_a_from_ui(cc1_color_a),
		cc_color_b_from_ui(cc1_color_b),
		cc_color_c_from_ui(cc1_color_c),
		cc_color_d_from_ui(cc1_color_d)
	);
	ivec4 cc1Alpha = ivec4(
		cc_alpha_abd_from_ui(cc1_alpha_a),
		cc_alpha_abd_from_ui(cc1_alpha_b),
		cc_alpha_c_from_ui(cc1_alpha_c),
		cc_alpha_abd_from_ui(cc1_alpha_d)
	);

	cc0[0].rgb = cc_fetchColor(cc0Color.x, ccShade, ccValue, texData0, texData1, primColor, envColor, screen_pos, lod_frac, prim_lod_frac, chroma_key_center, chroma_key_scale);
	cc0[1].rgb = cc_fetchColor(cc0Color.y, ccShade, ccValue, texData0, texData1, primColor, envColor, screen_pos, lod_frac, prim_lod_frac, chroma_key_center, chroma_key_scale);
	cc0[2].rgb = cc_fetchColor(cc0Color.z, ccShade, ccValue, texData0, texData1, primColor, envColor, screen_pos, lod_frac, prim_lod_frac, chroma_key_center, chroma_key_scale);
	cc0[3].rgb = cc_fetchColor(cc0Color.w, ccShade, ccValue, texData0, texData1, primColor, envColor, screen_pos, lod_frac, prim_lod_frac, chroma_key_center, chroma_key_scale);

	cc0[0].a = cc_fetchAlpha(cc0Alpha.x, ccShade, ccValue, texData0, texData1, primColor, envColor, lod_frac, prim_lod_frac);
	cc0[1].a = cc_fetchAlpha(cc0Alpha.y, ccShade, ccValue, texData0, texData1, primColor, envColor, lod_frac, prim_lod_frac);
	cc0[2].a = cc_fetchAlpha(cc0Alpha.z, ccShade, ccValue, texData0, texData1, primColor, envColor, lod_frac, prim_lod_frac);
	cc0[3].a = cc_fetchAlpha(cc0Alpha.w, ccShade, ccValue, texData0, texData1, primColor, envColor, lod_frac, prim_lod_frac);

	ccValue = cc_overflowValue((cc0[0] - cc0[1]) * cc0[2] + cc0[3]);

	if((other_mode_h & G_CYC_2CYCLE) != 0) {
		cc1[0].rgb = cc_fetchColor(cc1Color.x, ccShade, ccValue, texData0, texData1, primColor, envColor, screen_pos, lod_frac, prim_lod_frac, chroma_key_center, chroma_key_scale);
		cc1[1].rgb = cc_fetchColor(cc1Color.y, ccShade, ccValue, texData0, texData1, primColor, envColor, screen_pos, lod_frac, prim_lod_frac, chroma_key_center, chroma_key_scale);
		cc1[2].rgb = cc_fetchColor(cc1Color.z, ccShade, ccValue, texData0, texData1, primColor, envColor, screen_pos, lod_frac, prim_lod_frac, chroma_key_center, chroma_key_scale);
		cc1[3].rgb = cc_fetchColor(cc1Color.w, ccShade, ccValue, texData0, texData1, primColor, envColor, screen_pos, lod_frac, prim_lod_frac, chroma_key_center, chroma_key_scale);

		cc1[0].a = cc_fetchAlpha(cc1Alpha.x, ccShade, ccValue, texData0, texData1, primColor, envColor, lod_frac, prim_lod_frac);
		cc1[1].a = cc_fetchAlpha(cc1Alpha.y, ccShade, ccValue, texData0, texData1, primColor, envColor, lod_frac, prim_lod_frac);
		cc1[2].a = cc_fetchAlpha(cc1Alpha.z, ccShade, ccValue, texData0, texData1, primColor, envColor, lod_frac, prim_lod_frac);
		cc1[3].a = cc_fetchAlpha(cc1Alpha.w, ccShade, ccValue, texData0, texData1, primColor, envColor, lod_frac, prim_lod_frac);

		ccValue = (cc1[0] - cc1[1]) * cc1[2] + cc1[3];
	}

	ccValue = cc_overflowValue(ccValue);
	if (clamp_combiner_output) {
		ccValue = cc_clampValue(ccValue);
	}


	if (ccValue.a < alpha_clip) {
		discard;
	}

	return ccValue;
}

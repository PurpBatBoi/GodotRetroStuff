// n64comb.gdshaderinc
// N64 RDP Color Combiner — modular shader include for Godot 4
//
// ── Feature flags ──────────────────────────────────────────────────────────────
// Define these in your shader BEFORE #include-ing this file.
// Omitting a flag strips that feature from the compiled shader entirely.
//
//   Filter mode (pick exactly one, or omit all for a runtime-switchable path):
//     #define N64_FILTER_NEAREST       — nearest-neighbour only
//     #define N64_FILTER_3POINT        — N64-style 3-point only
//     #define N64_FILTER_BILINEAR      — bilinear only
//
//   Combiner cycles:
//     #define N64_TWO_CYCLE            — enable second combiner cycle (cc1_*)
//
//   CC color inputs (strip any branch you never route a slot to):
//     #define N64_INPUT_TEX1           — Tex1 color/alpha inputs
//     #define N64_INPUT_ENV            — Env color/alpha inputs
//     #define N64_INPUT_NOISE          — Noise color input
//     #define N64_INPUT_COMB_ALPHA     — Combined-alpha-as-color input
//     #define N64_INPUT_TEX_ALPHA      — Tex0/Tex1 alpha-as-color inputs
//     #define N64_INPUT_PRIM_ALPHA     — Prim/Env alpha-as-color inputs
//     #define N64_INPUT_SHADE_ALPHA    — Shade alpha-as-color input (+ gamma path)
//     #define N64_INPUT_ALPHA_ENV      — Env alpha input in alpha combiner
//
//   Optional systems:
//     #define N64_CHROMA_KEY           — chroma-key center/scale inputs
//     #define N64_LOD                  — LOD fraction + dFdx/dFdy path
//     #define N64_ATLAS                — texture atlas / seam-hiding support
//     #define N64_TEX_GEN              — normal-based UV generation (env mapping)
//     #define N64_SCROLL               — per-texture UV scroll (TIME-driven)
//     #define N64_QUANTIZE             — 3-bit / 4-bit texture quantisation
//     #define N64_VERTEX_COLOR_GAMMA   — gamma-correct vertex color shade input (for compatibility-mode)
// ──────────────────────────────────────────────────────────────────────────────

// If no filter flag is set, compile all three variants with a runtime switch.
#if !defined(N64_FILTER_NEAREST) && !defined(N64_FILTER_3POINT) && !defined(N64_FILTER_BILINEAR)
#define N64_FILTER_RUNTIME
#endif

// N64_INPUT_SHADE_ALPHA requires the linearToGamma utility.
// N64_VERTEX_COLOR_GAMMA requires fromLinear. Both share the same guard.
#if defined(N64_INPUT_SHADE_ALPHA) || defined(N64_VERTEX_COLOR_GAMMA)
#define N64_NEED_GAMMA_UTILS
#endif

// ── CC Color input constants ───────────────────────────────────────────────────
const int CC_C_1          = 1;
const int CC_C_COMB       = 2;
const int CC_C_TEX0       = 3;
#ifdef N64_INPUT_TEX1
const int CC_C_TEX1       = 4;
#endif
const int CC_C_PRIM       = 5;
const int CC_C_SHADE      = 6;
#ifdef N64_INPUT_ENV
const int CC_C_ENV        = 7;
#endif
#ifdef N64_INPUT_COMB_ALPHA
const int CC_C_COMB_ALPHA = 10;
#endif
#ifdef N64_INPUT_TEX_ALPHA
const int CC_C_TEX0_ALPHA = 11;
#ifdef N64_INPUT_TEX1
const int CC_C_TEX1_ALPHA = 12;
#endif
#endif
#ifdef N64_INPUT_PRIM_ALPHA
const int CC_C_PRIM_ALPHA = 13;
const int CC_C_ENV_ALPHA  = 15;
#endif
#ifdef N64_INPUT_SHADE_ALPHA
const int CC_C_SHADE_ALPHA = 14;
#endif
#ifdef N64_LOD
const int CC_C_LOD_FRAC      = 16;
const int CC_C_PRIM_LOD_FRAC = 17;
#endif
#ifdef N64_INPUT_NOISE
const int CC_C_NOISE = 18;
#endif
#ifdef N64_CHROMA_KEY
const int CC_C_CHROMA_KEY_CENTER = 19;
const int CC_C_CHROMA_KEY_SCALE  = 20;
#endif

// ── CC Alpha input constants ───────────────────────────────────────────────────
const int CC_A_1    = 1;
const int CC_A_COMB = 2;
const int CC_A_TEX0 = 3;
#ifdef N64_INPUT_TEX1
const int CC_A_TEX1 = 4;
#endif
const int CC_A_PRIM  = 5;
const int CC_A_SHADE = 6;
#ifdef N64_INPUT_ALPHA_ENV
const int CC_A_ENV = 7;
#endif
#ifdef N64_LOD
const int CC_A_LOD_FRAC      = 8;
const int CC_A_PRIM_LOD_FRAC = 9;
#endif

// ── Per-slot UI → CC constant lookup tables ────────────────────────────────────
//
// Slots that reference stripped inputs just map to 0 (black/transparent),
// which is the N64's hardware behaviour for unused inputs anyway.

// Color A: Combined, Tex0, Tex1, Prim, Shade, Env, 1, Noise, 0
const int CC_COLOR_A_TABLE[9] = int[](
	CC_C_COMB,
	CC_C_TEX0,
#ifdef N64_INPUT_TEX1
	CC_C_TEX1,
#else
	0,
#endif
	CC_C_PRIM,
	CC_C_SHADE,
#ifdef N64_INPUT_ENV
	CC_C_ENV,
#else
	0,
#endif
	CC_C_1,
#ifdef N64_INPUT_NOISE
	CC_C_NOISE,
#else
	0,
#endif
	0
);

// Color B: Combined, Tex0, Tex1, Prim, Shade, Env, (Chroma Key Center | 0), 0
const int CC_COLOR_B_TABLE[8] = int[](
	CC_C_COMB,
	CC_C_TEX0,
#ifdef N64_INPUT_TEX1
	CC_C_TEX1,
#else
	0,
#endif
	CC_C_PRIM,
	CC_C_SHADE,
#ifdef N64_INPUT_ENV
	CC_C_ENV,
#else
	0,
#endif
#ifdef N64_CHROMA_KEY
	CC_C_CHROMA_KEY_CENTER,
#else
	0,
#endif
	0
);

// Color C: Combined, Tex0, Tex1, Prim, Shade, Env,
//          (Chroma Key Scale | 0), (Comb Alpha | 0),
//          (Tex0 Alpha | 0), (Tex1 Alpha | 0),
//          (Prim Alpha | 0), (Shade Alpha | 0), (Env Alpha | 0),
//          (LOD Frac | 0), (Prim LOD Frac | 0), 0
const int CC_COLOR_C_TABLE[16] = int[](
	CC_C_COMB,
	CC_C_TEX0,
#ifdef N64_INPUT_TEX1
	CC_C_TEX1,
#else
	0,
#endif
	CC_C_PRIM,
	CC_C_SHADE,
#ifdef N64_INPUT_ENV
	CC_C_ENV,
#else
	0,
#endif
#ifdef N64_CHROMA_KEY
	CC_C_CHROMA_KEY_SCALE,
#else
	0,
#endif
#ifdef N64_INPUT_COMB_ALPHA
	CC_C_COMB_ALPHA,
#else
	0,
#endif
#ifdef N64_INPUT_TEX_ALPHA
	CC_C_TEX0_ALPHA,
#else
	0,
#endif
#if defined(N64_INPUT_TEX_ALPHA) && defined(N64_INPUT_TEX1)
	CC_C_TEX1_ALPHA,
#else
	0,
#endif
#ifdef N64_INPUT_PRIM_ALPHA
	CC_C_PRIM_ALPHA,
#else
	0,
#endif
#ifdef N64_INPUT_SHADE_ALPHA
	CC_C_SHADE_ALPHA,
#else
	0,
#endif
#ifdef N64_INPUT_PRIM_ALPHA
	CC_C_ENV_ALPHA,
#else
	0,
#endif
#ifdef N64_LOD
	CC_C_LOD_FRAC,
	CC_C_PRIM_LOD_FRAC,
#else
	0,
	0,
#endif
	0
);

// Color D: Combined, Tex0, Tex1, Prim, Shade, Env, 1, 0
const int CC_COLOR_D_TABLE[8] = int[](
	CC_C_COMB,
	CC_C_TEX0,
#ifdef N64_INPUT_TEX1
	CC_C_TEX1,
#else
	0,
#endif
	CC_C_PRIM,
	CC_C_SHADE,
#ifdef N64_INPUT_ENV
	CC_C_ENV,
#else
	0,
#endif
	CC_C_1,
	0
);

// Alpha A/B/D: Comb, Tex0, (Tex1 | 0), Prim, Shade, (Env | 0), 1, 0
const int CC_ALPHA_ABD_TABLE[8] = int[](
	CC_A_COMB,
	CC_A_TEX0,
#ifdef N64_INPUT_TEX1
	CC_A_TEX1,
#else
	0,
#endif
	CC_A_PRIM,
	CC_A_SHADE,
#ifdef N64_INPUT_ALPHA_ENV
	CC_A_ENV,
#else
	0,
#endif
	CC_A_1,
	0
);

// Alpha C: (LOD Frac | 0), Comb, Tex0, (Tex1 | 0), Prim, Shade, (Env | 0),
//          (Prim LOD Frac | 0), 0
const int CC_ALPHA_C_TABLE[9] = int[](
#ifdef N64_LOD
	CC_A_LOD_FRAC,
#else
	0,
#endif
	CC_A_COMB,
	CC_A_TEX0,
#ifdef N64_INPUT_TEX1
	CC_A_TEX1,
#else
	0,
#endif
	CC_A_PRIM,
	CC_A_SHADE,
#ifdef N64_INPUT_ALPHA_ENV
	CC_A_ENV,
#else
	0,
#endif
#ifdef N64_LOD
	CC_A_PRIM_LOD_FRAC,
#else
	0,
#endif
	0
);

int cc_color_a_from_ui(int idx) { return CC_COLOR_A_TABLE[clamp(idx, 0, 8)]; }
int cc_color_b_from_ui(int idx) { return CC_COLOR_B_TABLE[clamp(idx, 0, 7)]; }
int cc_color_c_from_ui(int idx) { return CC_COLOR_C_TABLE[clamp(idx, 0, 15)]; }
int cc_color_d_from_ui(int idx) { return CC_COLOR_D_TABLE[clamp(idx, 0, 7)]; }
int cc_alpha_abd_from_ui(int idx) { return CC_ALPHA_ABD_TABLE[clamp(idx, 0, 7)]; }
int cc_alpha_c_from_ui(int idx)   { return CC_ALPHA_C_TABLE[clamp(idx, 0, 8)]; }

// ── Texture uniforms ───────────────────────────────────────────────────────────
group_uniforms Texture0_Settings;
	/** Texture 0 source image. */
	uniform sampler2D Texture0 : source_color;
	/** Tex0 wrap mask in pixels (x,y). */
	uniform vec2 Texture0_Mask;
	/** Tex0 UV scale (tile rate). */
	uniform vec2 Texture0_Scale;
	/** Tex0 UV offset (pixel-space pan). */
	uniform vec2 Texture0_Offset;
	/** Clamp Tex0 on X. */
	uniform bool Texture0_ClampX;
	/** Clamp Tex0 on Y. */
	uniform bool Texture0_ClampY;
	/** Mirror Tex0 on X. */
	uniform bool Texture0_MirrorX;
	/** Mirror Tex0 on Y. */
	uniform bool Texture0_MirrorY;
#ifdef N64_SCROLL
	/** Tex0 UV scroll speed (pixels/sec). */
	uniform vec2 Texture0_Scroll = vec2(0.0);
#endif
group_uniforms;

#ifdef N64_INPUT_TEX1
group_uniforms Texture1_Settings;
	/** Texture 1 source image. */
	uniform sampler2D Texture1 : source_color;
	/** Tex1 wrap mask in pixels (x,y). */
	uniform vec2 Texture1_Mask;
	/** Tex1 UV scale (tile rate). */
	uniform vec2 Texture1_Scale;
	/** Tex1 UV offset (pixel-space pan). */
	uniform vec2 Texture1_Offset;
	/** Clamp Tex1 on X. */
	uniform bool Texture1_ClampX;
	/** Clamp Tex1 on Y. */
	uniform bool Texture1_ClampY;
	/** Mirror Tex1 on X. */
	uniform bool Texture1_MirrorX;
	/** Mirror Tex1 on Y. */
	uniform bool Texture1_MirrorY;
#ifdef N64_SCROLL
	/** Tex1 UV scroll speed (pixels/sec). */
	uniform vec2 Texture1_Scroll = vec2(0.0);
#endif
group_uniforms;
#endif // N64_INPUT_TEX1

group_uniforms Cycle0_Combiner_Settings;
	/** Cycle 0 color input A. */
	uniform int cc0_color_a : hint_enum("Combined,Tex0,Tex1,Prim,Shade,Env,1,Noise,0") = 1;
	/** Cycle 0 color input B. */
	uniform int cc0_color_b : hint_enum("Combined,Tex0,Tex1,Prim,Shade,Env,Chroma Key Center,0") = 7;
	/** Cycle 0 color input C. */
	uniform int cc0_color_c : hint_enum("Combined,Tex0,Tex1,Prim,Shade,Env,Chroma Key Scale,Comb Alpha,Tex0 Alpha,Tex1 Alpha,Prim Alpha,Shade Alpha,Env Alpha,LOD Frac,Prim LOD Frac,0") = 4;
	/** Cycle 0 color input D. */
	uniform int cc0_color_d : hint_enum("Combined,Tex0,Tex1,Prim,Shade,Env,1,0") = 7;
	/** Cycle 0 alpha input A. */
	uniform int cc0_alpha_a : hint_enum("Comb Alpha,Tex0 Alpha,Tex1 Alpha,Prim Alpha,Shade Alpha,Env Alpha,1,0") = 7;
	/** Cycle 0 alpha input B. */
	uniform int cc0_alpha_b : hint_enum("Comb Alpha,Tex0 Alpha,Tex1 Alpha,Prim Alpha,Shade Alpha,Env Alpha,1,0") = 7;
	/** Cycle 0 alpha input C. */
	uniform int cc0_alpha_c : hint_enum("LOD Frac,Comb Alpha,Tex0 Alpha,Tex1 Alpha,Prim Alpha,Shade Alpha,Env Alpha,Prim LOD Frac,0") = 8;
	/** Cycle 0 alpha input D. */
	uniform int cc0_alpha_d : hint_enum("Comb Alpha,Tex0 Alpha,Tex1 Alpha,Prim Alpha,Shade Alpha,Env Alpha,1,0") = 5;
group_uniforms;

#ifdef N64_TWO_CYCLE
group_uniforms Cycle1_Combiner_Settings;
	/** Cycle 1 color input A. */
	uniform int cc1_color_a : hint_enum("Combined,Tex0,Tex1,Prim,Shade,Env,1,Noise,0") = 1;
	/** Cycle 1 color input B. */
	uniform int cc1_color_b : hint_enum("Combined,Tex0,Tex1,Prim,Shade,Env,Chroma Key Center,0") = 7;
	/** Cycle 1 color input C. */
	uniform int cc1_color_c : hint_enum("Combined,Tex0,Tex1,Prim,Shade,Env,Chroma Key Scale,Comb Alpha,Tex0 Alpha,Tex1 Alpha,Prim Alpha,Shade Alpha,Env Alpha,LOD Frac,Prim LOD Frac,0") = 4;
	/** Cycle 1 color input D. */
	uniform int cc1_color_d : hint_enum("Combined,Tex0,Tex1,Prim,Shade,Env,1,0") = 7;
	/** Cycle 1 alpha input A. */
	uniform int cc1_alpha_a : hint_enum("Comb Alpha,Tex0 Alpha,Tex1 Alpha,Prim Alpha,Shade Alpha,Env Alpha,1,0") = 7;
	/** Cycle 1 alpha input B. */
	uniform int cc1_alpha_b : hint_enum("Comb Alpha,Tex0 Alpha,Tex1 Alpha,Prim Alpha,Shade Alpha,Env Alpha,1,0") = 7;
	/** Cycle 1 alpha input C. */
	uniform int cc1_alpha_c : hint_enum("LOD Frac,Comb Alpha,Tex0 Alpha,Tex1 Alpha,Prim Alpha,Shade Alpha,Env Alpha,Prim LOD Frac,0") = 8;
	/** Cycle 1 alpha input D. */
	uniform int cc1_alpha_d : hint_enum("Comb Alpha,Tex0 Alpha,Tex1 Alpha,Prim Alpha,Shade Alpha,Env Alpha,1,0") = 5;
group_uniforms;
#endif // N64_TWO_CYCLE

group_uniforms Material_Colors;
	uniform float material_prim_r = 1.0;
	uniform float material_prim_g = 1.0;
	uniform float material_prim_b = 1.0;
	uniform float material_prim_a = 1.0;
#ifdef N64_INPUT_ENV
	uniform float material_env_r = 1.0;
	uniform float material_env_g = 1.0;
	uniform float material_env_b = 1.0;
	uniform float material_env_a = 1.0;
#endif
group_uniforms;

#if defined(N64_CHROMA_KEY) || defined(N64_LOD)
group_uniforms Extra_Inputs;
#ifdef N64_CHROMA_KEY
	/** Chroma key center color (RGB). */
	uniform vec3 chroma_key_center = vec3(0.0);
	/** Chroma key scale factor (RGB). */
	uniform vec3 chroma_key_scale  = vec3(0.0);
#endif
#ifdef N64_LOD
	/** Primitive LOD fraction (0–1). */
	uniform float prim_lod_frac : hint_range(0.0, 1.0) = 0.0;
	/** Minimum LOD contribution. */
	uniform float prim_lod_min : hint_range(0.0, 1.0) = 0.0;
	/** Number of mip levels for LOD approximation. */
	uniform int mip_count : hint_range(1, 8) = 1;
#endif
group_uniforms;
#endif

group_uniforms Alpha_Settings;
	/** Alpha cutout threshold. */
	uniform float alpha_clip : hint_range(0.0, 1.0) = 0.0;
group_uniforms;

#ifdef N64_ATLAS
group_uniforms Atlas_Settings;
	uniform ivec2 atlas_region_0 = ivec2(0);
	uniform ivec2 atlas_offset_0 = ivec2(0);
#ifdef N64_INPUT_TEX1
	uniform ivec2 atlas_region_1 = ivec2(0);
	uniform ivec2 atlas_offset_1 = ivec2(0);
#endif
	uniform int   atlas_seam_hiding = 0;
	uniform float atlas_seam_zoom : hint_range(0.0, 0.1) = 0.0;
group_uniforms;
#endif

group_uniforms Mode_Toggles;
#ifdef N64_TEX_GEN
	uniform bool use_tex_gen = false;
#endif
#ifdef N64_FILTER_RUNTIME
	uniform int filter_mode : hint_enum("Nearest,3-Point,Bilinear") = 1;
#endif
#ifdef N64_TWO_CYCLE
	uniform bool use_two_cycle = false;
#endif
#ifdef N64_LOD
	uniform bool use_texture_lod = false;
	uniform int  texture_detail_mode : hint_enum("Clamp,Sharpen,Detail") = 0;
#endif
#ifdef N64_QUANTIZE
	uniform bool tex0_mono = false;
	uniform int  tex0_quantize : hint_enum("None,4-bit,3-bit") = 0;
#ifdef N64_INPUT_TEX1
	uniform bool tex1_mono = false;
	uniform int  tex1_quantize : hint_enum("None,4-bit,3-bit") = 0;
#endif
#endif
group_uniforms;

group_uniforms Range_Control;
	uniform bool clamp_shade_input     = false;
	uniform bool clamp_combiner_output = false;
group_uniforms;

// ── Geometry mode bits ─────────────────────────────────────────────────────────
#ifdef N64_TEX_GEN
const int G_TEX_GEN = (1 << 14);
#endif

// ── Draw flag bits (quantise only) ────────────────────────────────────────────
#ifdef N64_QUANTIZE
const int DRAW_FLAG_TEX0_MONO = (1 << 1);
const int DRAW_FLAG_TEX1_MONO = (1 << 2);
const int DRAW_FLAG_TEX0_4BIT = (1 << 5);
const int DRAW_FLAG_TEX1_4BIT = (1 << 6);
const int DRAW_FLAG_TEX0_3BIT = (1 << 7);
const int DRAW_FLAG_TEX1_3BIT = (1 << 8);
#endif

// ── Varyings ───────────────────────────────────────────────────────────────────
varying vec4  cc_shade;
varying float cc_shade_from_vertex_color;
varying vec4  uv;       // xy = tex0, zw = tex1 (pixel space)
varying vec4  tileSize;

struct N64CombVertexData {
	vec4  cc_shade;
	float cc_shade_from_vertex_color;
	vec4  uv;
	vec4  tileSize;
};

// ── Material vector builders ───────────────────────────────────────────────────
vec4 build_material_mask()
{
	vec2 s0 = vec2(Texture0_ClampX ? -1.0 : 1.0, Texture0_ClampY ? -1.0 : 1.0);
#ifdef N64_INPUT_TEX1
	vec2 s1 = vec2(Texture1_ClampX ? -1.0 : 1.0, Texture1_ClampY ? -1.0 : 1.0);
	return vec4(Texture0_Mask * s0, Texture1_Mask * s1);
#else
	return vec4(Texture0_Mask * s0, 1.0, 1.0);
#endif
}

vec4 build_material_shift()
{
#ifdef N64_INPUT_TEX1
	return vec4(Texture0_Scale, Texture1_Scale);
#else
	return vec4(Texture0_Scale, 1.0, 1.0);
#endif
}

vec4 build_material_low()
{
#ifdef N64_INPUT_TEX1
	return vec4(Texture0_Offset, Texture1_Offset);
#else
	return vec4(Texture0_Offset, 0.0, 0.0);
#endif
}

vec4 build_material_high()
{
	vec2 m0 = vec2(Texture0_MirrorX ? -1.0 : 1.0, Texture0_MirrorY ? -1.0 : 1.0);
#ifdef N64_INPUT_TEX1
	vec2 m1 = vec2(Texture1_MirrorX ? -1.0 : 1.0, Texture1_MirrorY ? -1.0 : 1.0);
	return vec4(Texture0_Mask * m0, Texture1_Mask * m1);
#else
	return vec4(Texture0_Mask * m0, 1.0, 1.0);
#endif
}

vec4 build_material_prim_color()
{
	return vec4(material_prim_r, material_prim_g, material_prim_b, material_prim_a);
}

#ifdef N64_INPUT_ENV
vec4 build_material_env_color()
{
	return vec4(material_env_r, material_env_g, material_env_b, material_env_a);
}
#endif

// ── Gamma utilities (only when actually needed) ────────────────────────────────
#ifdef N64_NEED_GAMMA_UTILS
vec3 linearToGamma(in vec3 color)
{
	vec3 safe = max(color, vec3(0.0));
	return mix(safe * 12.92,
	           1.055 * pow(safe, vec3(1.0 / 2.4)) - 0.055,
	           step(vec3(0.0031308), safe));
}

vec4 fromLinear(vec4 c)
{
	bvec3 cut  = lessThan(c.rgb, vec3(0.0031308));
	vec3  high = vec3(1.055) * pow(c.rgb, vec3(1.0 / 2.4)) - vec3(0.055);
	vec3  low  = c.rgb * vec3(12.92);
	return vec4(mix(high, low, cut), c.a);
}
#endif

// ── Noise ─────────────────────────────────────────────────────────────────────
#ifdef N64_INPUT_NOISE
float noise(in vec2 coords)
{
	return fract(sin(dot(coords, vec2(12.9898, 78.233))) * 43758.5453);
}
#endif

// ── Wrap helpers ───────────────────────────────────────────────────────────────
vec4 mirrorUV(vec4 uvEnd, vec4 uvIn)
{
	vec4 m2 = mod(uvIn, uvEnd * 2.0 + 1.0);
	return mix(m2, uvEnd * 2.0 - m2, step(uvEnd, m2));
}

ivec4 wrappedMirror(ivec4 texSize, ivec4 uvIn, vec4 mat_mask, vec4 mat_high, vec4 tile_size)
{
	vec4 mask         = abs(mat_mask);
	vec4 isClamp      = step(mat_mask, vec4(1.0));
	vec4 isMirror     = step(mat_high, vec4(0.0));
	vec4 isForceClamp = step(mask, vec4(1.0));
	mask = mix(mask, vec4(256.0), isForceClamp);

	vec4 tc = vec4(uvIn);
	tc.yw = vec2(texSize.yw) - tc.yw;

	tc = mix(tc, clamp(tc, vec4(0.0), tile_size), isClamp);
	tc = mix(tc, mirrorUV(mask - vec4(0.5), tc), isMirror);
	tc = mod(tc, min(vec4(texSize + 1), mask));
	tc.yw = vec2(texSize.yw) - tc.yw;
	return ivec4(tc);
}

// tex0-only fast path (avoids packing/unpacking tex1 when N64_INPUT_TEX1 is off)
ivec2 wrap_texel_a_simple(ivec2 coord, ivec2 size)
{
	vec4 mat_mask = build_material_mask();
	vec4 mat_high = build_material_high();
#ifdef N64_ATLAS
	ivec2 eff = atlas_region_0.x > 0 ? atlas_region_0 : size;
	ivec4 w   = wrappedMirror(ivec4(eff, 1, 1) - 1, ivec4(coord, 0, 0), mat_mask, mat_high, tileSize);
	w.xy = clamp(w.xy, ivec2(atlas_seam_hiding), eff - 1 - atlas_seam_hiding);
	return w.xy + atlas_offset_0;
#else
	return wrappedMirror(ivec4(size, 1, 1) - 1, ivec4(coord, 0, 0), mat_mask, mat_high, tileSize).xy;
#endif
}

#ifdef N64_INPUT_TEX1
// Both textures in one call (avoids reading uniforms twice per fetch)
ivec4 wrap_texel_ab(ivec2 coord_a, ivec2 size_a, ivec2 coord_b, ivec2 size_b)
{
	vec4 mat_mask = build_material_mask();
	vec4 mat_high = build_material_high();
#ifdef N64_ATLAS
	ivec2 eff_a = atlas_region_0.x > 0 ? atlas_region_0 : size_a;
	ivec2 eff_b = atlas_region_1.x > 0 ? atlas_region_1 : size_b;
	ivec4 w = wrappedMirror(ivec4(eff_a, eff_b) - 1, ivec4(coord_a, coord_b), mat_mask, mat_high, tileSize);
	w = clamp(w, ivec4(atlas_seam_hiding), ivec4(eff_a - 1 - atlas_seam_hiding, eff_b - 1 - atlas_seam_hiding));
	return w + ivec4(atlas_offset_0, atlas_offset_1);
#else
	return wrappedMirror(ivec4(size_a, size_b) - 1, ivec4(coord_a, coord_b), mat_mask, mat_high, tileSize);
#endif
}

ivec2 wrap_texel_a(ivec2 coord, ivec2 size)
{
	return wrap_texel_ab(coord, size, ivec2(0), ivec2(1)).xy;
}
ivec2 wrap_texel_b(ivec2 coord, ivec2 size)
{
	return wrap_texel_ab(ivec2(0), ivec2(1), coord, size).zw;
}
#else
// No tex1 — alias a to the simple path so filter functions compile cleanly.
ivec2 wrap_texel_a(ivec2 coord, ivec2 size) { return wrap_texel_a_simple(coord, size); }
#endif // N64_INPUT_TEX1

// ── Texture filter functions ───────────────────────────────────────────────────
// Only the variants requested by the consuming shader are compiled.

#if defined(N64_FILTER_NEAREST) || defined(N64_FILTER_RUNTIME)
vec4 sample_texA_nearest(sampler2D tex, vec2 uv_in) {
	ivec2 sz = textureSize(tex, 0);
	return texelFetch(tex, wrap_texel_a(ivec2(floor(uv_in)), sz), 0);
}
#ifdef N64_INPUT_TEX1
vec4 sample_texB_nearest(sampler2D tex, vec2 uv_in) {
	ivec2 sz = textureSize(tex, 0);
	return texelFetch(tex, wrap_texel_b(ivec2(floor(uv_in)), sz), 0);
}
#endif
#endif

#if defined(N64_FILTER_3POINT) || defined(N64_FILTER_RUNTIME)
vec4 sample_texA_3point(sampler2D tex, vec2 uv_in) {
	ivec2 sz = textureSize(tex, 0);
	vec2  pc = uv_in - 0.5;
	ivec2 tc = ivec2(floor(pc));
	vec2  f  = fract(pc);
	vec4 t0 = texelFetch(tex, wrap_texel_a(tc,               sz), 0);
	vec4 t1 = texelFetch(tex, wrap_texel_a(tc + ivec2(1, 0), sz), 0);
	vec4 t2 = texelFetch(tex, wrap_texel_a(tc + ivec2(0, 1), sz), 0);
	vec4 t3 = texelFetch(tex, wrap_texel_a(tc + ivec2(1, 1), sz), 0);
	if (f.x + f.y < 1.0) return t0 + (t1 - t0) * f.x + (t2 - t0) * f.y;
	vec2 w = 1.0 - f;
	return t3 + (t2 - t3) * w.x + (t1 - t3) * w.y;
}
#ifdef N64_INPUT_TEX1
vec4 sample_texB_3point(sampler2D tex, vec2 uv_in) {
	ivec2 sz = textureSize(tex, 0);
	vec2  pc = uv_in - 0.5;
	ivec2 tc = ivec2(floor(pc));
	vec2  f  = fract(pc);
	vec4 t0 = texelFetch(tex, wrap_texel_b(tc,               sz), 0);
	vec4 t1 = texelFetch(tex, wrap_texel_b(tc + ivec2(1, 0), sz), 0);
	vec4 t2 = texelFetch(tex, wrap_texel_b(tc + ivec2(0, 1), sz), 0);
	vec4 t3 = texelFetch(tex, wrap_texel_b(tc + ivec2(1, 1), sz), 0);
	if (f.x + f.y < 1.0) return t0 + (t1 - t0) * f.x + (t2 - t0) * f.y;
	vec2 w = 1.0 - f;
	return t3 + (t2 - t3) * w.x + (t1 - t3) * w.y;
}
#endif
#endif

#if defined(N64_FILTER_BILINEAR) || defined(N64_FILTER_RUNTIME)
vec4 sample_texA_bilinear(sampler2D tex, vec2 uv_in) {
	ivec2 sz = textureSize(tex, 0);
	vec2  pc = uv_in - 0.5;
	ivec2 tc = ivec2(floor(pc));
	vec2  f  = fract(pc);
	vec4 t0 = texelFetch(tex, wrap_texel_a(tc,               sz), 0);
	vec4 t1 = texelFetch(tex, wrap_texel_a(tc + ivec2(1, 0), sz), 0);
	vec4 t2 = texelFetch(tex, wrap_texel_a(tc + ivec2(0, 1), sz), 0);
	vec4 t3 = texelFetch(tex, wrap_texel_a(tc + ivec2(1, 1), sz), 0);
	return mix(mix(t0, t1, f.x), mix(t2, t3, f.x), f.y);
}
#ifdef N64_INPUT_TEX1
vec4 sample_texB_bilinear(sampler2D tex, vec2 uv_in) {
	ivec2 sz = textureSize(tex, 0);
	vec2  pc = uv_in - 0.5;
	ivec2 tc = ivec2(floor(pc));
	vec2  f  = fract(pc);
	vec4 t0 = texelFetch(tex, wrap_texel_b(tc,               sz), 0);
	vec4 t1 = texelFetch(tex, wrap_texel_b(tc + ivec2(1, 0), sz), 0);
	vec4 t2 = texelFetch(tex, wrap_texel_b(tc + ivec2(0, 1), sz), 0);
	vec4 t3 = texelFetch(tex, wrap_texel_b(tc + ivec2(1, 1), sz), 0);
	return mix(mix(t0, t1, f.x), mix(t2, t3, f.x), f.y);
}
#endif
#endif

// ── Quantisation ───────────────────────────────────────────────────────────────
#ifdef N64_QUANTIZE
vec4 quantize3Bit(vec4 c) { return vec4(round(c.rgb * 8.0) / 8.0, step(0.5, c.a)); }
vec4 quantize4Bit(vec4 c) { return round(c * 16.0) / 16.0; }

int build_draw_flags()
{
	int f = 0;
	f |= tex0_mono     ? DRAW_FLAG_TEX0_MONO : 0;
	f |= tex0_quantize == 1 ? DRAW_FLAG_TEX0_4BIT : 0;
	f |= tex0_quantize == 2 ? DRAW_FLAG_TEX0_3BIT : 0;
#ifdef N64_INPUT_TEX1
	f |= tex1_mono     ? DRAW_FLAG_TEX1_MONO : 0;
	f |= tex1_quantize == 1 ? DRAW_FLAG_TEX1_4BIT : 0;
	f |= tex1_quantize == 2 ? DRAW_FLAG_TEX1_3BIT : 0;
#endif
	return f;
}

vec4 quantizeTex0(vec4 c, int df)
{
	c = ((df & DRAW_FLAG_TEX0_4BIT) != 0) ? quantize4Bit(c) : c;
	c = ((df & DRAW_FLAG_TEX0_3BIT) != 0) ? quantize3Bit(c) : c;
	return ((df & DRAW_FLAG_TEX0_MONO) != 0) ? c.rrrr : c;
}

#ifdef N64_INPUT_TEX1
vec4 quantizeTex1(vec4 c, int df)
{
	c = ((df & DRAW_FLAG_TEX1_4BIT) != 0) ? quantize4Bit(c) : c;
	c = ((df & DRAW_FLAG_TEX1_3BIT) != 0) ? quantize3Bit(c) : c;
	return ((df & DRAW_FLAG_TEX1_MONO) != 0) ? c.rrrr : c;
}
#endif
#endif // N64_QUANTIZE

// ── LOD ────────────────────────────────────────────────────────────────────────
#ifdef N64_LOD
float compute_lod_fraction(vec2 dx, vec2 dy)
{
	bool sharpen = texture_detail_mode == 1;
	bool clam    = texture_detail_mode == 0;
	vec2  dfd      = max(abs(dx), abs(dy));
	float max_dist = max(dfd.x, dfd.y);
	float mip_base = floor(log2(max(max_dist, 1e-8)));
	bool distant     = max_dist >= 16384.0;
	bool above_count = mip_base >= float(max(mip_count, 1));
	bool max_distant = distant || above_count;
	bool magnify     = max_dist < 1.0;
	float detail_frac   = max(prim_lod_min, max_dist) - float(sharpen);
	float mag_frac      = mix(float(max_distant), detail_frac, float(!clam));
	float dist_frac     = float(distant || (above_count && clam));
	float denom         = max(pow(2.0, max(mip_base, 0.0)), 1.0);
	float nc_frac       = max(max_dist / denom - 1.0, prim_lod_min);
	float nm_frac       = mix(dist_frac, nc_frac, float(!max_distant || !clam));
	float lod_frac      = mix(nm_frac, mag_frac, float(!distant && magnify));
	return clamp(use_texture_lod ? lod_frac : nc_frac, 0.0, 1.0);
}
#endif

// ── CC fetch ───────────────────────────────────────────────────────────────────
vec3 cc_fetchColor(
	in int  val,
	in vec4 shade,
	in vec4 comb,
	in vec4 t0,
	in vec4 t1,
	in vec4 prim,
	in vec4 env,
	in vec2 screen_pos,
	in float lod_frac,
	in float plf
#ifdef N64_CHROMA_KEY
	, in vec3 chroma_center
	, in vec3 chroma_scale
#endif
) {
	if      (val == CC_C_COMB ) return comb.rgb;
	else if (val == CC_C_TEX0 ) return t0.rgb;
#ifdef N64_INPUT_TEX1
	else if (val == CC_C_TEX1 ) return t1.rgb;
#endif
	else if (val == CC_C_PRIM ) return prim.rgb;
	else if (val == CC_C_SHADE) return shade.rgb;
#ifdef N64_INPUT_ENV
	else if (val == CC_C_ENV  ) return env.rgb;
#endif
#ifdef N64_INPUT_COMB_ALPHA
	else if (val == CC_C_COMB_ALPHA ) return comb.aaa;
#endif
#ifdef N64_INPUT_TEX_ALPHA
	else if (val == CC_C_TEX0_ALPHA) return t0.aaa;
#ifdef N64_INPUT_TEX1
	else if (val == CC_C_TEX1_ALPHA) return t1.aaa;
#endif
#endif
#ifdef N64_INPUT_PRIM_ALPHA
	else if (val == CC_C_PRIM_ALPHA) return prim.aaa;
	else if (val == CC_C_ENV_ALPHA ) return env.aaa;
#endif
#ifdef N64_INPUT_SHADE_ALPHA
	else if (val == CC_C_SHADE_ALPHA) return linearToGamma(shade.aaa);
#endif
#ifdef N64_LOD
	else if (val == CC_C_LOD_FRAC     ) return vec3(lod_frac);
	else if (val == CC_C_PRIM_LOD_FRAC) return vec3(plf);
#endif
#ifdef N64_INPUT_NOISE
	else if (val == CC_C_NOISE) return vec3(noise(screen_pos * 0.25));
#endif
#ifdef N64_CHROMA_KEY
	else if (val == CC_C_CHROMA_KEY_CENTER) return chroma_center;
	else if (val == CC_C_CHROMA_KEY_SCALE ) return chroma_scale;
#endif
	else if (val == CC_C_1) return vec3(1.0);
	return vec3(0.0);
}

float cc_fetchAlpha(
	in int  val,
	in vec4 shade,
	in vec4 comb,
	in vec4 t0,
	in vec4 t1,
	in vec4 prim,
	in vec4 env,
	in float lod_frac,
	in float plf
) {
	if      (val == CC_A_COMB ) return comb.a;
	else if (val == CC_A_TEX0 ) return t0.a;
#ifdef N64_INPUT_TEX1
	else if (val == CC_A_TEX1 ) return t1.a;
#endif
	else if (val == CC_A_PRIM ) return prim.a;
	else if (val == CC_A_SHADE) return shade.a;
#ifdef N64_INPUT_ALPHA_ENV
	else if (val == CC_A_ENV  ) return env.a;
#endif
#ifdef N64_LOD
	else if (val == CC_A_LOD_FRAC     ) return lod_frac;
	else if (val == CC_A_PRIM_LOD_FRAC) return plf;
#endif
	else if (val == CC_A_1) return 1.0;
	return 0.0;
}

// Macro hides the optional chroma key arguments at call sites.
#ifdef N64_CHROMA_KEY
#define CC_FETCH_COLOR(val, shade, comb, t0, t1, prim, env, pos, lf, plf) \
	cc_fetchColor(val, shade, comb, t0, t1, prim, env, pos, lf, plf, chroma_key_center, chroma_key_scale)
#else
#define CC_FETCH_COLOR(val, shade, comb, t0, t1, prim, env, pos, lf, plf) \
	cc_fetchColor(val, shade, comb, t0, t1, prim, env, pos, lf, plf)
#endif

// env passthrough (vec4(0) when ENV inputs are stripped)
#ifdef N64_INPUT_ENV
#define N64_ENV_COLOR build_material_env_color()
#else
#define N64_ENV_COLOR vec4(0.0)
#endif

vec4 cc_overflow(in vec4 v) { return mod(v + 0.5, 2.0) - 0.5; }
vec4 cc_clamp(in vec4 v)    { return clamp(v, 0.0, 1.0); }

// ── Vertex ─────────────────────────────────────────────────────────────────────
N64CombVertexData n64comb_vertex_data(
	vec3 normal_in, vec4 color_in, float shade_from_vertex_color,
	vec2 uv_in, mat4 view_matrix, mat3 model_normal_matrix)
{
	N64CombVertexData outv;
	vec4 mat_shift = build_material_shift();
	vec4 mat_low   = build_material_low();
	vec4 mat_high  = build_material_high();

#ifdef N64_TEX_GEN
	vec3 ns  = normalize(mat3(view_matrix) * (model_normal_matrix * normal_in));
	vec2 uvG = use_tex_gen ? (ns.xy * 0.5 + 0.5) : uv_in;
#else
	vec2 uvG = uv_in;
#endif

	outv.cc_shade                  = color_in;
	outv.cc_shade_from_vertex_color = shade_from_vertex_color;

#ifdef N64_ATLAS
	ivec2 sA = atlas_region_0.x > 0 ? atlas_region_0 : max(textureSize(Texture0, 0), ivec2(1));
#ifdef N64_INPUT_TEX1
	ivec2 sB = atlas_region_1.x > 0 ? atlas_region_1 : max(textureSize(Texture1, 0), ivec2(1));
#else
	ivec2 sB = ivec2(1);
#endif
#else
	ivec2 sA = max(textureSize(Texture0, 0), ivec2(1));
#ifdef N64_INPUT_TEX1
	ivec2 sB = max(textureSize(Texture1, 0), ivec2(1));
#else
	ivec2 sB = ivec2(1);
#endif
#endif

	vec4 sz    = vec4(vec2(sA), vec2(sB));
	vec4 uvl   = uvG.xyxy * sz.xyxy;
	uvl.yw     = sz.yw - uvl.yw - 1.0;
	uvl       *= mat_shift;
	uvl.yw     = sz.yw - uvl.yw - 1.0;
	uvl        = uvl - (mat_shift * 0.5) - mat_low;

	outv.uv       = uvl;
	outv.tileSize = abs(mat_high) - abs(mat_low);
	return outv;
}

// ── Fragment ───────────────────────────────────────────────────────────────────
vec4 n64comb_fragment(vec2 screen_uv)
{
	vec4 primColor = build_material_prim_color();
	vec4 envColor  = N64_ENV_COLOR;

	vec4 shade_raw = cc_shade;
#ifdef N64_VERTEX_COLOR_GAMMA
	if (cc_shade_from_vertex_color > 0.5)
		shade_raw = fromLinear(shade_raw);
#endif
	vec4 ccShade = clamp_shade_input ? clamp(shade_raw, 0.0, 1.0) : shade_raw;

	// UV — optional atlas seam zoom then optional scroll
	vec4 uv_s = uv;
#ifdef N64_ATLAS
	if (atlas_seam_zoom > 0.0) {
		float sz = atlas_seam_zoom;
		ivec2 rA = atlas_region_0.x > 0 ? atlas_region_0 : max(textureSize(Texture0, 0), ivec2(1));
#ifdef N64_INPUT_TEX1
		ivec2 rB = atlas_region_1.x > 0 ? atlas_region_1 : max(textureSize(Texture1, 0), ivec2(1));
#else
		ivec2 rB = ivec2(1);
#endif
		vec4 rgn = vec4(vec2(rA), vec2(rB));
		uv_s = mod(uv, rgn) * (1.0 - sz * 2.0) + rgn * sz;
	}
#endif
#ifdef N64_SCROLL
	uv_s.xy += Texture0_Scroll * TIME;
#ifdef N64_INPUT_TEX1
	uv_s.zw += Texture1_Scroll * TIME;
#endif
#endif

	// Sample
	vec4 texData0;
	vec4 texData1 = vec4(0.0); // stays zero if N64_INPUT_TEX1 not defined

#if defined(N64_FILTER_NEAREST)
	texData0 = sample_texA_nearest(Texture0, uv_s.xy);
#ifdef N64_INPUT_TEX1
	texData1 = sample_texB_nearest(Texture1, uv_s.zw);
#endif
#elif defined(N64_FILTER_BILINEAR)
	texData0 = sample_texA_bilinear(Texture0, uv_s.xy);
#ifdef N64_INPUT_TEX1
	texData1 = sample_texB_bilinear(Texture1, uv_s.zw);
#endif
#elif defined(N64_FILTER_3POINT)
	texData0 = sample_texA_3point(Texture0, uv_s.xy);
#ifdef N64_INPUT_TEX1
	texData1 = sample_texB_3point(Texture1, uv_s.zw);
#endif
#else // runtime
	if (filter_mode == 0) {
		texData0 = sample_texA_nearest(Texture0, uv_s.xy);
#ifdef N64_INPUT_TEX1
		texData1 = sample_texB_nearest(Texture1, uv_s.zw);
#endif
	} else if (filter_mode == 2) {
		texData0 = sample_texA_bilinear(Texture0, uv_s.xy);
#ifdef N64_INPUT_TEX1
		texData1 = sample_texB_bilinear(Texture1, uv_s.zw);
#endif
	} else {
		texData0 = sample_texA_3point(Texture0, uv_s.xy);
#ifdef N64_INPUT_TEX1
		texData1 = sample_texB_3point(Texture1, uv_s.zw);
#endif
	}
#endif

#ifdef N64_QUANTIZE
	int df = build_draw_flags();
	texData0 = quantizeTex0(texData0, df);
#ifdef N64_INPUT_TEX1
	texData1 = quantizeTex1(texData1, df);
#endif
#endif

	// LOD
	float lod_frac = 0.0;
	float plf      = 0.0;
#ifdef N64_LOD
	vec2 dx = abs(vec2(dFdx(uv.x), dFdy(uv.x)));
	vec2 dy = abs(vec2(dFdx(uv.y), dFdy(uv.y)));
	lod_frac = compute_lod_fraction(dx, dy);
	plf      = prim_lod_frac;
#endif

	vec2 screen_pos = vec2(screen_uv.x, 1.0 - screen_uv.y);

	// Cycle 0 index resolve
	ivec4 c0col = ivec4(
		cc_color_a_from_ui(cc0_color_a), cc_color_b_from_ui(cc0_color_b),
		cc_color_c_from_ui(cc0_color_c), cc_color_d_from_ui(cc0_color_d));
	ivec4 c0alp = ivec4(
		cc_alpha_abd_from_ui(cc0_alpha_a), cc_alpha_abd_from_ui(cc0_alpha_b),
		cc_alpha_c_from_ui(cc0_alpha_c),   cc_alpha_abd_from_ui(cc0_alpha_d));

	// Cycle 0 evaluate — ccValue starts as 0 (combined input = black before cycle 0)
	vec4 ccValue = vec4(0.0);
	vec4 s0[4];
	s0[0].rgb = CC_FETCH_COLOR(c0col.x, ccShade, ccValue, texData0, texData1, primColor, envColor, screen_pos, lod_frac, plf);
	s0[1].rgb = CC_FETCH_COLOR(c0col.y, ccShade, ccValue, texData0, texData1, primColor, envColor, screen_pos, lod_frac, plf);
	s0[2].rgb = CC_FETCH_COLOR(c0col.z, ccShade, ccValue, texData0, texData1, primColor, envColor, screen_pos, lod_frac, plf);
	s0[3].rgb = CC_FETCH_COLOR(c0col.w, ccShade, ccValue, texData0, texData1, primColor, envColor, screen_pos, lod_frac, plf);
	s0[0].a = cc_fetchAlpha(c0alp.x, ccShade, ccValue, texData0, texData1, primColor, envColor, lod_frac, plf);
	s0[1].a = cc_fetchAlpha(c0alp.y, ccShade, ccValue, texData0, texData1, primColor, envColor, lod_frac, plf);
	s0[2].a = cc_fetchAlpha(c0alp.z, ccShade, ccValue, texData0, texData1, primColor, envColor, lod_frac, plf);
	s0[3].a = cc_fetchAlpha(c0alp.w, ccShade, ccValue, texData0, texData1, primColor, envColor, lod_frac, plf);

	ccValue = (s0[0] - s0[1]) * s0[2] + s0[3];

#ifdef N64_TWO_CYCLE
	// Overflow only needed between cycles; final overflow applied once below.
	if (use_two_cycle) {
		ccValue = cc_overflow(ccValue);

		ivec4 c1col = ivec4(
			cc_color_a_from_ui(cc1_color_a), cc_color_b_from_ui(cc1_color_b),
			cc_color_c_from_ui(cc1_color_c), cc_color_d_from_ui(cc1_color_d));
		ivec4 c1alp = ivec4(
			cc_alpha_abd_from_ui(cc1_alpha_a), cc_alpha_abd_from_ui(cc1_alpha_b),
			cc_alpha_c_from_ui(cc1_alpha_c),   cc_alpha_abd_from_ui(cc1_alpha_d));

		vec4 s1[4];
		s1[0].rgb = CC_FETCH_COLOR(c1col.x, ccShade, ccValue, texData0, texData1, primColor, envColor, screen_pos, lod_frac, plf);
		s1[1].rgb = CC_FETCH_COLOR(c1col.y, ccShade, ccValue, texData0, texData1, primColor, envColor, screen_pos, lod_frac, plf);
		s1[2].rgb = CC_FETCH_COLOR(c1col.z, ccShade, ccValue, texData0, texData1, primColor, envColor, screen_pos, lod_frac, plf);
		s1[3].rgb = CC_FETCH_COLOR(c1col.w, ccShade, ccValue, texData0, texData1, primColor, envColor, screen_pos, lod_frac, plf);
		s1[0].a = cc_fetchAlpha(c1alp.x, ccShade, ccValue, texData0, texData1, primColor, envColor, lod_frac, plf);
		s1[1].a = cc_fetchAlpha(c1alp.y, ccShade, ccValue, texData0, texData1, primColor, envColor, lod_frac, plf);
		s1[2].a = cc_fetchAlpha(c1alp.z, ccShade, ccValue, texData0, texData1, primColor, envColor, lod_frac, plf);
		s1[3].a = cc_fetchAlpha(c1alp.w, ccShade, ccValue, texData0, texData1, primColor, envColor, lod_frac, plf);

		ccValue = (s1[0] - s1[1]) * s1[2] + s1[3];
	}
#endif // N64_TWO_CYCLE

	// Final overflow + optional clamp
	ccValue = cc_overflow(ccValue);
	if (clamp_combiner_output)
		ccValue = cc_clamp(ccValue);

	if (ccValue.a < alpha_clip)
		discard;

	return ccValue;
}

shader_type spatial;
render_mode unshaded, fog_disabled;

uniform sampler2D screen_texture : source_color, hint_screen_texture, repeat_disable, filter_nearest;
uniform vec2 viewport_size = vec2(320.0, 240.0);

// ── Pass 1 settings ──
group_uniforms Quantization;
uniform int bits_per_channel : hint_range(1, 8) = 5;
uniform bool dither_enabled = true;
/** 0 = Magic, 1 = Bayer, 2 = Random Threshold */
uniform int dither_mode : hint_range(0, 2) = 0;
uniform bool time_varying_noise = false;
uniform bool anti_dither_enabled = true;
uniform bool divot_enabled = true;
group_uniforms;

// ── Pass 2 settings ──
group_uniforms VI;
uniform bool vi_enabled = true;
uniform float vi_x_add = 1.0;
uniform float vi_x_start = 0.0;
uniform float gamma : hint_range(0.5, 3.0) = 1.3;
group_uniforms;

const int MAGIC[16] = int[16](
    0,6,1,7, 4,2,5,3, 3,5,2,4, 7,1,6,0
);
const int BAYER[16] = int[16](
    0,4,1,5, 4,0,5,1, 3,7,2,6, 7,3,6,2
);

int dither_value(int x, int y, int mode) {
    int idx = ((y & 3) << 2) | (x & 3);
    return mode == 0 ? MAGIC[idx] : BAYER[idx];
}

int hash_seed(int x, int y, int s) {
    int n = x * 1973 + y * 9277 + s * 26699;
    n = (n << 13) ^ n;
    return n * (n * n * 15731 + 789221) + 1376312589;
}

int median3(int a, int b, int c) {
    return max(min(a, b), min(max(a, b), c));
}

int dither_channel(int c, int m, int shift, int mask, int noise_mask, int clamp_thresh) {
    int rounded = (c & mask) + (1 << shift);
    rounded = c > clamp_thresh ? 255 : rounded;
    int replace = (m - (c & noise_mask)) >> 31;
    return c + ((rounded - c) & replace);
}

ivec3 sample_rgb8(vec2 uv) {
    vec3 rgb = texture(screen_texture, clamp(uv, vec2(0.0), vec2(1.0))).rgb;
    return ivec3(clamp(rgb, 0.0, 1.0) * 255.0 + 0.5);
}

ivec3 dithered_c8(vec2 base_uv, ivec2 off, ivec2 px,
                  vec2 px_size,
                  int shift, int mask, int noise_mask, int clamp_thresh) {
    ivec3 c8 = sample_rgb8(base_uv + vec2(off) * px_size);
    if (!dither_enabled) return c8;
    ivec2 spx = px + off;
    if (dither_mode < 2) {
        int m = dither_value(spx.x, spx.y, dither_mode);
        return ivec3(
            dither_channel(c8.r, m, shift, mask, noise_mask, clamp_thresh),
            dither_channel(c8.g, m, shift, mask, noise_mask, clamp_thresh),
            dither_channel(c8.b, m, shift, mask, noise_mask, clamp_thresh)
        );
    }
    int seed = time_varying_noise ? int(floor(TIME * 1000.0)) : 0;
    int hr = hash_seed(spx.x, spx.y, seed);        hr = (hr ^ (hr >> 16)) & noise_mask;
    int hg = hash_seed(spx.x, spx.y, seed + 9277);  hg = (hg ^ (hg >> 16)) & noise_mask;
    int hb = hash_seed(spx.x, spx.y, seed + 18554); hb = (hb ^ (hb >> 16)) & noise_mask;
    return ivec3(
        dither_channel(c8.r, hr, shift, mask, noise_mask, clamp_thresh),
        dither_channel(c8.g, hg, shift, mask, noise_mask, clamp_thresh),
        dither_channel(c8.b, hb, shift, mask, noise_mask, clamp_thresh)
    );
}

ivec3 anti_dither_reconstruct(vec2 base_uv, ivec2 tex_px,
                               vec2 px_size,
                               int shift, int mask, int noise_mask, int clamp_thresh,
                               ivec3 mid8) {
    ivec3 base_q = mid8 >> shift;
    ivec3 accum  = ivec3(0);
    const ivec2 OFFSETS[9] = ivec2[9](
        ivec2(-1,-1), ivec2(0,-1), ivec2(1,-1),
        ivec2(-1, 0), ivec2(0, 0), ivec2(1, 0),
        ivec2(-1, 1), ivec2(0, 1), ivec2(1, 1)
    );
    for (int i = 0; i < 9; i++) {
        ivec3 nb = (OFFSETS[i] == ivec2(0, 0))
            ? mid8
            : dithered_c8(base_uv, OFFSETS[i], tex_px, px_size,
                          shift, mask, noise_mask, clamp_thresh);
        accum += clamp((nb >> shift) - base_q, ivec3(-1), ivec3(1));
    }
    return clamp((mid8 & ivec3(mask)) + accum, ivec3(0), ivec3(255));
}

ivec3 compute_quantized_pixel(ivec2 px, vec2 px_size,
                               int shift, int mask, int noise_mask, int clamp_thresh) {
    vec2 base_uv = (vec2(px) + 0.5) * px_size;
    bool use_anti = dither_enabled && anti_dither_enabled && dither_mode != 2;

    ivec3 raw_mid = dithered_c8(base_uv, ivec2(0,0), px, px_size,
                                shift, mask, noise_mask, clamp_thresh);
    ivec3 c8_mid = use_anti
        ? anti_dither_reconstruct(base_uv, px, px_size,
                                  shift, mask, noise_mask, clamp_thresh, raw_mid)
        : ((raw_mid >> shift) << shift);

    if (divot_enabled) {
        ivec3 raw_l = dithered_c8(base_uv, ivec2(-1,0), px, px_size,
                                  shift, mask, noise_mask, clamp_thresh);
        ivec3 raw_r = dithered_c8(base_uv, ivec2( 1,0), px, px_size,
                                  shift, mask, noise_mask, clamp_thresh);
        ivec3 c8_left = use_anti
            ? anti_dither_reconstruct(base_uv, px + ivec2(-1,0), px_size,
                                      shift, mask, noise_mask, clamp_thresh, raw_l)
            : ((raw_l >> shift) << shift);
        ivec3 c8_right = use_anti
            ? anti_dither_reconstruct(base_uv, px + ivec2( 1,0), px_size,
                                      shift, mask, noise_mask, clamp_thresh, raw_r)
            : ((raw_r >> shift) << shift);
        c8_mid = ivec3(
            median3(c8_left.r, c8_mid.r, c8_right.r),
            median3(c8_left.g, c8_mid.g, c8_right.g),
            median3(c8_left.b, c8_mid.b, c8_right.b)
        );
    }
    return c8_mid;
}

void vertex() {
    POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
    int shift        = 8 - bits_per_channel;
    int mask         = 0xFF & ~((1 << shift) - 1);
    int noise_mask   = (1 << shift) - 1;
    int clamp_thresh = 255 - (1 << shift) + 1;

    vec2 px_size = 1.0 / viewport_size;

    // ── Derive integer pixel coords from SCREEN_UV + known viewport size ──
    ivec2 tex_px = ivec2(SCREEN_UV * viewport_size);
    ivec3 result;

    if (vi_enabled) {
        float x = SCREEN_UV.x * viewport_size.x * vi_x_add + vi_x_start;
        int x_base = int(floor(x));
        int x_frac = int(fract(x) * 32.0);

        int max_base = max(int(viewport_size.x) - 2, 0);
        x_base = clamp(x_base, 0, max_base);

        int y_px = tex_px.y;

        ivec3 c0 = compute_quantized_pixel(ivec2(x_base,     y_px), px_size,
                                            shift, mask, noise_mask, clamp_thresh);
        ivec3 c1 = compute_quantized_pixel(ivec2(x_base + 1, y_px), px_size,
                                            shift, mask, noise_mask, clamp_thresh);

        result = (c0 + (((c1 - c0) * x_frac + ivec3(16)) >> 5)) & ivec3(255);
    } else {
        result = compute_quantized_pixel(tex_px, px_size,
                                          shift, mask, noise_mask, clamp_thresh);
    }

    vec3 col = vec3(result) / 255.0;
    col = pow(max(col, vec3(0.0)), vec3(1.0 / gamma));

    ALBEDO = col;
}
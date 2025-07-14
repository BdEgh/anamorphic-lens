// Created by TheNosiriN
// https://www.shadertoy.com/view/wlcyzj

shader_type canvas_item;

uniform vec3 sun_color : source_color = vec3(0.643, 0.494, 0.867);
uniform vec2 sun_position = vec2(0.5, 0.5);
uniform float sun_intensity : hint_range(0.5, 10.0) = 1.0;
uniform float threshold : hint_range(0.0, 1.0) = 0.5;
uniform float intensity : hint_range(0.0, 1000.0) = 400.0;
uniform float stretch : hint_range(0.0, 2.0) = 0.5;
uniform float brightness : hint_range(0.0, 2.0) = 0.6;
uniform float alpha_multiplier : hint_range(0.0, 1.0) = 1.0;
uniform bool use_cheap_flare = false;

float getSun(vec2 uv) {
    return length(uv) < 0.009 ? 1.0 : 0.0;
}

vec3 lensflares(vec2 uv, vec2 pos) {
    vec2 main = uv - pos;
    vec2 uvd = uv * length(uv);

    float ang = atan(main.y, main.x);
    float dist = length(main);
    dist = pow(dist, 0.1);

    float f0 = 1.0 / (length(uv - pos) * 25.0 + 1.0);
    f0 = pow(f0, 2.0);
    f0 = f0 + f0 * (sin((ang + 1.0 / 18.0) * 12.0) * 0.1 + dist * 0.1 + 0.8);

    float f2 = max(1.0 / (1.0 + 32.0 * pow(length(uvd + 0.8 * pos), 2.0)), 0.0) * 0.25;
    float f22 = max(1.0 / (1.0 + 32.0 * pow(length(uvd + 0.85 * pos), 2.0)), 0.0) * 0.23;
    float f23 = max(1.0 / (1.0 + 32.0 * pow(length(uvd + 0.9 * pos), 2.0)), 0.0) * 0.21;

    vec2 uvx = mix(uv, uvd, -0.5);
    float f4 = max(0.01 - pow(length(uvx + 0.4 * pos), 2.4), 0.0) * 6.0;
    float f42 = max(0.01 - pow(length(uvx + 0.45 * pos), 2.4), 0.0) * 5.0;
    float f43 = max(0.01 - pow(length(uvx + 0.5 * pos), 2.4), 0.0) * 3.0;

    uvx = mix(uv, uvd, -0.4);
    float f5 = max(0.01 - pow(length(uvx + 0.2 * pos), 5.5), 0.0) * 2.0;
    float f52 = max(0.01 - pow(length(uvx + 0.4 * pos), 5.5), 0.0) * 2.0;
    float f53 = max(0.01 - pow(length(uvx + 0.6 * pos), 5.5), 0.0) * 2.0;

    uvx = mix(uv, uvd, -0.5);
    float f6 = max(0.01 - pow(length(uvx - 0.3 * pos), 1.6), 0.0) * 6.0;
    float f62 = max(0.01 - pow(length(uvx - 0.325 * pos), 1.6), 0.0) * 3.0;
    float f63 = max(0.01 - pow(length(uvx - 0.35 * pos), 1.6), 0.0) * 5.0;

    vec3 sunflare = vec3(f0);
    vec3 lensflare = vec3(f2 + f4 + f5 + f6, f22 + f42 + f52 + f62, f23 + f43 + f53 + f63);

    return (sunflare + lensflare) * sun_intensity;
}

vec3 anflares(vec2 uv, float threshold_in, float intensity_in, float stretch_in, float brightness_in) {
    float thresh = 1.0 - threshold_in;
    vec3 hdr = vec3(getSun(uv));
    hdr = vec3(floor(thresh + pow(hdr.r, 1.0)));

    float d = intensity_in;
    float c = intensity_in * stretch_in;

    for (float i = c; i > -1.0; i--) {
        float texL = getSun(uv + vec2(i / d, 0.0));
        float texR = getSun(uv - vec2(i / d, 0.0));
        hdr += floor(thresh + pow(max(texL, texR), 4.0)) * (1.0 - i / c);
    }

    return hdr * brightness_in;
}

vec3 anflares_simple(vec2 uv, float intensity_in, float stretch_in, float brightness_in) {
    vec2 mod_uv = uv;
    mod_uv.x *= 1.0 / (intensity_in * stretch_in);
    mod_uv.y *= 0.5;
    return vec3(smoothstep(0.009, 0.0, length(mod_uv))) * brightness_in;
}

void fragment() {
    vec2 uv = UV - 0.5;
    vec2 sun_pos = sun_position - 0.5;
    float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
    uv.x *= aspect;
    sun_pos.x *= aspect;

    vec3 col = vec3(0.0);

    vec3 flare = lensflares(uv * 1.5, sun_pos * 1.5);

    vec3 anflare;
    if (use_cheap_flare) {
        anflare = pow(anflares_simple(uv - sun_pos, intensity, stretch, brightness), vec3(4.0));
        anflare += smoothstep(0.0025, 1.0, anflare) * 10.0;
        anflare *= smoothstep(0.0, 1.0, anflare);
    } else {
        anflare = pow(anflares(uv - sun_pos, threshold, intensity, stretch, brightness), vec3(4.0));
    }

    vec3 sun = (flare + anflare) * sun_color * 2.0;
    col += sun;

    col *= alpha_multiplier;

    col = pow(col, vec3(1.0 / 2.2));

    float alpha = clamp(max(col.r, max(col.g, col.b)), 0.0, 1.0);
    COLOR = vec4(col, alpha);
}

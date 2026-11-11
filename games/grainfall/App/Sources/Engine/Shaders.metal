#include <metal_stdlib>
using namespace metal;

// Full-screen (viewport-sized) textured quad for the pixel grid. Spec §4.

struct VOut {
    float4 position [[position]];
    float2 uv;
};

vertex VOut grid_vertex(uint vid [[vertex_id]]) {
    // Triangle strip: 0 top-left, 1 top-right, 2 bottom-left, 3 bottom-right.
    float2 uv = float2((vid & 1) ? 1.0 : 0.0, (vid & 2) ? 1.0 : 0.0);
    VOut out;
    out.position = float4(uv.x * 2.0 - 1.0, 1.0 - uv.y * 2.0, 0.0, 1.0);
    out.uv = uv;
    return out;
}

fragment float4 grid_fragment(VOut in [[stage_in]],
                              texture2d<float> cells [[texture(0)]]) {
    constexpr sampler nearest(filter::nearest, address::clamp_to_edge);
    constexpr sampler smooth(filter::linear, address::clamp_to_edge);
    float3 c = cells.sample(nearest, in.uv).rgb;

    // Bloom: alpha carries emissive strength (lava, fire). Two rings of taps, a few cells out,
    // sampled bilinearly so the glow is soft while the pixels themselves stay crisp.
    float2 texel = 1.0 / float2(cells.get_width(), cells.get_height());
    float3 glow = float3(0.0);
    const int taps = 12;
    for (int i = 0; i < taps; i++) {
        float a = 6.2831853 * float(i) / float(taps);
        float2 dir = float2(cos(a), sin(a));
        float4 near = cells.sample(smooth, in.uv + dir * texel * 1.8);
        float4 far  = cells.sample(smooth, in.uv + dir * texel * 4.0);
        glow += near.rgb * near.a * 0.6 + far.rgb * far.a * 0.4;
    }
    glow /= float(taps);
    c += glow * 0.55;

    // Subtle vignette so the board reads as a lit stage.
    float2 d = in.uv - 0.5;
    float v = 1.0 - dot(d, d) * 0.45;
    return float4(min(c * v, float3(1.0)), 1.0);
}

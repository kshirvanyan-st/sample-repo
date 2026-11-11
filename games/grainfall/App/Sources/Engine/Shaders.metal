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
    float3 c = cells.sample(nearest, in.uv).rgb;
    // Subtle vignette so the board reads as a lit stage.
    float2 d = in.uv - 0.5;
    float v = 1.0 - dot(d, d) * 0.45;
    return float4(c * v, 1.0);
}

shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, depth_test_disabled, shadows_disabled;

uniform vec4 tint : source_color = vec4(1.0, 0.3, 0.3, 1.0);
uniform vec4 core_tint : source_color = vec4(1.0, 0.95, 0.9, 1.0);
uniform float master_opacity : hint_range(0.0, 1.0) = 0.40;

void fragment() {
    vec2 p = (UV - vec2(0.5)) * 2.0;
    float dist = length(p);
    if (dist > 1.0) {
        discard;
    }
    // Soft celestial glimmer mote
    float halo = exp(-dist * 2.8);
    float diamond = clamp(1.0 - (abs(p.x) + abs(p.y)) * 0.9, 0.0, 1.0);
    float soft_star = max(
        clamp(1.0 - abs(p.x) * 3.0, 0.0, 1.0) * clamp(1.0 - abs(p.y) * 0.7, 0.0, 1.0),
        clamp(1.0 - abs(p.y) * 3.0, 0.0, 1.0) * clamp(1.0 - abs(p.x) * 0.7, 0.0, 1.0)
    );
    float glow = halo * 0.40 + pow(diamond, 2.0) * 0.35 + soft_star * 0.25;
    
    vec3 col = mix(tint.rgb, core_tint.rgb, clamp(pow(diamond, 1.5) * 0.7 + halo * 0.3, 0.0, 1.0));
    float alpha = clamp(glow, 0.0, 1.0) * master_opacity * COLOR.a;
    if (alpha < 0.005) {
        discard;
    }
    ALBEDO = col;
    ALPHA = alpha;
}

shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, depth_test_disabled, shadows_disabled;

uniform vec4 color : source_color = vec4(1.0, 0.2, 0.25, 1.0);
uniform vec4 core_color : source_color = vec4(1.0, 0.9, 0.8, 1.0);
uniform float ring_radius : hint_range(0.0, 1.0) = 0.5;
uniform float ring_thickness : hint_range(0.0, 0.5) = 0.06;
uniform float core_glow_radius : hint_range(0.0, 1.0) = 0.22;
uniform float master_opacity : hint_range(0.0, 1.0) = 0.38;

void fragment() {
    vec2 p = (UV - vec2(0.5)) * 2.0;
    float dist = length(p);
    
    if (dist > 1.0) {
        discard;
    }
    
    // 1. Soft, diffused primary shockwave ring (soft light wave, zero hard vector edges)
    float ring_dist = abs(dist - ring_radius);
    float ring = exp(-pow(ring_dist / max(0.001, ring_thickness), 1.5));
    float outer_halo = exp(-pow(ring_dist / max(0.001, ring_thickness * 2.2), 1.4)) * 0.35;
    
    // 2. Soft, delicate core glow at center
    float core = exp(-pow(dist / max(0.001, core_glow_radius), 1.6)) * 0.45;
    
    // 3. Ethereal, gentle celestial glimmer flare at origin
    float star_flare = clamp(1.0 - (abs(p.x) + abs(p.y)) * 3.5, 0.0, 1.0) * 0.25 * clamp(1.0 - dist * 2.0, 0.0, 1.0);
    
    // 4. Subtle harmonic ripple
    float angle = atan(p.y, p.x);
    float shimmer = (0.5 + 0.5 * sin(angle * 8.0)) * 0.12 * ring;
    
    float total_wave = ring * 0.55 + outer_halo + shimmer;
    float total_core = core + star_flare;
    
    vec3 col = mix(color.rgb, core_color.rgb, clamp(total_core * 0.8 + total_wave * 0.35, 0.0, 1.0));
    float alpha = clamp(total_wave + total_core, 0.0, 1.0) * master_opacity * COLOR.a;
    
    if (alpha < 0.003) {
        discard;
    }
    
    ALBEDO = col;
    ALPHA = alpha;
}

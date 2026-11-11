shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, depth_test_disabled, shadows_disabled;

uniform float master_opacity : hint_range(0.0, 2.0) = 1.0;
uniform float bokeh_ring_power : hint_range(0.0, 2.0) = 0.65;
uniform float core_glow_power : hint_range(0.0, 2.0) = 0.75;

void fragment() {
	vec2 p = (UV - vec2(0.5)) * 2.0;
	float r = length(p);
	if (r > 1.0) {
		discard;
	}
	
	// 1. Soft optical bokeh disc with smooth edge falloff
	float disc = smoothstep(1.0, 0.45, r);
	
	// 2. Delicate bright optical perimeter ring (lens chromatic aberration on bokeh edge)
	float ring = exp(-pow((r - 0.78) / 0.14, 2.0)) * bokeh_ring_power;
	
	// 3. Warm luminous glowing core
	float core = exp(-pow(r / 0.36, 2.0)) * core_glow_power;
	
	// 4. Subtle center stardust sparkle
	float sparkle = max(
		clamp(1.0 - abs(p.x) * 4.5, 0.0, 1.0) * clamp(1.0 - abs(p.y) * 1.6, 0.0, 1.0),
		clamp(1.0 - abs(p.y) * 4.5, 0.0, 1.0) * clamp(1.0 - abs(p.x) * 1.6, 0.0, 1.0)
	) * clamp(1.0 - r * 2.2, 0.0, 1.0) * 0.30;
	
	float total_shape = disc * 0.35 + ring + core + sparkle;
	
	// Warm sunlit color shift: golden core, warm amber edge
	vec3 col = mix(COLOR.rgb, vec3(1.0, 0.96, 0.88), clamp(core * 0.85, 0.0, 1.0));
	
	float alpha = clamp(total_shape, 0.0, 1.0) * COLOR.a * master_opacity;
	if (alpha < 0.003) {
		discard;
	}
	
	ALBEDO = col;
	ALPHA = alpha;
}

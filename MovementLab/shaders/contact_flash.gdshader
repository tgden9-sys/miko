shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;

uniform float progress = 0.0;
uniform vec3 flash_color = vec3(0.88, 0.92, 0.96);

void fragment() {
	vec2 p = (UV - vec2(0.5, 0.5)) * 2.0;
	float dist = length(p);
	
	// Fast snappy pop
	float pop_t = clamp(progress / 0.15, 0.0, 1.0);
	float grow_t = 0.40 + 0.60 * pow(pop_t, 0.40) + progress * 0.20;
	
	// Primary 4-point comic astroid star
	float d_star = (sqrt(abs(p.x)) + sqrt(abs(p.y))) / grow_t;
	float star_main = 1.0 - smoothstep(0.92, 1.02, d_star);
	
	// Solid pure white core
	float core_mask = 1.0 - smoothstep(0.38, 0.48, d_star);
	
	// Diagonal slash cut line
	float slash_dist = abs(p.x * 0.819 - p.y * 0.574);
	float slash_len = 1.0 - smoothstep(0.3, 0.95, dist);
	float slash_mask = (1.0 - smoothstep(0.015, 0.07, slash_dist)) * slash_len;
	
	// Subtle expanding shockwave ripple ring
	float ring_radius = 0.15 + progress * 0.70;
	float ring_dist = abs(dist - ring_radius);
	float ring_mask = (1.0 - smoothstep(0.01, 0.06, ring_dist)) * smoothstep(0.05, 0.18, progress);
	
	// Muted, tasteful cel color scheme: white core + subtle tint
	vec3 col = mix(flash_color, vec3(1.0, 1.0, 1.0), clamp(core_mask + slash_mask * 0.8, 0.0, 1.0));
	
	// 50% restrained alpha
	float shape_mask = clamp(star_main * 0.85 + slash_mask * 0.75 + ring_mask * 0.65, 0.0, 1.0);
	float fade = 1.0 - smoothstep(0.35, 1.0, progress);
	float alpha = shape_mask * fade * 0.85;
	
	ALBEDO = col;
	ALPHA = alpha;
}

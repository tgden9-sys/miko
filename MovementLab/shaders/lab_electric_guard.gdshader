shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, fog_disabled;

uniform float strength : hint_range(0.0, 1.0) = 0.0;
uniform float direction_sign = 1.0;
uniform float hit_age = 1.0;
uniform float impact_height = 0.0;
uniform float cells = 3.0;

float contour(vec2 p) {
	float side = max(p.x - 0.94, -p.x - 0.8);
	float chamfer = max(p.x + abs(p.y) * 0.94 - 1.40, -p.x + abs(p.y) * 0.53 - 1.10);
	return max(abs(p.y) - 0.90, max(side, chamfer * 0.79));
}

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	p.x *= direction_sign;
	float y = -p.y / 0.83;
	float bend = 0.10 - 0.18 * y * y + 0.10 * y;
	vec2 face = vec2((p.x - bend) / 0.52, y);
	float shape = contour(face);
	float aa = max(fwidth(shape) * 0.66, 0.008);
	float mask = 1.0 - smoothstep(-aa, aa, shape);
	float front = smoothstep(-0.52, 0.49, face.x);
	float border = 1.0 - smoothstep(0.010, 0.037 + aa, abs(shape + 0.019));
	float bevel = (1.0 - smoothstep(0.009, 0.025 + aa, abs(shape + 0.106))) * front;
	float haze = exp(-abs(shape) * 18.0) * (0.075 + 0.13 * front);
	float facet = smoothstep(-0.24, -0.08, face.x + face.y * 0.26);
	float sweep = exp(-pow((face.y - face.x * 0.32 - sin(TIME * 0.78) * 0.68) * 9.0, 2.0));
	float glass = mask * (0.095 + 0.082 * facet + 0.045 * sweep);

	// Charge travels along the forward bevel. The hit starts where the bolt struck.
	float current = pow(0.5 + 0.5 * sin(face.y * 17.2 - TIME * 4.2), 8.0) * bevel;
	vec2 delta = (face - vec2(0.80, impact_height)) * vec2(1.0, 1.24);
	float distance_to_hit = length(delta);
	float flash_time = 1.0 - smoothstep(0.014, 0.17, hit_age);
	float hit_core = exp(-distance_to_hit * 13.0) * flash_time;
	float shock = exp(-pow((distance_to_hit - hit_age * 6.2) * 15.0, 2.0));
	float wave = shock * mask * (1.0 - smoothstep(0.045, 0.29, hit_age));
	float angle = atan(delta.y, delta.x);
	float jets = pow(0.5 + 0.5 * sin(angle * 5.0 + 1.3), 20.0) * exp(-distance_to_hit * 3.6);
	jets *= flash_time * smoothstep(0.02, 0.096, distance_to_hit);
	float overload = (1.0 - step(0.5, cells)) * flash_time;
	float rim_flash = border * exp(-abs(face.y - impact_height) * 2.3) * flash_time;

	float nodes = 0.0;
	float extinguished = 0.0;
	for (int i = 0; i < 3; i++) {
		float row = float(i - 1) * 0.36;
		vec2 offset = face - vec2(0.71, row);
		offset.x += offset.y * (row * 0.48);
		float bar = max(abs(offset.x) - .073, abs(offset.y) - .035);
		float cell = 1.0 - smoothstep(-0.009, max(aa, 0.02), bar);
		float lit = step(float(i) + 0.5, cells);
		nodes += cell * lit;
		extinguished += cell * (1.0 - lit);
	}
	vec3 glass_color = mix(vec3(0.055, 0.32, 0.43), vec3(0.12, 0.66, 0.77), facet);
	vec3 edge_color = mix(vec3(0.23, 0.75, 0.83), vec3(0.80, 1.0, 0.98), front);
	float highlights = clamp(border * 0.74 + bevel * 0.35 + current * 0.42 + nodes, 0.0, 1.0);
	vec3 surface = mix(glass_color, edge_color, highlights);
	surface = mix(surface, vec3(.10, .32, .39), extinguished * 0.6);
	ALBEDO = mix(surface, vec3(.92, 1.0, .98), clamp(hit_core + wave * .75 + rim_flash + jets + overload * .36, 0.0, 1.0));
	ALPHA = clamp(glass + border * (0.31 + 0.44 * front) + bevel * 0.33 + current * 0.32 + haze + nodes * 0.88 + extinguished * 0.40 + wave * 0.5 + hit_core + jets * 0.65 + rim_flash * 0.5, 0.0, 1.0) * strength;
}

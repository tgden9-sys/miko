shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, fog_disabled;

uniform float strength : hint_range(0.0, 1.0) = 0.0;
uniform float direction_sign = 1.0;
uniform float hit_age = 1.0;
uniform float impact_height = 0.0;
uniform float impact_side = 1.0;
uniform float cells = 3.0;

// Regular hexagonal tiling (pointy-topped)
// Period: (sqrt(3), 1.0) with offset (sqrt(3)/2, 0.5)
vec4 hex_tiling(vec2 p) {
	vec2 s = vec2(1.7320508, 1.0);
	vec2 h = vec2(0.8660254, 0.5);
	vec2 a = mod(p, s) - h;
	vec2 b = mod(p - h, s) - h;
	vec2 gv = dot(a, a) < dot(b, b) ? a : b;
	vec2 id = p - gv;
	return vec4(gv.x, gv.y, id.x, id.y);
}

// Exact distance from center of pointy-topped hexagon to edge (edge at d = 0.5)
float hex_distance(vec2 p) {
	p = abs(p);
	return max(p.y, 0.8660254 * p.x + 0.5 * p.y);
}

void fragment() {
	// Delicate, silky Fresnel rim glow
	float ndotv = abs(dot(NORMAL, VIEW));
	float fresnel = pow(1.0 - ndotv, 3.2);
	float rim = pow(1.0 - ndotv, 1.8) * 0.18;

	// Seamless hex grid wrapping across UV
	vec2 grid_p = vec2(UV.x * 17.3205, UV.y * 11.5);
	vec4 hex_data = hex_tiling(grid_p);
	vec2 local_p = hex_data.xy;
	vec2 cell_id = hex_data.zw;

	float d = hex_distance(local_p);

	// Thin, razor-sharp hex wireframe lines
	// d goes from 0.0 (center) to 0.50 (outer edge)
	float border = smoothstep(0.44, 0.485, d);
	float core_wire = smoothstep(0.47, 0.495, d);
	float cell_interior = 1.0 - smoothstep(0.38, 0.45, d);

	// Very subtle kinetic breathing shimmer per cell
	float cell_phase = sin(TIME * 2.0 + cell_id.x * 1.8 + cell_id.y * 2.4) * 0.5 + 0.5;
	float kinetic_glass = cell_interior * (0.015 + 0.025 * cell_phase);

	// Thin, elegant charge indicator bands (3 battery cells)
	float cell_band = 0.0;
	float dim_band = 0.0;
	for (int i = 0; i < 3; i++) {
		float band_y = 0.42 + float(i) * 0.075;
		float dist_y = abs(UV.y - band_y);
		float ring = exp(-dist_y * 110.0);
		ring *= (0.8 + 0.2 * sin(UV.x * 17.3205 * 0.5 + TIME * 3.0));
		if (float(i) + 0.5 < cells) {
			cell_band += ring * 0.35;
		} else {
			dim_band += ring * 0.08;
		}
	}

	// Dynamic impact shockwave
	float flash_time = 1.0 - smoothstep(0.0, 0.35, hit_age);
	vec2 impact_uv = vec2(0.5 + impact_side * 0.25, 0.5 - impact_height * 0.45);
	float dist_to_hit = length((UV - impact_uv) * vec2(1.0, 1.4));
	float shock_radius = hit_age * 4.2;
	float shock = exp(-pow((dist_to_hit - shock_radius) * 14.0, 2.0)) * flash_time;
	float hit_core = exp(-dist_to_hit * 8.0) * flash_time * 1.4;
	float impact_hex_boost = border * exp(-dist_to_hit * 3.5) * flash_time * 1.2;

	// Palette: Electric Cyan, Deep Azure, Crisp Core White
	vec3 deep_azure = vec3(0.02, 0.38, 0.88);
	vec3 electric_cyan = vec3(0.14, 0.90, 1.0);
	vec3 core_white = vec3(0.92, 0.99, 1.0);

	// Color composition
	vec3 col = mix(deep_azure, electric_cyan, fresnel * 0.8 + kinetic_glass * 4.0);
	col = mix(col, electric_cyan, border * 0.9);
	col = mix(col, core_white, clamp(core_wire * 0.85 + hit_core + shock * 0.6 + cell_band * 0.5 + impact_hex_boost, 0.0, 1.0));

	// Halved opacity: ultra-delicate, clear, and subtle
	float alpha = (fresnel * 0.38 + rim * 0.15 + kinetic_glass
	            + border * 0.32 + core_wire * 0.25
	            + cell_band + dim_band
	            + hit_core * 1.0 + shock * 0.5 + impact_hex_boost) * 0.5;

	ALBEDO = col;
	ALPHA = clamp(alpha, 0.0, 1.0) * strength;
}

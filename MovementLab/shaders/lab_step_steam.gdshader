shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 steam_color : source_color = vec4(0.88, 0.93, 0.95, 1.0);
uniform float density_multiplier : hint_range(0.5, 3.0) = 1.6;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash(cell), hash(cell + vec2(1.0, 0.0)), f.x),
		mix(hash(cell + vec2(0.0, 1.0)), hash(cell + vec2(1.0, 1.0)), f.x),
		f.y
	);
}

void fragment() {
	vec2 p = vec2(UV.x, 1.0 - UV.y);
	float age = TIME * 0.8;
	float travel = max(p.x - 0.15, 0.0);
	
	// Expanding rolling plume
	float center = 0.25 + travel * 0.22 + sin(p.x * 9.0 - age * 1.5) * 0.06;
	float thickness = 0.22 + travel * 0.45;
	float plume = exp(-pow(abs(p.y - center) / thickness, 1.4));
	
	// Soft horizontal expansion and fade out
	float spread = smoothstep(0.08, 0.24, p.x) * (1.0 - smoothstep(0.65, 0.98, p.x));
	
	// Turbulence billow
	vec2 flow = p * vec2(6.0, 3.5) - vec2(age * 0.95, age * 0.25);
	float billow = noise(flow) * 0.65 + noise(flow * 2.4 + 3.1) * 0.35;
	
	float alpha_val = plume * spread * billow * density_multiplier;
	alpha_val = clamp(alpha_val, 0.0, 0.85);
	
	ALBEDO = steam_color.rgb;
	ALPHA = alpha_val * steam_color.a;
}

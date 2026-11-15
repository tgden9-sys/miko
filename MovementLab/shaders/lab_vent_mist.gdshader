shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

varying float vent_phase;

void vertex() {
	vent_phase = fract(MODEL_MATRIX[3].x * 0.73);
}

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
	vec2 point = vec2(UV.x, 1.0 - UV.y);
	float age = TIME + vent_phase * 19.0;
	float travel = max(point.x - 0.235, 0.0);
	float center = 0.16 + travel * 0.19 + sin(point.x * 13.0 - age) * 0.05;
	float thickness = 0.11 + travel * 0.31;
	float plume = exp(-pow(abs(point.y - center) / thickness, 1.5));
	float spread = smoothstep(0.17, 0.30, point.x) * (1.0 - smoothstep(0.52, 1.0, point.x));
	vec2 flow = point * vec2(9.0, 4.0) - vec2(age * 1.02, age * 0.13);
	float density = noise(flow) * 0.68 + noise(flow * 2.28 + 4.0) * 0.32;
	float draft = smoothstep(0.14, 0.80, density);
	float release = fract(age * 0.16 - travel * 0.83);
	float puff = smoothstep(0.04, 0.23, release) * (1.0 - smoothstep(0.38, 0.81, release));
	float nozzle_distance = (point.x - 0.235) * 25.0;
	float nozzle = exp(-nozzle_distance * nozzle_distance - point.y * 6.0);
	float soft_floor = smoothstep(0.0, 0.09, point.y);
	ALBEDO = vec3(0.53, 0.61, 0.61);
	ALPHA = soft_floor * (plume * spread * (0.14 + draft * 0.42 + puff * 0.16) + nozzle * (0.17 + density * 0.20));
}

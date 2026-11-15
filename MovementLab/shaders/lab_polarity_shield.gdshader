shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never, shadows_disabled;

uniform vec4 pole_color : source_color = vec4(1.0, 0.23, 0.19, 1.0);
uniform float field_strength : hint_range(0.0, 1.0) = 1.0;

float hash(float seed) {
	return fract(sin(seed * 127.1 + 17.7) * 43758.5453);
}

float angular_noise(float position, float seed) {
	float cell = floor(position);
	return mix(hash(seed + cell), hash(seed + cell + 1.0), fract(position)) - 0.5;
}

float arc_path(float x, float height, float seed) {
	float anchored = sin(x * PI);
	return height + anchored * (angular_noise(x * 5.0 + TIME * 2.2, seed + 11.0) * 0.35
		+ angular_noise(x * 16.0 - TIME * 4.0, seed + 29.0) * 0.12
		+ angular_noise(x * 34.0 + TIME * 8.2, seed + 56.0) * 0.033);
}

void fragment() {
	vec2 uv = UV;
	float seed = 23.0;
	float main_arc = arc_path(uv.x, 0.53, seed);
	float distance_to_arc = abs(uv.y - main_arc);
	float secondary = abs(uv.y - arc_path(uv.x, 0.23, seed + 173.0));
	float upper = abs(uv.y - arc_path(uv.x, 0.78, seed + 311.0));
	float split = main_arc + (uv.x - 0.47) * 0.47
		+ angular_noise(uv.x * 24.0, seed + 240.0) * 0.064;
	float branch = abs(uv.y - split);
	float branch_fade = smoothstep(0.41, 0.5, uv.x) * (1.0 - smoothstep(0.88, 1.0, uv.x));
	float core = max(exp(-distance_to_arc * 176.0), exp(-secondary * 225.0) * 0.66);
	core = max(core, exp(-branch * 240.0) * branch_fade * 0.74);
	core = max(core, exp(-upper * 220.0) * 0.70);
	float halo = exp(-distance_to_arc * 33.0) * 0.48
		+ exp(-secondary * 37.0) * 0.27 + exp(-upper * 37.0) * 0.30;
	float electrodes = exp(-min(uv.x, 1.0 - uv.x) * 18.0);
	float breath = 0.87 + 0.07 * sin(TIME * 31.0) + 0.05 * sin(TIME * 17.0);
	float floor_fade = smoothstep(0.0, 0.08, uv.y);
	ALBEDO = mix(pole_color.rgb, vec3(1.0, 0.94, 0.91), core * 0.92);
	float border = smoothstep(0.0, 0.018, min(uv.x, 1.0 - uv.x));
	ALPHA = clamp((0.028 + electrodes * 0.12 + halo + core * 0.92) * breath * floor_fade * border * field_strength, 0.0, 1.0);
}

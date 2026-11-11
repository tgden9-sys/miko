shader_type spatial;
render_mode unshaded;

uniform vec4 paint : source_color = vec4(0.72, 0.51, 0.31, 1.0);
uniform bool tread = false;
uniform vec4 worn_steel : source_color = vec4(0.36, 0.36, 0.33, 1.0);
uniform vec4 oxidation : source_color = vec4(0.40, 0.28, 0.19, 1.0);

varying vec3 world_normal;
varying vec3 world_position;

float hash_point(vec3 point) {
	point = fract(point * 0.1031);
	point += dot(point, point.yzx + 33.33);
	return fract((point.x + point.y) * point.z);
}

float wear_noise(vec3 point) {
	vec3 cell = floor(point);
	vec3 blend = fract(point);
	blend = blend * blend * (3.0 - 2.0 * blend);
	float a = mix(hash_point(cell), hash_point(cell + vec3(1, 0, 0)), blend.x);
	float b = mix(hash_point(cell + vec3(0, 1, 0)), hash_point(cell + vec3(1, 1, 0)), blend.x);
	float c = mix(hash_point(cell + vec3(0, 0, 1)), hash_point(cell + vec3(1, 0, 1)), blend.x);
	float d = mix(hash_point(cell + vec3(0, 1, 1)), hash_point(cell + vec3(1, 1, 1)), blend.x);
	return mix(mix(a, b, blend.y), mix(c, d, blend.y), blend.z);
}

void vertex() {
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 normal = normalize(world_normal);
	vec3 point = world_position + vec3(13.7, 4.9, 8.3);
	float footprint = max(length(dFdx(world_position)), length(dFdy(world_position)));

	// Use the same metre scale on full-height rails, returns and tower meshes.
	float faded = wear_noise(point * vec3(19.0, 6.0, 19.0));
	float grime = (1.0 - smoothstep(0.04, 0.55, world_position.y)) * 0.19;
	vec3 finish = mix(paint.rgb, oxidation.rgb, 0.09 + grime + faded * 0.24);

	// Chipped patches leave darker steel with a soft oxidised rim.
	float chip_pattern = wear_noise(point * vec3(44.0, 26.0, 44.0)) * 0.76 + faded * 0.24;
	float chip = smoothstep(0.63, 0.77, chip_pattern);
	float rim = smoothstep(0.55, 0.69, chip_pattern);
	float chip_detail = 1.0 - smoothstep(0.018, 0.056, footprint);
	finish = mix(finish, oxidation.rgb, rim * 0.34 * chip_detail);
	finish = mix(finish, worn_steel.rgb, chip * 0.85 * chip_detail);

	// Rub marks follow the rails, with softer wear across the tops of rungs.
	vec3 scuff_scale = tread ? vec3(13.0, 64.0, 13.0) : vec3(64.0, 9.0, 64.0);
	float scuff = smoothstep(0.58, 0.83, wear_noise(point * scuff_scale));
	float contact = tread ? smoothstep(0.05, 0.95, normal.y) : 0.54;
	float scuff_detail = 1.0 - smoothstep(0.010, 0.035, footprint);
	vec3 rubbed = tread ? mix(paint.rgb, worn_steel.rgb, 0.22) * 1.18 : worn_steel.rgb;
	finish = mix(finish, rubbed, scuff * contact * 0.64 * scuff_detail);

	float facing = dot(normal, normalize(vec3(0.28, 0.62, 0.73)));
	float tone = mix(0.68, 0.86, smoothstep(0.10, 0.28, facing));
	tone = mix(tone, 1.0, smoothstep(0.51, 0.72, facing));
	ALBEDO = finish * tone;
}

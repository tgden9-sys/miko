shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

uniform float power : hint_range(0.0, 1.0) = 1.0;

float hash(float seed) {
	return fract(sin(seed * 127.1 + 13.3) * 43758.5453);
}

float field_noise(float p, float seed) {
	float cell = floor(p);
	float blend = smoothstep(0.0, 1.0, fract(p));
	return mix(hash(cell + seed), hash(cell + seed + 1.0), blend);
}

float gaussian(float distance) {
	return exp(-distance * distance);
}

float streak(vec2 p, vec2 from, vec2 to, float width) {
	vec2 path = to - from;
	float along = clamp(dot(p - from, path) / max(dot(path, path), .00001), 0.0, 1.0);
	return 1.0 - smoothstep(width * .35, width, length(p - from - path * along));
}

float discharge_sparks(vec2 point, float time, float seed) {
	float sparks = 0.0;
	for (int i = 0; i < 8; i++) {
		float index = float(i) + seed;
		float cycle = time * (1.9 + hash(index) * 1.7) + hash(index + 8.0);
		float life = fract(cycle);
		float id = 19.0 * index + floor(cycle);
		vec2 velocity = vec2((hash(id + 1.0) - .5) * 1.16, .19 + hash(id + 2.0) * .49);
		vec2 head = velocity * life + vec2(0.0, -.105 * life * life);
		vec2 tail = head - velocity * (.055 + hash(id + 3.0) * .13);
		sparks += streak(point, head, tail, .008 + .008 * hash(id + 4.0))
			* (1.0 - smoothstep(.30, 1.0, life)) * (.38 + hash(id + 5.0) * .52);
	}
	return sparks;
}

void fragment() {
	if (power <= .001) {
		discard;
	}
	float x = (UV.x - .5) * 1.36;
	float y = UV.y * 4.97;
	float end_distance = min(y, 4.97 - y);
	float azimuth = TIME * 13.0;
	float aa = max(fwidth(x), .008);
	float core = 1.0 - smoothstep(.010, .021 + aa, abs(x));
	float traveling_pulse = gaussian((fract(y * .47 - TIME * 2.2) - .5) * 6.9);
	float ionized_air = field_noise(y * 6.95 + TIME * 6.5, 4.0);
	float halo_width = .072 + ionized_air * .036 + traveling_pulse * .039;
	float halo = gaussian(x / halo_width) * (.31 + ionized_air * .21 + traveling_pulse * .24);
	float corona = gaussian(x / .248) * (.048 + traveling_pulse * .076);

	// Short filaments jump away from the hot center and break up along the beam.
	float fray_noise = field_noise(y * 14.75 - TIME * 10.0, 77.0);
	float drift = (.043 + fray_noise * .092) * sin(y * 11.7 - azimuth);
	float filament = 1.0 - smoothstep(.006, .014 + aa, abs(x - drift));
	filament *= smoothstep(.59, .86, field_noise(y * 5.1 + TIME * 9.4, 15.0));

	float endpoint_flare = gaussian(x / .13) * exp(-end_distance * 11.5) * .58;
	float sparks = 0.0;
	if (end_distance < .72) {
		float seed = UV.y < .5 ? 7.0 : 31.0;
		sparks = discharge_sparks(vec2(x,end_distance), TIME, seed);
	}
	vec3 hot = vec3(1.0,.91,.94) * (core * (.93 + .08 * traveling_pulse) + sparks * .74);
	vec3 plasma = vec3(1.0,.054,.20) * (halo + corona + endpoint_flare);
	vec3 electrical = vec3(1.0,.36,.61) * (filament * .55 + sparks * .31);
	ALBEDO = hot + plasma + electrical;
	ALPHA = power * smoothstep(.0,.014,min(UV.x,1.0-UV.x));
}

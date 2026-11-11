shader_type spatial;
render_mode unshaded, blend_mix, shadows_disabled, depth_draw_never;

uniform float lock_amount = 0.0;

float clipped_plate(vec2 p, vec2 half_size, float bevel) {
	vec2 edge = abs(p) - half_size;
	return max(max(edge.x, edge.y), (edge.x + edge.y + bevel) * .7071);
}

void fragment() {
	vec2 p = (UV - .5) * vec2(1.52, 1.02);
	vec2 mirror = abs(p);
	float aa = max(length(fwidth(p)) * .55, .004);
	float rim = clipped_plate(p, vec2(.46, .245), .10);
	float cover = 1.0 - smoothstep(-aa, aa, rim);
	float bevel = smoothstep(-.038 - aa, -.038 + aa, rim);
	float shadow = (1.0 - smoothstep(0.0, .075, rim)) * .42;
	vec3 plate = mix(vec3(.075, .104, .119), vec3(.25, .35, .36), bevel);
	float bay = 1.0 - smoothstep(-aa, aa, clipped_plate(p, vec2(.25, .163), .072));
	plate = mix(plate, vec3(.033, .058, .066), bay);
	float fastener = 1.0 - smoothstep(.022 - aa, .022 + aa, length(mirror - vec2(.348, .146)));
	plate = mix(plate, vec3(.46, .53, .52), fastener);

	float coil_r = length(p * vec2(1.0, 1.4));
	float coil = 1.0 - smoothstep(.014 - aa, .014 + aa, abs(coil_r - .13));
	float terminal = 1.0 - smoothstep(.036 - aa, .036 + aa, coil_r);
	float trace = (1.0 - smoothstep(.024 - aa, .024 + aa, mirror.y)) *
		smoothstep(.13, .16, mirror.x) * (1.0 - smoothstep(.37 - aa, .37 + aa, mirror.x));
	float pulse = .69 + .10 * sin(TIME * 3.2 - mirror.x * 16.0) + lock_amount * .21;
	float light_mask = clamp(coil * .80 + terminal + trace * pulse, 0.0, 1.0);
	plate = mix(plate, mix(vec3(.13, .69, .60), vec3(.67, 1.0, .91), lock_amount), light_mask);

	float wave = 1.0 - smoothstep(.015, .038 + aa, abs(coil_r - mix(.35, .64, lock_amount)));
	wave *= smoothstep(.3, .57, lock_amount) * (1.0 - smoothstep(.75, 1.0, lock_amount));
	float ground_light = exp(-coil_r * 7.0) * (.11 + lock_amount * .29) + wave * .48;
	float surround = max(shadow, ground_light);
	ALBEDO = mix(vec3(.045, .60, .53) * ground_light / max(surround, .001), plate, cover);
	ALPHA = max(cover, surround);
}

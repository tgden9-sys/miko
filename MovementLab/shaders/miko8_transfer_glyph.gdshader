shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, shadows_disabled, depth_draw_never;

uniform float lock_amount = 0.0;

float stroke(float distance_to_line, float width, float aa) {
	return 1.0 - smoothstep(width - aa, width + aa, abs(distance_to_line));
}

void fragment() {
	vec2 p = (UV - .5) * 2.0;
	float r = length(p);
	float aa = max(fwidth(r) * .65, .004);
	float angle = atan(p.y, p.x + .00001);
	float drift = sin(TIME * 1.5) * .26 * (1.0 - lock_amount);
	float iris = mix(.77, .69, lock_amount);

	// Three alignment jaws settle around the relay mark when the connection locks.
	float sector = abs(fract((angle + drift) / TAU * 3.0 + .25) - .5);
	float jaw = 1.0 - smoothstep(.27, .31, sector);
	float ring = stroke(r - iris, .024, aa) * jaw;
	float ticks = stroke(r - (.85 - lock_amount * .05), .028, aa) *
		(1.0 - smoothstep(.19, .38, abs(sin((angle + drift) * 9.0))));
	float node = 0.0;
	for (int i = 0; i < 3; i++) {
		float bearing = float(i) * TAU / 3.0 + PI * .5 - drift;
		vec2 at = vec2(cos(bearing), sin(bearing)) * iris;
		node = max(node, 1.0 - smoothstep(.045, .045 + aa, length(p - at)));
	}

	// Split the central diamond into two linked chevrons with a bright contact pin.
	float diamond = abs(p.x) + abs(p.y) - .37;
	float split = smoothstep(.042, .085, abs(p.x));
	float mark = stroke(diamond, .035, aa) * split;
	float pin = 1.0 - smoothstep(.047, .047 + aa, r);
	float echo = stroke(r - mix(.38, .92, lock_amount), .012, aa) *
		smoothstep(.35, .56, lock_amount) * (1.0 - smoothstep(.75, 1.0, lock_amount));
	float core = clamp(max(max(mark, pin), node) + ring * .78 + ticks * .46 + echo * .68, 0.0, 1.0);
	float halo = exp(-abs(r - iris) * 15.0) * .21 + exp(-r * r * 5.5) * .34;
	float backing = (1.0 - smoothstep(.58, .78, r)) * .28;
	float idle_pulse = mix(.83 + .17 * sin(TIME * 2.3), 1.0, lock_amount);

	vec3 ink = mix(vec3(.018, .14, .17), vec3(.04, .69, .68), halo + lock_amount * .12);
	vec3 light = mix(vec3(.32, .91, .84), vec3(.89, 1.0, .97), lock_amount);
	ALBEDO = mix(ink, light, core);
	ALPHA = clamp(backing + halo * (.42 + .38 * lock_amount) + core * .95, 0.0, 1.0) * idle_pulse;
}

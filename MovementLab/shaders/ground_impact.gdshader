shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;

uniform float age = 0.0;
uniform bool metal_landing = false;

float streak(vec2 p, vec2 head, vec2 tail, float width) {
	vec2 segment = tail - head;
	float t = clamp(dot(p - head, segment) / max(dot(segment, segment), .0001), 0.0, 1.0);
	float distance_to_segment = length(p - head - segment * t);
	return (1.0 - smoothstep(.34, 1.0, distance_to_segment / width)) * (1.0 - t * .87);
}

float sheet(vec2 p, float lead, float lift, float width, float phase) {
	// Sweep a hook forward along the floor, lifting and thinning at the tip.
	float u = (p.x - lead) / width;
	float shape = smoothstep(-1.0, -.78, u) * (1.0 - smoothstep(-.12, .065, u));
	float curve = .025 + lift * pow(clamp(1.0 + u, 0.0, 1.0), 2.4);
	float ripple = sin(p.x * 27.0 + p.y * 20.0 + phase) * .022;
	float thickness = (.085 + lift * .12) * smoothstep(.02, .33, shape);
	float offset = p.y - curve - ripple;
	float body = (1.0 - smoothstep(thickness * .48, thickness, abs(offset))) * shape;
	float crest = (1.0 - smoothstep(.009, .039, abs(offset - thickness * .48))) * shape;
	return body * .58 + crest * .42;
}

void fragment() {
	// Width is normalized to [-1, 1], and the deck passes through y = 0.
	vec2 local = vec2(UV.x * 2.0 - 1.0, .90 - UV.y);
	vec2 p = vec2(abs(local.x), local.y);
	if (p.y < -.055 || p.y > .86 || p.x > .995) {
		discard;
	}

	float phase = clamp(age / (metal_landing ? .44 : .55), 0.0, 1.0);
	float expansion = 1.0 - exp(-phase * 4.6);
	float side_phase = local.x > 0.0 ? .75 : 2.15;
	float lead = mix(.055, .89, expansion);
	float punch = 1.0 - smoothstep(.055, .19, age);
	float flash = exp(-dot(local / vec2(.111, .12), local / vec2(.111, .12)) * 1.8) * punch;
	float spread = exp(-p.x * 6.2 - abs(p.y - .026) * 21.0) * punch;
	float rim = 0.0;
	float vapor = 0.0;

	if (metal_landing) {
		float roll = (p.x - (.10 + .61 * expansion)) / (.22 + .09 * phase);
		float lift = .047 + .068 * sin(p.x * 17.0 + side_phase);
		float height = (p.y - lift) / (.114 + .07 * phase);
		vapor = exp(-dot(vec2(roll, height), vec2(roll, height)) * 1.3) * .56;
		rim = exp(-p.x * 5.0 - abs(p.y - .031) * 44.0) * punch * .65;
	} else {
		float rise = mix(.22, .47, expansion) * (1.0 - phase * .68);
		float main = sheet(p, lead, rise, .42, side_phase);
		float lower = sheet(p, lead + .062, rise * .45, .58, side_phase + 3.1);
		float split = sheet(p, lead * .72, rise * 1.13, .27, side_phase + 1.9);
		float pressure = max(main, max(lower * .87, split * .63));
		rim = pressure * (1.0 - smoothstep(.23, .78, phase)) * 1.27;
		float skirt = (p.x - lead * .80) / (.28 + phase * .19);
		float height = (p.y - .065 - .033 * sin(p.x * 17.0 + side_phase)) / (.095 + phase * .13);
		vapor = exp(-dot(vec2(skirt, height), vec2(skirt, height)) * 1.5) * .34;
	}
	vapor *= smoothstep(0.0, .045, age) * (1.0 - smoothstep(.24, 1.0, phase));

	float sparks = 0.0;
	float spark_age = age / (metal_landing ? .36 : .29);
	if (spark_age < 1.0) {
		for (int i = 0; i < 7; i++) {
			float seed = float(i) + side_phase;
			float variation = fract(seed * 1.618);
			float t = max(spark_age - variation * .11, 0.0);
			vec2 velocity = vec2(1.15 - float(i) * .13, .53 + variation * 1.5);
			vec2 head = vec2(.018 + velocity.x * t, .041 + t * (velocity.y - 1.89 * t));
			vec2 tail = head - vec2(velocity.x, velocity.y - 3.78 * t) * (.16 - .092 * t);
			float width = (metal_landing ? .030 : .024) * mix(.66, 1.15, variation);
			sparks = max(sparks, streak(vec2(p.x * 1.4, p.y), head * vec2(1.4, 1.0), tail * vec2(1.4, 1.0), width));
		}
		sparks *= 1.0 - smoothstep(.41, 1.0, spark_age);
	}

	vec3 dust_tint = metal_landing ? vec3(.69, .51, .32) : vec3(.50, .67, .72);
	vec3 glow_tint = metal_landing ? vec3(1.0, .39, .08) : vec3(.25, .82, .95);
	float hot = max(flash, sparks * .88);
	float glow = max(max(spread * .86, rim), sparks);
	float light_alpha = clamp(max(hot, glow), 0.0, 1.0);
	float alpha = light_alpha + vapor * (1.0 - light_alpha);
	vec3 light = mix(glow_tint, vec3(1.0, .99, .92), clamp(hot + rim * .44, 0.0, 1.0));
	ALBEDO = mix(dust_tint, light, light_alpha / max(alpha, .001));
	ALPHA = alpha * smoothstep(-.053, .022, p.y) * (1.0 - smoothstep(.90, .995, p.x));
}

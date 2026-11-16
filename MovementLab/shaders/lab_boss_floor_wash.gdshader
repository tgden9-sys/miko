shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform float drift = 0.0;
uniform bool wake = false;

float thruster(vec2 point, float phase) {
	float distance = length(point);
	float pulse = fract(distance * 2.6 - TIME * 1.1 + phase);
	float curl = sin(point.x * 21.0 + point.y * 12.0 - TIME * 6.2);
	float ripple = smoothstep(.14, .52, pulse) * (1.0 - smoothstep(.58, .84, pulse));
	float pool = exp(-distance * distance * 24.0);
	float ring = exp(-distance * distance * 6.0) * ripple * (.65 + curl * .35);
	return pool * .28 + ring * .115;
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	if (wake) {
		float height = 1.0 - UV.y;
		float trail = p.x + drift * .22;
		float fold = sin(trail * 17.0 - TIME * 4.8) * .035;
		float band = exp(-pow((height - .27 - fold) / .18, 2.0));
		float billows = .55 + .26 * sin(trail * 13.3 + TIME * (2.0 + drift * 1.9))
			+ .19 * sin(trail * 26.0 - TIME * 4.0 + height * 5.0);
		float edge = (1.0 - smoothstep(.44, .99, abs(trail))) * smoothstep(0.0, .13, height);
		ALBEDO = vec3(.55, .69, .79);
		ALPHA = edge * band * billows * (.12 + abs(drift) * .075);
	} else {
		p.x += drift * .075;
		float edge = 1.0 - smoothstep(.63, .99, length(p));
		float forward_wash = thruster(p - vec2(.30, .03), 0.0);
		float rear_wash = thruster(p + vec2(.30, .03), .53);
		ALBEDO = vec3(.48, .72, .93);
		ALPHA = edge * (forward_wash + rear_wash);
	}
}

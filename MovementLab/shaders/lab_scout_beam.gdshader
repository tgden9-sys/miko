shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, fog_disabled;

uniform float power = 1.0;

void fragment() {
	float across = abs(UV.y * 2.0 - 1.0);
	float core = 1.0 - smoothstep(0.032, 0.076, across);
	float glow = exp(-across * 4.5) * (1.0 - smoothstep(0.72, 1.0, across));
	float tip = 1.0 - smoothstep(0.990, 1.0, UV.x);
	vec3 red = vec3(1.0, 0.045, 0.034);
	vec3 hot = vec3(1.0, 0.63, 0.51);
	ALBEDO = mix(red, hot, core * 0.12);
	ALPHA = tip * power * (core * 0.60 + glow * 0.12);
}

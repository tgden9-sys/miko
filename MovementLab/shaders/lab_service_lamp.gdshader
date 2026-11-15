shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, shadows_disabled;

uniform vec4 tint : source_color = vec4(1.0, 0.77, 0.52, 1.0);
uniform float lamp_power : hint_range(0.0, 1.0) = 1.0;
uniform bool beam = false;

void fragment() {
	float across = abs(UV.x * 2.0 - 1.0);
	float down = UV.y;
	float spread = mix(0.205, 0.94, down);
	float cone = 1.0 - smoothstep(spread * 0.25, spread, across);
	float drift = 0.86 + 0.08 * sin(UV.x * 16.0 - UV.y * 8.0 + TIME * 0.42);
	float depth = (1.0 - smoothstep(0.04, 1.0, down)) * smoothstep(0.0, 0.04, down);
	float intensity = lamp_power * lamp_power;
	ALBEDO = tint.rgb;
	ALPHA = beam ? intensity * cone * depth * drift * 0.23 : intensity * (0.82 - 0.25 * across);
}

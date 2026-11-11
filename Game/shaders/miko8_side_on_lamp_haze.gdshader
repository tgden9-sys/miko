shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform float opacity : hint_range(0.0, 0.6) = 0.40;
uniform float phase = 0.0;
uniform vec3 haze_color : source_color = vec3(0.88, 0.60, 0.29);

void fragment() {
	float below = UV.y;
	float width = mix(0.075, 0.43, below);
	float drift = sin(below * 8.0 + TIME * 0.10 + phase) * 0.018;
	float lateral = (UV.x - 0.5 - drift) / width;
	float soft = exp(-lateral * lateral * 3.0);
	float falloff = exp(-below * 1.5) * (1.0 - smoothstep(0.78, 1.0, below));
	float source_fade = smoothstep(0.0, 0.06, below);
	float air = 0.82 + 0.10 * sin(below * 17.0 - TIME * 0.15 + phase);
	ALBEDO = haze_color;
	ALPHA = opacity * soft * falloff * source_fade * air;
}

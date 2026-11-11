shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform float opacity : hint_range(0.0, 0.5) = 0.34;
uniform float phase = 0.0;
uniform vec3 vapor_color : source_color = vec3(0.62, 0.67, 0.69);

void fragment() {
	float h = 1.0 - UV.y;
	float time = TIME * 0.18;
	float center = 0.5 + sin(h * 7.0 - time + phase) * 0.095;
	center += sin(h * 15.0 + time * 0.47 + phase) * 0.035;
	float width = 0.08 + h * 0.20;
	float ribbon = exp(-pow((UV.x - center) / width, 2.0) * 1.8);
	float inner = exp(-pow((UV.x - center + 0.045) / (width * 0.32), 2.0));
	float flow = 0.61 + sin(h * 18.0 - TIME * 0.37 + phase) * 0.17;
	float fade = smoothstep(0.0, 0.12, h) * (1.0 - smoothstep(0.48, 1.0, h));
	ALBEDO = vapor_color;
	ALPHA = opacity * (ribbon * 0.78 + inner * 0.22) * flow * fade;
}

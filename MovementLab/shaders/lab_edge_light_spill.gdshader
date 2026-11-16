shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;

uniform vec4 spill_color : source_color = vec4(0.42, 0.68, 0.82, 1.0);
uniform float intensity : hint_range(0.0, 2.0) = 0.60;
uniform float falloff_power : hint_range(0.5, 5.0) = 2.2;

void fragment() {
	// UV.y is 0.0 at the cutaway boundary, 1.0 at outer edge in the void
	float falloff = pow(clamp(1.0 - UV.y, 0.0, 1.0), falloff_power);
	// Soften corners along x
	float edge_taper = sin(clamp(UV.x, 0.0, 1.0) * PI);
	edge_taper = pow(edge_taper, 0.25);
	ALBEDO = spill_color.rgb;
	ALPHA = falloff * edge_taper * intensity * spill_color.a;
}

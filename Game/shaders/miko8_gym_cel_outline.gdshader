shader_type spatial;
render_mode unshaded, cull_front, shadows_disabled;

uniform vec3 ink_color : source_color = vec3(0.015, 0.020, 0.028);
uniform float thickness = 0.004;

void vertex() {
	VERTEX += NORMAL * thickness;
}

void fragment() {
	ALBEDO = ink_color;
}

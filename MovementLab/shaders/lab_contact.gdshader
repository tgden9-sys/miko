shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, fog_disabled;

uniform float opacity = 0.40;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	ALBEDO = vec3(0.028, 0.038, 0.048);
	ALPHA = pow(max(0.0, 1.0 - dot(p, p)), 2.1) * opacity;
}

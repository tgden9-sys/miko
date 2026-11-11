shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, fog_disabled;

uniform vec4 light_color : source_color = vec4(1.0, 0.58, 0.22, 1.0);
uniform float energy = 0.44;
uniform float flicker = 0.0;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float halo = pow(max(0.0, 1.0 - dot(p, p)), 3.0);
	ALBEDO = light_color.rgb;
	ALPHA = halo * energy * (1.0 - flicker * (0.5 + 0.5 * sin(TIME * 2.8)));
}

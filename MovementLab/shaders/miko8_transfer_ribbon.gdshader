shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, shadows_disabled, depth_draw_never;
uniform float strength = 1.;
void fragment() {
	float across = abs(UV.x * 2. - 1.);
	float core = 1. - smoothstep(.10, .30, across);
	float halo = pow(1. - across, 2.) * .22;
	float flow = .72 + .28 * pow(.5 + .5 * sin(UV.y * 28. - TIME * 11.), 6.);
	ALBEDO = mix(vec3(.24, .80, .69), vec3(.83, 1., .96), core);
	ALPHA = (core + halo) * strength * flow;
}

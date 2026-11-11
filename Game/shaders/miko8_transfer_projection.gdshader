shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, shadows_disabled, depth_draw_never;

uniform float lock_amount = 0.0;

void fragment() {
	float height = 1.0 - UV.y;
	float spread = mix(.11, .43, height);
	float distance_from_axis = abs(UV.x - .5) / spread;
	float envelope = 1.0 - smoothstep(.04, 1.0, distance_from_axis);
	float ends = smoothstep(0.0, .08, height) * (1.0 - smoothstep(.71, 1.0, height));
	float scan = pow(.5 + .5 * cos(height * TAU * 3.0 - TIME * 6.5), 12.0);
	ALBEDO = mix(vec3(.09, .64, .62), vec3(.31, .89, .83), scan);
	ALPHA = envelope * ends * (.09 + lock_amount * .07 + scan * (.09 + lock_amount * .13));
}

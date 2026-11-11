shader_type spatial;
render_mode unshaded, fog_disabled;

uniform sampler2D machine_hall : source_color, filter_linear_mipmap, repeat_disable;
uniform vec4 view_rect = vec4(0.0, 0.06, 0.38, 0.88);
uniform float bay_x = 0.0;
uniform vec4 tint : source_color = vec4(0.76, 0.92, 0.91, 1.0);

void fragment() {
	float shift = clamp((CAMERA_POSITION_WORLD.x - bay_x) * 0.0024, -0.042, 0.042);
	vec2 uv = view_rect.xy + UV * view_rect.zw + vec2(shift, 0.0);
	vec3 room = texture(machine_hall, uv).rgb;
	float edge = smoothstep(0.0, 0.16, UV.x) * smoothstep(0.0, 0.16, 1.0 - UV.x);
	float glass = smoothstep(0.065, 0.09, UV.y) * (1.0 - smoothstep(0.14, 0.18, UV.y));
	float gloss = pow(1.0 - UV.y, 7.0) * 0.07 + glass * 0.026;
	ALBEDO = room * tint.rgb * mix(0.66, 1.08, edge) + vec3(0.018, 0.035, 0.039) * (0.5 + gloss * 8.0);
}

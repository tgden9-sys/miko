shader_type spatial;
render_mode unshaded, shadows_disabled;

uniform vec4 pole_color : source_color = vec4(1.0, 0.21, 0.13, 1.0);
uniform float powered : hint_range(0.0, 1.0) = 1.0;
uniform float surge = -1.0;
uniform float feed_start = 24.4;
uniform float feed_finish = 29.3;
varying float position_x;

void vertex() {
	position_x = (MODEL_MATRIX * vec4(VERTEX, 1.0)).x;
}

void fragment() {
	float pulse = 0.5 + 0.5 * sin(position_x * 2.7 - TIME * 3.4);
	float along_feed = (position_x - feed_start) / (feed_finish - feed_start);
	float wave = exp(-pow(abs(along_feed - surge) * 9.0, 2.0));
	float envelope = smoothstep(0.0, 0.15, surge) * (1.0 - smoothstep(0.70, 1.0, surge));
	vec3 lit = pole_color.rgb * (0.38 + pulse * 0.17);
	ALBEDO = mix(COLOR.rgb * 0.10, lit, powered) + vec3(1.0, 0.63, 0.44) * wave * envelope * 0.90;
}

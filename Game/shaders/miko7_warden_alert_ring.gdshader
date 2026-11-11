shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, depth_draw_never;

uniform float alerted : hint_range(0.0, 1.0) = 0.0;
uniform float facing = 1.0;

void fragment() {
	vec2 point = (UV - 0.5) * 2.0;
	float radius = length(point);
	float aa = max(fwidth(radius), 0.002);
	float edge = 1.0 - smoothstep(0.002, 0.002 + aa, abs(radius - 0.993));
	float arc = fract(atan(point.y, point.x) * 4.45634);
	float dash = smoothstep(0.1, 0.2, arc) * (1.0 - smoothstep(0.72, 0.82, arc));
	float front = smoothstep(-0.10, 0.13, point.x * facing);
	float tint = front * alerted;
	ALBEDO = mix(vec3(0.59, 0.41, 0.22), vec3(1.0, 0.43, 0.12), tint);
	ALPHA = edge * mix(0.21, 0.84, tint) * mix(dash, 1.0, tint);
}

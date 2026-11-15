// Broad pools give each route its own light without a bank of per-pixel scene lights.
uniform float room_lighting : hint_range(0.0, 1.0) = 0.0;
uniform float gallery_power : hint_range(0.0, 1.0) = 1.0;
uniform vec3 relay_position = vec3(30.4, 13.05, 0.4);
uniform vec4 relay_color : source_color = vec4(1.0, 0.17, 0.10, 1.0);
uniform float relay_power : hint_range(0.0, 1.0) = 0.0;
uniform bool fixed_room_lighting = false;
uniform vec3 fixed_ambient = vec3(0.77, 0.85, 0.91);
uniform vec3 first_light_tint = vec3(0.40, 0.25, 0.12);
uniform vec3 second_light_tint = vec3(0.08, 0.25, 0.37);
// Each pool is a world-space X/Y center and horizontal/vertical radii.
uniform vec4 first_light_pool = vec4(0.0, 0.0, 4.0, 3.0);
uniform vec4 second_light_pool = vec4(0.0, 0.0, 4.0, 3.0);

float local_room_light(vec2 point, vec4 pool) {
	return 1.0 - smoothstep(0.15, 1.0, length((point - pool.xy) / pool.zw));
}

vec3 room_light(vec3 point) {
	if (fixed_room_lighting) {
		return fixed_ambient
			+ first_light_tint * local_room_light(point.xy, first_light_pool)
			+ second_light_tint * local_room_light(point.xy, second_light_pool);
	}
	float middle = smoothstep(5.3, 6.9, point.y);
	float upper = smoothstep(11.3, 12.9, point.y);
	float warm_pool = 1.0 - smoothstep(0.3, 5.5, min(abs(point.x - 5.7), abs(point.x - 17.0)));
	float relay_pool = 1.0 - smoothstep(0.3, 5.7, min(abs(point.x - 12.2), abs(point.x - 23.4)));
	vec3 base = vec3(0.58, 0.64, 0.69);
	vec3 warm = base + vec3(0.43, 0.28, 0.15) * warm_pool;
	vec3 cool = base + vec3(0.14, 0.27, 0.32) * gallery_power;
	vec3 relay = base + vec3(0.26, 0.34, 0.24) * relay_pool;
	float shaft = max(smoothstep(26.0, 30.5, point.x) * (1.0 - smoothstep(7.4, 9.4, point.y)),
		(1.0 - smoothstep(5.0, 9.0, point.x)) * smoothstep(6.9, 8.6, point.y));
	return mix(mix(mix(warm, cool, middle), relay, upper), vec3(0.49, 0.65, 0.72), shaft * 0.83);
}

vec3 relay_spill(vec3 point, vec3 normal) {
	vec3 ray = relay_position - point;
	float radius = length(ray * vec3(0.72, 1.0, 0.86));
	float falloff = 1.0 - smoothstep(0.38, 2.65, radius);
	float facing = 0.38 + 0.62 * max(dot(normal, ray / max(length(ray), 0.01)), 0.0);
	return relay_color.rgb * relay_power * falloff * falloff * facing;
}

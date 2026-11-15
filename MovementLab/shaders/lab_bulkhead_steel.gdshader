shader_type spatial;
render_mode unshaded;
#include "res://shaders/lab_room_light.gdshaderinc"

uniform sampler2D steel_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
varying vec3 position_in_room;
varying vec3 surface_normal;

void vertex() {
	position_in_room = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	surface_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
	vec3 point = position_in_room * 0.38;
	vec3 normal = normalize(surface_normal);
	vec3 weight = pow(abs(normal), vec3(5.0));
	weight /= weight.x + weight.y + weight.z;
	vec3 steel = texture(steel_map, point.zy).rgb * weight.x
		+ texture(steel_map, point.xz + vec2(0.29, 0.41)).rgb * weight.y
		+ texture(steel_map, point.xy + vec2(0.62, 0.19)).rgb * weight.z;
	float wear = dot(steel, vec3(0.31, 0.53, 0.16));
	vec3 finish_color = COLOR.rgb * (0.20 + wear * 2.55) + (steel - vec3(wear)) * 0.19;
	float key = max(dot(normal, normalize(vec3(-0.38, 0.63, 0.61))), 0.0);
	float bounce = max(dot(normal, normalize(vec3(0.35, -0.72, 0.60))), 0.0);
	vec3 steel_color = finish_color * (0.44 + key * 0.68 + bounce * 0.16);
	ALBEDO = steel_color;
	if (room_lighting > 0.0) {
		ALBEDO *= mix(vec3(1.0), room_light(position_in_room), room_lighting);
		if (relay_power > 0.0) {
			ALBEDO += relay_spill(position_in_room, normal) * (0.12 + finish_color * 0.52);
		}
	}
}

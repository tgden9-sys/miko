shader_type spatial;
render_mode unshaded, shadows_disabled;
#include "res://shaders/lab_room_light.gdshaderinc"

uniform sampler2D backdrop : source_color, filter_linear_mipmap, repeat_disable;
uniform vec2 atlas_offset = vec2(0.0);
uniform vec2 atlas_scale = vec2(1.0);
uniform vec4 backdrop_tint : source_color = vec4(0.74, 0.79, 0.81, 1.0);
uniform float recession : hint_range(0.0, 1.0) = 0.26;
uniform float lamp_power : hint_range(0.0, 1.0) = 1.0;
uniform float shaft_haze : hint_range(0.0, 1.0) = 0.0;
varying vec3 room_point;

void vertex() {
	room_point = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 image = texture(backdrop, atlas_offset + UV * atlas_scale).rgb;
	float value = dot(image, vec3(0.28, 0.57, 0.15));
	image = mix(image, vec3(value), 0.28);
	vec3 light = room_light(room_point);
	float edge = min(UV.y, 1.0 - UV.y);
	float ceiling_shadow = mix(0.72, 1.0, smoothstep(0.0, 0.13, edge));
	vec3 shaded = image * backdrop_tint.rgb * light * ceiling_shadow * mix(0.43, 1.0, lamp_power);
	float haze = exp(-pow((UV.y - 0.59) * 2.4, 2.0));
	float drift = 0.69 + 0.19 * sin(UV.y * 9.0 + UV.x * 5.0 + TIME * 0.23);
	vec3 deep_air = vec3(0.023, 0.048, 0.058);
	ALBEDO = mix(shaded, deep_air, min(recession + shaft_haze * haze * drift * 0.31, 0.88));
}

shader_type spatial;
render_mode unshaded, cull_front, shadows_disabled;
#include "res://shaders/miko8_transfer_common.gdshaderinc"

uniform vec3 ink_color : source_color = vec3(0.018, 0.024, 0.031);
uniform vec3 mist_color : source_color = vec3(0.095, 0.135, 0.220);
uniform float near_depth = 17.5;
uniform float far_depth = 24.0;
uniform float base_thickness = 0.009;

void vertex() {
	vec4 view_pos = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	float depth = -view_pos.z;
	float factor = clamp((depth - near_depth) / max(far_depth - near_depth, 0.01), 0.0, 1.0);
	float thickness = base_thickness * mix(1.0, 0.45, factor);
	VERTEX += NORMAL * thickness / max(length((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz), 0.001);
}

void fragment() {
	vec3 transfer_point = (INV_VIEW_MATRIX * vec4(VERTEX, 1.)).xyz;
	if (transfer_progress > 0. && transfer_distance(transfer_point) < 0.) discard;
	float depth = -VERTEX.z;
	float factor = clamp((depth - near_depth) / max(far_depth - near_depth, 0.01), 0.0, 1.0);
	ALBEDO = mix(mix(ink_color, mist_color, factor * 0.75), transfer_colour, transfer_charge * .78);
}

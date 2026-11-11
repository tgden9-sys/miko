shader_type spatial;
render_mode unshaded;
#include "res://shaders/lab_sword_wall.gdshaderinc"

uniform vec4 tint : source_color = vec4(1.0);

void vertex() {
	sword_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	if (beyond_sword_wall()) {
		discard;
	}
	ALBEDO = tint.rgb;
}

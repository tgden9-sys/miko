shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled;

uniform float opacity = 0.16;
uniform vec4 tint = vec4(1.0,.085,.15,1.0);
uniform float deck_height = 6.0;
varying float world_height;

void vertex() {
	world_height = (MODEL_MATRIX*vec4(VERTEX,1.0)).y;
}

void fragment() {
	float along = UV.x;
	float across = abs(UV.y*2.0-1.0);
	float spread = mix(0.025,1.0,along);
	float edge = across/max(spread,.001);
	float cone = 1.0-smoothstep(.76,1.0,edge);
	float falloff = (1.0-smoothstep(.70,1.0,along))*smoothstep(0.0,.04,along);
	float scan = .86+.14*sin(along*16.0-TIME*6.0);
	ALBEDO = tint.rgb;
	ALPHA = cone*falloff*scan*opacity
		* smoothstep(deck_height-.035,deck_height+.07,world_height);
}

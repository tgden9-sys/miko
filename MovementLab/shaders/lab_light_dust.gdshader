shader_type spatial;
render_mode unshaded, depth_draw_never, shadows_disabled;

uniform vec4 dust_color : source_color = vec4(0.82, 0.75, 0.62, 1.0);
uniform float lamp_power : hint_range(0.0, 1.0) = 1.0;
uniform vec3 drift_volume = vec3(3.5, 4.0, 0.56);
uniform bool lamp_cone = true;
uniform float dust_opacity : hint_range(0.0, 1.0) = 1.0;
varying float mote_opacity;

void vertex() {
	vec3 seed = VERTEX;
	float speed = lamp_cone ? 1.0 : 0.42;
	float drift = TIME * mix(0.035, 0.085, seed.z) * speed;
	float slide = fract(seed.x + drift);
	float height = fract(seed.y + drift * 0.41);
	float spread = lamp_cone ? mix(0.194, 1.0, height) : 1.0;
	VERTEX = vec3((slide - 0.5) * spread, 0.5 - height, seed.z - 0.5) * drift_volume;
	mote_opacity = sin(slide * PI) * sin(height * PI) * mix(0.30, 0.69, seed.z);
	float size = lamp_cone ? 3.1 : 4.6;
	POINT_SIZE = clamp(VIEWPORT_SIZE.y * size / 900.0, 2.25, 7.0) * mix(0.78, 1.26, seed.z);
}

void fragment() {
	float radius = length(POINT_COORD - vec2(0.5));
	ALBEDO = dust_color.rgb;
	ALPHA = dust_opacity * lamp_power * lamp_power * mote_opacity * (1.0 - smoothstep(0.09, 0.49, radius));
}

shader_type spatial;
render_mode unshaded, shadows_disabled;

uniform sampler2D facade : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D panels : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D concrete : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 facade_rect = vec4(0.0, 0.0, 1.0, 1.0);
uniform vec3 dimensions = vec3(8.0, 5.0, 3.0);
uniform float brightness = 0.5;
uniform float facade_gain = 1.0;

varying vec3 local_position;
varying vec3 local_normal;
varying vec3 world_position;

void vertex() {
	local_position = VERTEX;
	local_normal = NORMAL;
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 paint;
	if (local_normal.z > 0.5) {
		vec2 front_uv = vec2(local_position.x / dimensions.x + 0.5, 0.5 - local_position.y / dimensions.y);
		paint = texture(facade, facade_rect.xy + front_uv * facade_rect.zw).rgb * facade_gain;
	} else if (local_normal.y > 0.5) {
		vec2 tile = world_position.xz / vec2(1.8, 1.45);
		vec2 seam = min(fract(tile), 1.0 - fract(tile));
		float joint = smoothstep(0.005, 0.022, min(seam.x, seam.y));
		paint = texture(concrete, world_position.xz / 2.1).rgb * mix(0.32, 0.57, joint);
	} else {
		vec2 side_uv = vec2(world_position.z, -world_position.y) / 3.2;
		paint = texture(panels, side_uv).rgb * vec3(0.48, 0.51, 0.52);
	}
	// Keep the wall grounded and separate its value range from the playable roofs.
	ALBEDO = paint * brightness * mix(0.63, 1.0, smoothstep(0.0, 0.85, world_position.y));
}

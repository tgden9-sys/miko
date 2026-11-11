shader_type spatial;
render_mode unshaded;

uniform sampler2D wear_map : filter_linear_mipmap, repeat_enable;
varying vec3 world_position;
varying vec3 world_normal;
varying float light_level;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	vec3 key_direction = normalize(vec3(-0.35, 0.76, 0.55));
	light_level = 0.56 + 0.54 * max(0.0, dot(world_normal, key_direction));
}

void fragment() {
	vec3 p = world_position * 0.23;
	vec3 axis = abs(world_normal);
	float xy = step(max(axis.x, axis.y), axis.z);
	float xz = (1.0 - xy) * step(axis.x, axis.y);
	vec2 uv = p.xy * xy + p.xz * xz + p.zy * (1.0 - xy - xz);
	vec3 surface = texture(wear_map, uv).rgb;
	float patina = dot(surface, vec3(0.30, 0.60, 0.10));
	float oxidation = clamp((surface.r - surface.g + 0.006) * 5.0, 0.0, 0.6);
	vec3 paint = COLOR.rgb * light_level * (0.56 + patina * 1.24);
	ALBEDO = mix(paint, paint * vec3(1.24, 0.78, 0.51), oxidation);
}

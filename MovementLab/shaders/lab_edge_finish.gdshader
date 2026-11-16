shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D steel_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
varying vec3 world_point;
varying vec3 world_normal;

void vertex() {
	world_point = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
	vec3 n = normalize(world_normal);
	vec3 weights = pow(abs(n), vec3(5.0));
	weights /= max(dot(weights, vec3(1.0)), 0.001);
	vec3 p = world_point * 0.65;
	vec3 steel = texture(steel_map, p.zy).rgb * weights.x
		+ texture(steel_map, p.xz).rgb * weights.y
		+ texture(steel_map, p.xy).rgb * weights.z;
	float grain = clamp(dot(steel, vec3(0.30, 0.55, 0.15)), 0.08, 0.70);
	vec3 finish = COLOR.rgb * (0.72 + grain * 0.75);
	float key = max(dot(n, normalize(vec3(-0.30, 0.72, 0.62))), 0.0);
	float rim = pow(max(dot(n, normalize(vec3(0.06, 0.58, 0.81))), 0.0), 18.0);
	finish *= 0.40 + key * 0.72;
	finish += vec3(0.12, 0.15, 0.16) * rim;
	// Recessed deck joints and a narrow non-slip strip, all at world scale.
	if (n.y > 0.82) {
		float seam = 1.0 - smoothstep(0.012, 0.027, abs(mod(world_point.x + 0.7, 2.8) - 1.4));
		float edge_zone = smoothstep(-0.38, -0.32, world_point.z) * (1.0 - smoothstep(0.20, 0.24, world_point.z));
		float groove = 1.0 - smoothstep(0.009, 0.017, abs(mod(world_point.z, 0.13) - 0.065));
		finish *= 1.0 - seam * 0.52 - groove * edge_zone * 0.18;
	}
	ALBEDO = finish;
}

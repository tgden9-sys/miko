shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// The lattice is real geometry. Its fine texture is low contrast and mip
// filtered; no fragment-frequency noise, fake grille pattern or moving grain.
uniform vec4 base_color : source_color = vec4(0.376, 0.380, 0.373, 1.0);
uniform sampler2D wear : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float metal : hint_range(0.0, 1.0) = 0.26;
uniform float roughness : hint_range(0.0, 1.0) = 0.86;
uniform bool use_vertex_detail = false;
varying vec3 world_point;
varying vec3 world_normal;

void vertex() {
	world_point = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
	vec3 weights = pow(abs(world_normal), vec3(4.0));
	weights /= max(dot(weights, vec3(1.0)), 0.001);
	vec3 grain = texture(wear, world_point.zy * 0.65).rgb * weights.x;
	grain += texture(wear, world_point.xz * 0.65).rgb * weights.y;
	grain += texture(wear, world_point.xy * 0.65).rgb * weights.z;
	float value = dot(grain, vec3(0.299, 0.587, 0.114));
	float variation = clamp((value - 0.10) * 1.1, -0.10, 0.15);
	ALBEDO = base_color.rgb * (1.0 + variation);
	float oxidation = clamp((grain.r - grain.b) * 2.0, 0.0, 0.22);
	ALBEDO = mix(ALBEDO, ALBEDO * vec3(1.08, 0.97, 0.88), oxidation);
	ROUGHNESS = clamp(roughness + (0.10 - value) * 0.18, 0.72, 0.93);
	METALLIC = metal;
	SPECULAR = 0.24;
	if (use_vertex_detail) {
		// Existing raycast-baked AO and bevel mask from the exported bridge.
		AO = clamp(COLOR.r, 0.28, 1.0);
		ALBEDO *= mix(0.76, 1.0, AO);
		ALBEDO = mix(ALBEDO, ALBEDO * 1.14, COLOR.g * 0.22);
	}
}

shader_type spatial;
render_mode unshaded;

uniform vec4 base_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D base_texture : source_color, filter_linear_mipmap_anisotropic;
uniform bool use_texture = true;

uniform vec3 key_direction = vec3(-0.45, 0.75, 0.48);
uniform float shadow_threshold = 0.15;
uniform float light_threshold = 0.58;
uniform float transition_width = 0.025;

uniform vec3 shadow_tone : source_color = vec3(0.30, 0.34, 0.42); // Cool industrial ambient tone
uniform vec3 middle_tone : source_color = vec3(0.80, 0.82, 0.85); // Neutral crisp midtone
uniform vec3 light_tone : source_color = vec3(1.10, 1.06, 0.98);  // Warm sunlit highlight

uniform float rim_power = 2.8;
uniform float rim_intensity = 0.28;
uniform vec3 rim_color : source_color = vec3(1.0, 0.96, 0.88);

varying vec3 world_normal;
varying vec3 world_pos;

void vertex() {
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 albedo = base_color.rgb;
	if (use_texture) {
		albedo *= texture(base_texture, UV).rgb;
	}
	
	// 1. Sharp Cel Lighting Bands
	float n_dot_l = dot(normalize(world_normal), normalize(key_direction));
	float mid = smoothstep(shadow_threshold - transition_width, shadow_threshold + transition_width, n_dot_l);
	float lit = smoothstep(light_threshold - transition_width, light_threshold + transition_width, n_dot_l);
	
	vec3 tone = mix(shadow_tone, middle_tone, mid);
	tone = mix(tone, light_tone, lit);
	
	vec3 color = albedo * tone;
	
	// 2. Subtle Anime Edge Rim Sheen
	vec3 view_dir = normalize(CAMERA_POSITION_WORLD - world_pos);
	float fresnel = pow(clamp(1.0 - dot(normalize(world_normal), view_dir), 0.0, 1.0), rim_power);
	color += rim_color * fresnel * rim_intensity * mid;
	
	ALBEDO = color;
}

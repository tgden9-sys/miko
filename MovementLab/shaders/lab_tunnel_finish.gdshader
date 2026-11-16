shader_type spatial;
render_mode unshaded;

// Preserve the authored UV detail, but remove the pale baked studio illumination.
uniform sampler2D base_texture : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D steel_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 field_color : source_color = vec4(0.2,0.6,1.0,1.0);
uniform float field_power = 1.0;
uniform vec4 metal_tint : source_color = vec4(1.0);
uniform bool textured_portal = false;
varying vec3 local_position;
varying vec3 world_normal;
void vertex() {
	local_position = VERTEX;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}
void fragment() {
	vec3 source = texture(base_texture,UV).rgb;
	float value = dot(source,vec3(0.3,0.59,0.11));
	vec3 detail = texture(steel_map,local_position.zy * 1.65).rgb;
	float grain = dot(detail,vec3(0.3,0.59,0.11));
	vec3 base = vec3(0.12,0.15,0.155) * (0.32 + value * 3.1);
	base *= 0.92 + grain * 0.36;
	base += (source-vec3(value)) * 0.15;
	float key = dot(normalize(world_normal),normalize(vec3(-0.4,0.75,0.5)));
	float light = mix(0.53,0.93,smoothstep(-0.1,0.4,key));
	light = mix(light,1.18,smoothstep(0.55,0.8,key));
	float recess = smoothstep(-2.6,-0.3,local_position.z);
	ALBEDO = base * metal_tint.rgb * light * mix(0.48,1.0,recess);
	if (textured_portal) {
		vec3 weathered = mix(vec3(value),source,0.60);
		vec3 steel = vec3(0.13,0.17,0.18) * (0.40 + 2.3*weathered + grain*0.8);
		ALBEDO = steel * mix(vec3(1.0),metal_tint.rgb,0.68) * light * mix(0.35,0.96,recess);
	}
	ALBEDO += field_color.rgb * exp(-abs(local_position.z+0.36)*4.8) * field_power * 0.036;
}

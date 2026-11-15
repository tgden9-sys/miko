shader_type spatial;
render_mode unshaded;
uniform sampler2D steel_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 field_color : source_color = vec4(0.2,0.6,1.0,1.0);
uniform float field_power = 1.0;
uniform vec4 metal_tint : source_color = vec4(1.0);
varying vec3 point;
varying vec3 world_normal;
varying vec3 local_normal;
void vertex() {
	point = VERTEX;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	local_normal = NORMAL;
}
void fragment() {
	vec3 n = normalize(world_normal);
	vec3 w = pow(abs(local_normal),vec3(4.0));
	w /= max(w.x+w.y+w.z,0.001);
	vec3 steel = texture(steel_map,point.zy*1.7).rgb*w.x
		+ texture(steel_map,point.xz*1.7).rgb*w.y
		+ texture(steel_map,point.xy*1.7).rgb*w.z;
	float grain = dot(steel,vec3(0.3,0.59,0.11));
	float key = dot(n,normalize(vec3(-0.38,0.7,0.6)));
	float shade = mix(0.50,0.88,smoothstep(-0.18,0.36,key));
	shade = mix(shade,1.17,smoothstep(0.58,0.80,key));
	ALBEDO = COLOR.rgb * metal_tint.rgb * (0.82+grain*0.72) * shade;
	// Local, restrained light from the recessed emitter channel.
	float spill = exp(-abs(abs(point.x)-1.075)*13.0) * exp(-abs(point.z+0.08)*7.0);
	ALBEDO += field_color.rgb * spill * field_power * 0.065;
}

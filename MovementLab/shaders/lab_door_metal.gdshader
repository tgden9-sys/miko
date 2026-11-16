shader_type spatial;
render_mode unshaded;
uniform sampler2D steel_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 field_color : source_color = vec4(0.2,0.6,1.0,1.0);
uniform float field_power = 1.0;
uniform vec4 metal_tint : source_color = vec4(1.0);
uniform bool textured_portal = false;
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
	if (textured_portal) {
		vec3 p = point * 0.61;
		vec3 patina = texture(steel_map,p.zy).rgb*w.x
			+ texture(steel_map,p.xz+vec2(0.19,0.43)).rgb*w.y
			+ texture(steel_map,p.xy+vec2(0.31,0.12)).rgb*w.z;
		float wear = dot(patina,vec3(0.30,0.59,0.11));
		float scuffs = smoothstep(0.19,0.41,wear);
		float broad_key = max(dot(normalize(local_normal),normalize(vec3(-0.2,0.68,0.68))),0.0);
		float pocket = mix(0.43,1.0,smoothstep(-0.80,0.085,point.z));
		vec3 tint = mix(vec3(1.0),metal_tint.rgb,0.66);
		vec3 base = COLOR.rgb * tint * (0.44 + 0.76*grain + 1.03*scuffs);
		base += (patina-vec3(wear))*0.28;
		// Broad highlights grade over the curved profile and leave the gasket dark.
		float steel_exposed = smoothstep(0.22,0.41,dot(COLOR.rgb,vec3(0.3,0.59,0.11)));
		ALBEDO = base * (0.38+0.62*broad_key) * pocket;
		ALBEDO += vec3(0.15,0.167,0.166) * pow(broad_key,8.0) * steel_exposed * (0.40+0.60*scuffs) * pocket;
		float throat = smoothstep(-0.55,-0.27,point.z) * (1.0-smoothstep(-0.13,0.025,point.z));
		float energized = 1.0-smoothstep(0.0,0.33,abs(abs(point.x)-1.10));
		ALBEDO += field_color.rgb * throat * energized * field_power * (0.029+0.034*grain);
	}
	// Local, restrained light from the recessed emitter channel.
	float spill = exp(-abs(abs(point.x)-1.075)*13.0) * exp(-abs(point.z+(textured_portal ? 0.245 : 0.08))*7.0);
	ALBEDO += field_color.rgb * spill * field_power * 0.065;
}

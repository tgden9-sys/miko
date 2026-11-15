shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, fog_disabled;

uniform float age = 0.0;
uniform vec4 ember_color : source_color = vec4(1.0, 0.42, 0.13, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float plume_noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 blend = smoothstep(vec2(0.0), vec2(1.0), fract(p));
	float row = mix(hash(cell), hash(cell + vec2(1, 0)), blend.x);
	float next_row = mix(hash(cell + vec2(0, 1)), hash(cell + vec2(1, 1)), blend.x);
	return mix(row, next_row, blend.y);
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float expansion = 1.0 - exp(-age * 13.0);
	p.y += expansion * .21;
	float angle = atan(p.y, p.x + .0001);
	float distance_from_core = length(p * vec2(.88, 1.07));
	vec2 flow = vec2(0.0, age * 1.6);
	float billows = plume_noise((p + flow) * 5.6);
	float detail = plume_noise((p + flow) * 14.0);
	float lobes = sin(angle * 5.0 + .8) * .063 + sin(angle * 11.0 - .9) * .026;
	float radius = .14 + expansion * (.58 + lobes + (billows - .5) * .24);
	float edge = distance_from_core / radius;

	float heat = 1.0 - smoothstep(.05, .26, age);
	float fire = (1.0 - smoothstep(.70, 1.03, edge)) * heat * (.69 + billows * .31);
	float white_core = (1.0 - smoothstep(.22, .84, edge + (detail - .5) * .25))
		* (1.0 - smoothstep(.055, .176, age));
	float glare = exp(-distance_from_core * 6.8) * (1.0 - smoothstep(.034, .12, age));

	float smoke = (1.0 - smoothstep(.54, 1.10, edge)) * (.23 + billows * .56 + detail * .20)
		* smoothstep(.040, .17, age) * (1.0 - smoothstep(.27, .64, age)) * .68;
	float light = max(fire, max(white_core, glare));
	vec3 soot = mix(vec3(.13, .124, .13), vec3(.32, .29, .26), billows);
	vec3 flame = ember_color.rgb * mix(.56, 1.0, detail);
	float flame_core = clamp(white_core * 1.22 + heat * billows * (1.0 - edge) * .42, 0.0, 1.0);
	ALBEDO = mix(soot, mix(flame, vec3(1.0, .97, .82), flame_core),
		light / max(.001, light + smoke * (1.0 - light)));
	ALPHA = light + smoke * (1.0 - light);
}

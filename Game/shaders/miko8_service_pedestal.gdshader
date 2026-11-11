shader_type spatial;
render_mode unshaded;

uniform sampler2D paint_atlas : source_color, hint_default_white, filter_linear_mipmap_anisotropic;
uniform vec4 hardware_paint : source_color = vec4(.46, .50, .50, 1.);
uniform bool use_atlas = true;
varying vec3 world_normal;
varying vec3 prop_position;

void vertex() {
	// Bias scan normals toward their main face to keep flat panels in one band.
	vec3 local_normal = normalize(NORMAL * pow(abs(NORMAL) + vec3(.001), vec3(.70)));
	world_normal = normalize(MODEL_NORMAL_MATRIX * local_normal);
	prop_position = VERTEX;
}

void fragment() {
	float key = dot(normalize(world_normal), normalize(vec3(-.35, .76, .57)));
	float middle = smoothstep(.16, .23, key);
	float light = smoothstep(.69, .76, key);
	vec3 band = mix(vec3(.49, .53, .57), vec3(.90, .91, .90), middle);
	band = mix(band, vec3(1.14, 1.10, 1.02), light);

	vec3 paint = hardware_paint.rgb;
	float standby = 0.;
	if (use_atlas) {
		vec3 src = texture(paint_atlas, UV, .35).rgb;
		float value = dot(src, vec3(.2126, .7152, .0722));
		float amber = smoothstep(.038, .19, src.r - src.b) *
			smoothstep(.012, .08, src.r - src.g);
		// Retain painted seams, bolts and chipped edges. Quiet the baked
		// highlights so the light and dark faces are set by the mesh.
		float steel = mix(value, sqrt(max(value, 0.)) * .74, .28);
		vec3 neutral = steel * vec3(1.015, 1., .952);
		vec3 warm = mix(src, vec3(1.15, .82, .43) * value, .40);
		paint = mix(neutral, warm, amber);

		// Only the original front lens glows; hardware and safety paint stay matte.
		float lens = 1. - smoothstep(.15, .18, abs(prop_position.x + .115));
		lens *= smoothstep(.46, .50, prop_position.z);
		lens *= smoothstep(.703, .733, prop_position.y) *
			(1. - smoothstep(.792, .818, prop_position.y));
		standby = lens * amber * smoothstep(.18, .50, value);
	} else {
		// Subtle machining marks on the new insert, without a second atlas.
		float lines = sin(173. * prop_position.y + sin(28. * prop_position.x));
		float edge_wear = smoothstep(.92, 1., lines) * .06;
		paint *= 1. + edge_wear;
	}

	float footing = mix(.78, 1., smoothstep(.006, .16, prop_position.y));
	vec3 colour = paint * band * footing;
	ALBEDO = mix(colour, vec3(1., .61, .22), standby * .57);
}

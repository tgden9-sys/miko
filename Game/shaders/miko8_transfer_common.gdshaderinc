uniform float transfer_progress = 0.0;
uniform float transfer_charge = 0.0;
uniform float transfer_floor = 0.0;
uniform vec3 transfer_colour : source_color = vec3(.44, 1., .88);

float transfer_distance(vec3 point) {
	float grain = sin(point.x * 63. + sin(point.z * 37.)) *
		sin(point.y * 49. + point.z * 29.) * .018;
	return point.y - transfer_floor + grain - (transfer_progress * 2.12 - .10);
}

vec3 transfer_paint(vec3 colour, vec3 point, vec3 normal, vec3 view) {
	float rim = pow(1. - max(0., dot(normalize(normal), normalize(view))), 2.2);
	float scan = pow(.5 + .5 * sin(point.y * 105. - TIME * 7.), 16.);
	float boundary = 1. - smoothstep(0., .09, transfer_distance(point));
	float strength = transfer_charge * (rim * .65 + scan * .045);
	strength += boundary * step(.001, transfer_progress);
	return mix(colour, transfer_colour, clamp(strength, 0., .88)) +
		vec3(.7, .92, .86) * boundary * step(.001, transfer_progress) * .40;
}

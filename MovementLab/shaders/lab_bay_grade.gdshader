shader_type spatial;
render_mode unshaded;

uniform sampler2D bay_art : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D machines : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D windows : source_color, filter_linear_mipmap, repeat_disable;
uniform bool use_inserts = true;
uniform int machine_slot = 0;
uniform int window_slot = 0;

// Coordinates in the original 1536 x 1024 wall artwork, inside the existing frames.
const vec4 MACHINE_OPENING = vec4(167.0, 305.0, 794.0, 794.0);
const vec4 WINDOW_OPENING = vec4(856.0, 354.0, 1392.0, 539.0);

float opening_mask(vec2 pixel, vec4 bounds, float chamfer) {
	vec2 from_edge = min(pixel - bounds.xy, bounds.zw - pixel);
	float distance_inside = min(min(from_edge.x, from_edge.y), (from_edge.x + from_edge.y - chamfer) * 0.707);
	return smoothstep(0.0, 7.0, distance_inside);
}

vec2 cell_origin(int slot, int columns) {
	return vec2(float(slot % columns), float(slot / columns));
}

vec3 insert_color(sampler2D atlas, vec2 pixel, vec4 bounds, vec2 cell, vec2 grid, vec2 dx, vec2 dy) {
	vec2 span = bounds.zw - bounds.xy;
	// Inset each tile slightly to avoid borrowing pixels from its neighbours.
	vec2 local = mix(vec2(0.025), vec2(0.975), (pixel - bounds.xy) / span);
	return textureGrad(atlas, (cell + local) / grid, dx / (span * grid), dy / (span * grid)).rgb;
}

void fragment() {
	vec3 paint = texture(bay_art, UV).rgb;
	vec2 pixel = UV * vec2(1536.0, 1024.0);
	vec2 dx = dFdx(pixel);
	vec2 dy = dFdy(pixel);
	float machine_mask = opening_mask(pixel, MACHINE_OPENING, 55.0);
	float window_mask = opening_mask(pixel, WINDOW_OPENING, 27.0);
	if (use_inserts && machine_mask > 0.0) {
		vec3 machine = insert_color(machines, pixel, MACHINE_OPENING, cell_origin(machine_slot, 3), vec2(3.0, 2.0), dx, dy);
		paint = mix(paint, machine, machine_mask);
	}
	if (use_inserts && window_mask > 0.0) {
		vec3 room = insert_color(windows, pixel, WINDOW_OPENING, cell_origin(window_slot, 2), vec2(2.0, 4.0), dx, dy);
		paint = mix(paint, room, window_mask);
	}
	float warmth = smoothstep(0.025, 0.18, paint.r - paint.b);
	float lamp = smoothstep(0.66, 0.98, paint.r);
	float value = dot(paint, vec3(0.2126, 0.7152, 0.0722));
	vec3 neutral = vec3(value) * vec3(0.985, 1.0, 1.045);
	ALBEDO = mix(paint, neutral, warmth * mix(0.58, 0.22, lamp));
}

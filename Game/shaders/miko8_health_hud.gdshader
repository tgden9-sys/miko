shader_type canvas_item;
render_mode unshaded;
uniform float health : hint_range(0.0, 1.0) = 1.0;
uniform int polarity = 0;
uniform bool hostile = false;

float rounded_box(vec2 point, vec2 half_size, float radius) {
	vec2 q = abs(point) - half_size + radius;
	return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
}
float line_distance(vec2 point, vec2 start, vec2 end) {
	vec2 direction = end - start;
	float along = clamp(dot(point - start, direction) / dot(direction, direction), 0.0, 1.0);
	return length(point - start - direction * along);
}
float coverage(float distance, float aa) {
	return 1.0 - smoothstep(-aa, aa, distance);
}
void paint(inout vec4 canvas, vec3 color, float opacity) {
	canvas.rgb = color * opacity + canvas.rgb * (1.0 - opacity);
	canvas.a = opacity + canvas.a * (1.0 - opacity);
}

void fragment() {
	vec2 p = (UV - 0.5) * (hostile ? vec2(48.0, 22.0) : vec2(54.0, 24.0));
	if (!hostile) { p.x += 4.5; }
	float aa = max(fwidth(p.x) * 0.55, 0.06);
	vec3 accent = vec3(0.49, 0.87, 0.74);
	if (polarity == 1) { accent = vec3(1.0, 0.30, 0.24); }
	if (polarity == 2) { accent = vec3(0.22, 0.71, 1.0); }
	if (hostile) { accent = vec3(1.0, 0.30, 0.24); }
	// Keep the charge badge separate from the four health cells.
	float shell_x = hostile ? abs(p.x) : abs(p.x + 6.5);
	float shell_width = hostile ? 20.0 : 13.5;
	float shell = max(shell_x - shell_width, abs(p.y) - 5.0);
	shell = max(shell, (shell_x + abs(p.y) - (shell_width + 2.8)) * 0.7071);
	vec4 result = vec4(0.0);
	paint(result, vec3(0.01, 0.03, 0.045), coverage(shell - 0.8, aa) * 0.55);
	paint(result, vec3(0.035, 0.075, 0.10), coverage(shell, aa) * 0.95);
	float edge = coverage(abs(shell + 0.35) - 0.25, aa);
	paint(result, mix(vec3(0.20, 0.34, 0.39), vec3(0.53, 0.70, 0.73), 1.0 - smoothstep(-5.0, 2.0, p.y)), edge * 0.85);
	for (int i = 0; i < 4; i++) {
		vec2 cell = p - vec2(-15.0 + float(i) * 5.8, 0.0);
		cell.x -= cell.y * 0.18;
		float shape = rounded_box(cell, vec2(2.15, 2.25), 0.5);
		float inside = coverage(shape, aa);
		paint(result, vec3(0.13, 0.23, 0.25), inside);
		float fraction = clamp(health * 4.0 - float(i), 0.0, 1.0);
		float fill = coverage(cell.x - mix(-2.15, 2.15, fraction), aa) * step(0.001, fraction);
		float glow = exp(-max(shape, 0.0) * 1.6) * fill * 0.09;
		paint(result, hostile ? accent : vec3(0.30, 1.0, 0.48), glow);
		vec3 low = hostile ? vec3(0.75, 0.14, 0.11) : vec3(0.20, 0.64, 0.29);
		vec3 high = hostile ? vec3(1.0, 0.59, 0.48) : vec3(0.70, 1.0, 0.69);
		vec3 cell_color = mix(low, high, clamp(0.65 - cell.y * 0.25, 0.0, 1.0));
		paint(result, cell_color, inside * fill);
	}
	if (hostile) {
		float separator = coverage(line_distance(p, vec2(7.3, -3.5), vec2(7.3, 3.5)) - 0.3, aa);
		paint(result, vec3(0.28, 0.42, 0.47), separator);
		float compartment = coverage(rounded_box(p - vec2(13.0, 0.0), vec2(5.0, 3.8), 1.0), aa);
		paint(result, accent, compartment * 0.10);
		vec2 mark = p - vec2(13.2, 0.0);
		float symbol = abs((abs(mark.x) + abs(mark.y) - 2.2) * 0.7071) - 0.42;
		paint(result, mix(accent, vec3(1.0), 0.28), coverage(symbol, aa));
		float rail = line_distance(p, vec2(8.5, 5.1), vec2(17.4, 5.1)) - 0.50;
		paint(result, accent, coverage(rail, aa));
	} else {
		vec2 mark = p - vec2(20.0, 0.0);
		vec3 badge_color = vec3(0.83, 0.85, 0.83);
		if (polarity == 1) { badge_color = vec3(1.0, 0.48, 0.40); }
		if (polarity == 2) { badge_color = vec3(0.34, 0.66, 1.0); }
		float badge = max(abs(mark.x) - 8.0, abs(mark.y) - 7.0);
		badge = max(badge, (abs(mark.x) + abs(mark.y) - 12.0) * 0.7071);
		paint(result, vec3(0.015, 0.025, 0.04), coverage(badge - 1.2, aa));
		paint(result, badge_color, coverage(badge, aa));
		float symbol = line_distance(mark, vec2(-3.9, 0.0), vec2(3.9, 0.0));
		if (polarity == 0) {
			float uprights = max(abs(abs(mark.x) - 3.0), abs(mark.y) - 3.8);
			symbol = min(uprights, line_distance(mark, vec2(-3.0, -3.8), vec2(3.0, 3.8)));
		} else if (polarity == 1) {
			symbol = min(symbol, line_distance(mark, vec2(0.0, -3.9), vec2(0.0, 3.9)));
		}
		paint(result, vec3(0.015, 0.035, 0.07), coverage(symbol - 1.15, aa));
	}
	COLOR = vec4(result.rgb / max(result.a, 0.001), result.a);
}

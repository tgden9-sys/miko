shader_type canvas_item;
render_mode unshaded;

uniform float flow_time = 0.0;
uniform float thrust : hint_range(0.0, 1.0) = 0.2;
uniform int style = 2;
uniform float wind = 0.0;
uniform float clearance = 1.0;
uniform int suit_polarity = 0;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 345.45));
	p += dot(p, p + 34.345);
	return fract(p.x * p.y);
}
float noise(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1,0)), f.x), mix(hash(i + vec2(0,1)), hash(i + vec2(1,1)), f.x), f.y);
}
float fbm(vec2 p) {
	float v = 0.0, a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += noise(p) * a;
		p = mat2(vec2(1.6,1.2), vec2(-1.2,1.6)) * p + 2.73;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	float t = flow_time;
	float power = thrust;
	// The exhaust is one continuous advected density field, not particle dots.
	float reach = mix(0.34, 0.95, power);
	float y = UV.y / reach;
	float x = (UV.x - 0.5) * 2.0;
	float speed = mix(0.6, 1.7, power);
	vec2 flow = vec2(x * 4.0, y * 4.7 - t * speed);
	float curl = fbm(flow + vec2(0, t * 0.08)) - 0.5;
	float bend = sin(y * 8.0 - t * 1.7) * 0.055 * y;
	float width = 0.20 + y * 0.27;
	float distortion = curl * 0.32 * y + bend - wind * y * y;
	float envelope = 1.0 - smoothstep(width * 0.35, width * 1.5, abs(x + distortion));
	float density = fbm(flow + curl * 2.0);
	float fade = (1.0 - smoothstep(0.30, 1.0, y));
	float smoke = envelope * smoothstep(0.23, 0.75, density) * fade;
	vec3 smoke_col = mix(vec3(0.34, 0.40, 0.48), vec3(0.67, 0.73, 0.78), density);
	float smoke_alpha = smoke * mix(0.27, 0.57, power);
	// Blue mode is an elongated gas plume with turbulent edges, no sparks.
	float jet_len = mix(0.24, 0.78, power);
	float jy = UV.y / jet_len;
	float jet_width = 0.205 * (1.0 - smoothstep(0.04, 1.0, jy));
	float jitter = (noise(vec2(jy * 14.0 - t * 6.0, t * 2.0)) - 0.5) * 0.12 * jy;
	float flame_noise = fbm(vec2(x * 18.0, jy * 11.0 - t * 5.0));
	float edge_noise = (flame_noise - 0.5) * 0.075 * smoothstep(0.0, 0.15, jy);
	float jet = (1.0 - smoothstep(jet_width * 0.65 + edge_noise, jet_width + 0.035 + edge_noise, abs(x + jitter))) * (1.0 - smoothstep(0.25, 1.0, jy));
	float halo = exp(-abs(x + jitter) * 8.0) * (1.0 - smoothstep(0.0, 0.8, jy)) * 0.12;
	float hot_core = jet * (0.65 + flame_noise * 0.35);
	vec3 jet_col = mix(vec3(0.10,0.39,0.79), vec3(0.64,0.91,1.0), pow(hot_core, 2.0));
	if (suit_polarity == 1) {
		jet_col = mix(vec3(0.85, 0.06, 0.13), vec3(1.0, 0.55, 0.42), pow(hot_core, 2.0));
	} else if (suit_polarity == 2) {
		jet_col = mix(vec3(0.04, 0.34, 1.0), vec3(0.38, 0.82, 1.0), pow(hot_core, 2.0));
	}
	if (style == 0) {
		COLOR = vec4(smoke_col, smoke_alpha);
	} else if (style == 1) {
		COLOR = vec4(jet_col, clamp(jet * 0.85 + halo, 0.0, 0.9));
	} else {
		float hot = jet * 0.85;
		vec3 hot_col = mix(jet_col, suit_polarity == 1 ? vec3(1.0, 0.84, 0.75) : vec3(0.87,0.98,1.0), pow(hot_core, 4.0));
		COLOR = vec4(mix(smoke_col, hot_col, hot), clamp(smoke_alpha * 0.8 + hot + halo * 0.4, 0.0, 0.95));
	}
	// Exhaust dissipates at nearby floors/platforms instead of drawing through them.
	COLOR.a *= 1.0 - smoothstep(max(0.0, clearance - 0.05), clearance, UV.y);
}

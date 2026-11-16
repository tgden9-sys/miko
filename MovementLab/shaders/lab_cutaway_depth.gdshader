shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 spill_tint : source_color = vec4(.72,.84,.86,1.0);

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(cell), hash(cell + vec2(1.0, 0.0)), f.x),
		mix(hash(cell + vec2(0.0, 1.0)), hash(cell + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	float time = TIME + UV2.x * .47;
	float x = UV.x;
	float y = UV.y;
	// A broad layer clings to the lip. Slow crossflow stretches it into the dark.
	float drift = .065 * sin(time*.44) + .027 * sin(time*.81 + 1.1);
	float travel = x - (.46 + drift);
	float along = travel / (travel < 0.0 ? .17 : .31);
	float height = .34 + .13 * smoothstep(.36,.92,x)
		+ .047 * sin(x*7.1-time*.62);
	float thickness = mix(.115,.20,smoothstep(.29,.91,x));
	float vertical = (y-height)/thickness;
	float sheet = exp(-along*along*1.45 - vertical*vertical);
	vec2 flow = vec2(x*7.5-time*.62,y*3.0+sin(time*.36)*.17);
	float wisps = mix(noise(flow),noise(flow*1.83+vec2(9.4,2.7)),.27);
	float density = .21 + .28 * smoothstep(.24,.81,wisps);
	float fade = smoothstep(.035,.20,x) * (1.0-smoothstep(.78,1.0,x))
		* smoothstep(.075,.23,y) * (1.0-smoothstep(.64,.94,y));
	ALBEDO = mix(vec3(.55),spill_tint.rgb,.58);
	ALPHA = sheet * density * fade;
}

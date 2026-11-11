shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;

varying vec4 particle_color;
varying float kind;

void vertex() {
	particle_color = COLOR;
	kind = INSTANCE_CUSTOM.x;
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float radius = length(p);
	float shape;
	if (kind < .5) {
		float edge = radius + sin(p.x*9.0 + p.y*7.0)*.075;
		shape = 1.0 - smoothstep(.14, 1.0, edge);
		shape *= shape;
	} else if (kind < 1.5) {
		shape = (1.0 - smoothstep(.15, 1.0, abs(p.y))) * smoothstep(-1.0,.7,p.x) * (1.0-smoothstep(.78,1.0,p.x));
	} else {
		shape = smoothstep(.62,.73,radius) * (1.0-smoothstep(.78,.94,radius));
	}
	ALBEDO = particle_color.rgb;
	ALPHA = particle_color.a * shape;
}

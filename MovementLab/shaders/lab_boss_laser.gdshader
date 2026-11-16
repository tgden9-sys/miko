shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform float span = 20.0;
uniform float power = 1.0;
uniform float direction = -1.0;

void fragment() {
	float along = (direction < 0.0 ? 1.0 - UV.x : UV.x) * span;
	float across = abs(UV.y - .5);
	float aa = max(fwidth(across), .001);
	float packet = pow(max(0.0, sin(along * 1.7 - TIME * 71.0)), 7.0);
	float ripple = sin(along * 9.7 - TIME * 87.0) * sin(along * 3.4 + TIME * 33.0);
	float core = 1.0 - smoothstep(.024, .041 + aa, across);
	float sheath = exp(-pow(across / (.082 + .027 * packet), 2.0));
	float corona = exp(-pow(across / .235, 2.0));
	float filament = 1.0 - smoothstep(.005, .014 + aa, abs(across - (.099 + ripple * .025)));
	float pulse = .83 + .17 * packet;
	vec3 hot = vec3(1.0, .88, .83) * core * .99;
	vec3 plasma = vec3(1.0, .053, .128) * (sheath * pulse + corona * (.26 + packet * .17));
	vec3 edges = vec3(1.0, .21, .29) * filament * (.21 + .44 * packet);
	ALBEDO = hot + plasma + edges;
	ALPHA = power * (1.0 - smoothstep(.37, .5, across));
}

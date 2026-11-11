shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;

uniform float age = 0.0;
uniform float duration = 0.16;
uniform int variant = 0; // 0: SwordA (horizontal), 1: SwordB (diagonal), 2: SwordC (cleave), 3: Uppercut (vertical)
uniform int facing = 1;

void fragment() {
	vec2 p = (UV - vec2(0.5, 0.5)) * 2.0;
	p.x *= float(facing);
	
	// Orient according to attack type
	float rot = 0.0;
	if (variant == 1) {
		rot = 0.55; // ~31 deg diagonal
	} else if (variant == 3) {
		rot = 1.48; // ~85 deg vertical uppercut
	}
	if (rot != 0.0) {
		float c = cos(rot);
		float s = sin(rot);
		p = vec2(p.x * c - p.y * s, p.x * s + p.y * c);
	}
	
	// Center at hilt reference
	vec2 center = vec2(-0.35, 0.0);
	vec2 delta = p - center;
	float r = length(delta);
	float theta = atan(delta.y, delta.x);
	
	// Angular bounds (cel graphic wedge)
	float max_angle = (variant == 2) ? 2.35 : 1.60;
	if (abs(theta) > max_angle) {
		discard;
	}
	
	// Taper profile to clean geometric points
	float angle_norm = theta / max_angle;
	float taper = cos(angle_norm * 1.5707963);
	taper = pow(max(0.0, taper), 0.65);
	
	// Target arc radius and thickness
	float arc_r = (variant == 2) ? 0.70 : 0.62;
	float base_width = (variant == 2) ? 0.25 : 0.19;
	float width = base_width * taper;
	
	float dist = abs(r - arc_r);
	if (dist > width) {
		discard;
	}
	
	// Stepped comic speed notches cut into the outer trailing edge
	float notch = step(0.68, sin(theta * 20.0 + r * 35.0));
	float norm_d = dist / max(width, 0.001);
	if (norm_d > 0.62 && notch > 0.5) {
		discard;
	}
	
	// Timing and progressive graphic shrink/erode
	float t = clamp(age / max(duration, 0.001), 0.0, 1.0);
	if (t > 0.92) {
		discard;
	}
	// Geometric shrink towards the tip as it dissipates
	if (t > 0.35) {
		float shrink_factor = (t - 0.35) / 0.65;
		if (norm_d > (1.0 - shrink_factor * 0.85)) {
			discard;
		}
	}
	
	// Three-tone cel palette matching Miko's character shader
	vec3 ink_black = vec3(0.09, 0.14, 0.15);      // Deep slate ink boundary
	vec3 shadow_tone = vec3(0.18, 0.42, 0.38);    // Cel shadow band
	vec3 cel_mint = vec3(0.42, 0.88, 0.74);       // Primary cel mint
	vec3 highlight_cream = vec3(0.96, 1.0, 0.98); // Solid white cutting highlight
	
	// Variant 2 (Heavy finisher) gets three-tone cel gold
	if (variant == 2) {
		cel_mint = vec3(0.92, 0.74, 0.22);
		shadow_tone = vec3(0.52, 0.38, 0.10);
	}
	
	// Hard-stepped cel transitions (no blurry gradients)
	vec3 col;
	if (norm_d > 0.82) {
		col = ink_black;
	} else if (norm_d > 0.45) {
		col = shadow_tone;
	} else if (norm_d > 0.16) {
		col = cel_mint;
	} else {
		col = highlight_cream;
	}
	
	ALBEDO = col;
	ALPHA = 1.0;
}

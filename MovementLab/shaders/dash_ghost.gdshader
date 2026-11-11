shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;

// Cel Dash Ghost / Afterimage Shader
// Renders a luminous cybernetic silhouette of Miko during dashes.
// Features:
// - Luminous Fresnel rim outlining character geometry and katana
// - Deep stylized teal core with subtle holographic scanline
// - Controlled transparency fading smoothly over time
// - Unshaded cel aesthetic matching the game's art style

uniform vec3 ghost_color = vec3(0.28, 0.96, 0.88);
uniform vec3 rim_color = vec3(1.0, 1.0, 1.0);
uniform vec3 shadow_color = vec3(0.04, 0.15, 0.22);
uniform float alpha_fade = 0.20;

void fragment() {
	// Surface normal to camera angle (Fresnel rim)
	float fresnel = 1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0);
	float rim = pow(fresnel, 2.0);
	
	// Subtle cybernetic scanline texture
	float scanline = sin(UV.y * 120.0) * 0.08 + 0.92;
	
	// Cel tonal layers: deep core -> vibrant cyan -> white razor rim
	vec3 core_mix = mix(shadow_color, ghost_color, smoothstep(0.12, 0.55, fresnel));
	vec3 final_color = mix(core_mix, rim_color, smoothstep(0.68, 0.95, rim)) * scanline;
	
	// Luminous rim opacity boost
	float silhouette_alpha = mix(0.35, 1.0, smoothstep(0.25, 0.80, rim));
	float total_alpha = silhouette_alpha * alpha_fade;
	
	ALBEDO = final_color;
	ALPHA = clamp(total_alpha, 0.0, 1.0);
}

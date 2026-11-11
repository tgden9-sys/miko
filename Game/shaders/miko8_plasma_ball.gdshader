shader_type spatial;
render_mode unshaded;
uniform float opacity = 1.0;
void fragment() {
    float facing = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
    float ripple = sin(UV.x * 45.0 + UV.y * 24.0 - TIME * 5.0) * 0.04;
    vec3 energy = mix(vec3(0.18,0.025,0.35), vec3(0.77,0.42,1.0), clamp(pow(facing, 1.5) + ripple,0.0,1.0));
    ALBEDO = energy;
    EMISSION = energy * 0.18;
    ALPHA = opacity < 0.5 ? opacity * pow(facing, 1.6) : 1.0;
}

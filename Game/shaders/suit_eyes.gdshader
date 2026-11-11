shader_type canvas_item;

uniform int polarity = 0;
uniform vec4 red_color : source_color = vec4(1.0, 0.19, 0.25, 1.0);
uniform vec4 blue_color : source_color = vec4(0.14, 0.66, 1.0, 1.0);

void fragment() {
	vec4 original = texture(TEXTURE, UV) * COLOR;
	// The rendered eyes are the bright, cool-white islands in the dark faceplate.
	// Armour and scarf pixels keep their original material colour.
	float bright = min(original.r, min(original.g, original.b));
	float eye = smoothstep(0.48, 0.72, bright);
	eye *= float(polarity != 0 && UV.y > 0.32 && UV.y < 0.51 && UV.x > 0.18 && UV.x < 0.82);
	vec3 chosen = polarity == 1 ? red_color.rgb : blue_color.rgb;
	vec3 lit = chosen * 1.15;
	COLOR = vec4(mix(original.rgb, lit, eye), original.a);
}

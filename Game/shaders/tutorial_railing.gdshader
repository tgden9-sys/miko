shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform sampler2D art : source_color, repeat_enable, filter_linear_mipmap;
uniform float repeats=1.0;
uniform bool end_post=false;
void fragment(){
 float x=end_post?mix(0.465,0.535,UV.x):mix(0.035,0.50,fract(UV.x*repeats));
 vec4 color=texture(art,vec2(x,mix(0.16,0.84,UV.y)));
 ALBEDO=color.rgb;
 ALPHA=color.a;
 ALPHA_SCISSOR_THRESHOLD=0.10;
}

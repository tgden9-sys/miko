shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, depth_prepass_alpha;
uniform sampler2D art : source_color, filter_linear_mipmap_anisotropic;
uniform vec2 vertical_range=vec2(0.0,1.0);
uniform vec2 horizontal_range=vec2(0.0,1.0);
void fragment(){
 vec2 uv=vec2(mix(horizontal_range.x,horizontal_range.y,UV.x),mix(vertical_range.x,vertical_range.y,UV.y));
 vec4 paint=texture(art,uv);
 ALBEDO=paint.rgb;
 ALPHA=smoothstep(0.15,0.85,paint.a);
}

shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform sampler2D art : source_color, filter_linear_mipmap;
uniform vec2 vertical_crop=vec2(0.0,1.0);
uniform float blur_lod=2.3;
void fragment(){
 vec4 color=textureLod(art,vec2(UV.x,mix(vertical_crop.x,vertical_crop.y,UV.y)),blur_lod);
 ALBEDO=color.rgb;
 ALPHA=color.a*0.94;
}

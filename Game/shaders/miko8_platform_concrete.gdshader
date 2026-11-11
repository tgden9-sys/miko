shader_type spatial;
render_mode unshaded, shadows_disabled;
uniform sampler2D art:source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform float width_metres=7.05;
uniform float height_metres=.40;
void fragment(){
 // Reuse the upper concrete band at its original six-by-two metre scale.
 // Pipework below this band is deliberately outside the UV crop.
 vec2 uv=vec2(UV.x*width_metres/6.0,UV.y*height_metres/2.0);
 ALBEDO=texture(art,uv).rgb;
}

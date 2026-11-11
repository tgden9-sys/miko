shader_type spatial;
render_mode unshaded, cull_disabled;
uniform sampler2D art : source_color, filter_linear_mipmap_anisotropic;
uniform vec2 horizontal_range=vec2(0.0,1.0);
uniform vec2 vertical_range=vec2(0.0,1.0);
void fragment(){
 vec3 paint=texture(art,vec2(mix(horizontal_range.x,horizontal_range.y,UV.x),mix(vertical_range.x,vertical_range.y,UV.y))).rgb;
 float warm=smoothstep(0.05,0.30,paint.r-paint.b);
 ALBEDO=paint*mix(vec3(0.46,0.53,0.77),vec3(0.83,0.72,0.65),warm);
}

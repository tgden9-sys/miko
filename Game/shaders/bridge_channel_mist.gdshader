shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;
void fragment(){
 float edge=smoothstep(0.0,0.18,UV.x)*(1.0-smoothstep(0.82,1.0,UV.x));
 float vertical=sin(UV.y*3.14159265);
 float drift=0.5+0.5*sin(UV.x*15.0+sin(UV.y*8.0)+TIME*0.07);
 float layers=0.5+0.5*sin(UV.x*8.0-UV.y*7.0-TIME*0.04);
 ALBEDO=vec3(0.20,0.27,0.35);
 ALPHA=edge*vertical*(0.25+drift*layers*0.75)*0.055;
}

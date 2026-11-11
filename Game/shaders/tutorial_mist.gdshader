shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform float strength=0.10;
void fragment(){
 vec2 p=UV*vec2(7.0,3.0);
 float drift=sin(p.x+TIME*0.035+sin(p.y*1.7))*0.5+0.5;
 float layers=sin(p.x*1.9-TIME*0.026+p.y*2.0)*0.5+0.5;
 float vertical=sin(UV.y*3.14159265);
 ALBEDO=vec3(0.56,0.63,0.73);
 ALPHA=(0.25+drift*layers*0.65)*vertical*strength;
}

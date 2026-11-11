shader_type spatial;
render_mode unshaded;
void fragment(){
 float flow=pow(.5+.5*sin(UV.x*35.-TIME*4.+sin(UV.y*13.+TIME*2.)),5.);
 ALBEDO=mix(vec3(.04,.55,.43),vec3(.75,1.,.93),flow);
 EMISSION=vec3(.12,.6,.46)*.25;
}

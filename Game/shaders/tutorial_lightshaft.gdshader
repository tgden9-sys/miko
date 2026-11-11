shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, blend_add;
void fragment(){
 float x=UV.x+UV.y*0.35;
 float ray=exp(-pow((x-0.55)/0.12,2.0)*2.0);
 float fade=sin(UV.y*3.14159);
 ALBEDO=vec3(0.72,0.46,0.20);
 ALPHA=ray*fade*0.045;
}

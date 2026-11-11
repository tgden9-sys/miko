shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;
void fragment(){
 float rise=1.0-UV.y;
 float centre=0.5+sin(rise*6.0-TIME*0.6)*0.075;
 float wisp=exp(-pow((UV.x-centre)/(0.10+rise*0.28),2.0)*3.0);
 float folds=0.6+0.4*sin(UV.x*19.0+rise*15.0-TIME*0.85);
 float ends=smoothstep(0.0,0.16,rise)*(1.0-smoothstep(0.3,1.0,rise));
 ALBEDO=vec3(0.68,0.75,0.79);
 ALPHA=wisp*folds*ends*0.15;
}

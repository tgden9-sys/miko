shader_type spatial;
render_mode unshaded, shadows_disabled, cull_disabled, depth_draw_never;
uniform bool mirror_x=false;
// Union of the main footprint and the set-back return; the open ladder bay
// stays open instead of receiving an incorrect rectangular black shadow.
float box_outside(vec2 p,vec2 centre,vec2 size){return length(max(abs(p-centre)-size*.5,vec2(0.0)));}
void fragment(){
 vec2 p=(UV-.5)*vec2(8.0,4.1);
 if(mirror_x){p.x=-p.x;}
 float d=min(box_outside(p,vec2(1.15,0.0),vec2(4.50,2.8)),box_outside(p,vec2(-2.25,-.73),vec2(2.30,1.34)));
 ALBEDO=vec3(.012,.017,.024);
 float contact=.68*(.70*exp(-d*28.)+.30*exp(-d*7.))*(1.-smoothstep(.28,.50,d));
 vec2 q=p-vec2(.23,.20);
 float cast=min(box_outside(q,vec2(1.15,0.0),vec2(4.50,2.8)),box_outside(q,vec2(-2.25,-.73),vec2(2.30,1.34)));
 ALPHA=max(contact,.20*exp(-cast*8.)*(1.-smoothstep(.18,.46,cast)));
}

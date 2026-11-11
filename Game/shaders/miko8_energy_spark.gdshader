shader_type spatial;
render_mode unshaded,blend_add,cull_disabled,depth_draw_never,shadows_disabled;
void fragment(){
 vec2 p=abs(UV-.5)*2.;
 float diamond=1.-smoothstep(.25,1.,p.x+p.y);
 float core=1.-smoothstep(.08,.28,length(p));
 ALBEDO=mix(COLOR.rgb,vec3(.8,1.,.95),core*.5);
 EMISSION=COLOR.rgb*.35;
 ALPHA=COLOR.a*max(diamond,core);
}

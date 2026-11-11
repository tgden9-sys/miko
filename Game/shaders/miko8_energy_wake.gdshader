shader_type spatial;
render_mode unshaded,blend_add,cull_disabled,depth_draw_never,shadows_disabled;
void fragment(){
 float edge=abs(UV.x-.5)*2.;
 float core=1.-smoothstep(.08,.36,edge);
 float halo=1.-smoothstep(.10,1.,edge);
 ALBEDO=mix(COLOR.rgb,vec3(.85,1.,.96),core*.35);
 EMISSION=COLOR.rgb*.7;
 ALPHA=COLOR.a*(core*.9+halo*.28);
}

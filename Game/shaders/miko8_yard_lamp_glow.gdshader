shader_type spatial;
render_mode unshaded,blend_add,cull_disabled,depth_draw_never,shadows_disabled;
uniform vec3 tint:source_color=vec3(1.0,.57,.22);
uniform float opacity=.18;
void fragment(){
 vec2 p=(UV-.5)*2.;float r=dot(p,p);
 float halo=exp(-r*4.0)*(1.-smoothstep(.55,1.,r));
 ALBEDO=tint;ALPHA=halo*opacity;
}

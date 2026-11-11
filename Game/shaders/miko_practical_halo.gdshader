shader_type spatial;
render_mode unshaded,cull_disabled,depth_draw_never,shadows_disabled,blend_add;
uniform vec4 tint:source_color=vec4(1.0,0.6,0.24,1.0);
uniform float strength=0.18;
void fragment(){
 float r=length((UV-0.5)*2.0);
 float glow=exp(-r*r*7.0)*(1.0-smoothstep(0.5,1.0,r));
 ALBEDO=tint.rgb;ALPHA=glow*strength;
}

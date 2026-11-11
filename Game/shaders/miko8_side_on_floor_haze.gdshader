shader_type spatial;
render_mode unshaded,cull_disabled,depth_draw_never,shadows_disabled;
uniform float opacity=.10;
uniform float phase=0.0;
void fragment(){
 float h=1.0-UV.y;
 float wave=.26+sin(UV.x*11.0-TIME*.24+phase)*.08;
 float ribbon=exp(-pow((h-wave)/.18,2.0));
 float flow=.55+.25*sin(UV.x*19.0-TIME*.40+sin(UV.x*7.0+TIME*.12)+phase);
 float edges=smoothstep(0,.14,UV.x)*(1.0-smoothstep(.86,1.0,UV.x));
 ALBEDO=vec3(.48,.53,.56);
 ALPHA=opacity*ribbon*flow*edges*(1.0-smoothstep(.55,.9,h));
}

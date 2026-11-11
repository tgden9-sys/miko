shader_type spatial;
render_mode unshaded, shadows_disabled, cull_disabled, depth_draw_never;
uniform vec2 footprint=vec2(6.4,3.0);
uniform vec2 plane_size=vec2(7.6,4.2);
uniform float opacity=.52;
void fragment(){
 vec2 point=(UV-.5)*plane_size;
 vec2 outside=max(abs(point)-footprint*.5,vec2(0.));
 float distance_to_wall=length(outside);
 float tight=exp(-distance_to_wall*15.);
 float soft=exp(-distance_to_wall*5.);
 float fade=1.-smoothstep(.38,.6,distance_to_wall);
 ALBEDO=vec3(.018,.022,.028);
 ALPHA=opacity*(tight*.72+soft*.28)*fade;
}

shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, shadows_disabled, depth_draw_never;
void fragment(){
 vec2 p=(UV-.5)*2.;
 float r=length(p);
 float a=atan(p.y,p.x+.00001);
 float arc_radius=.59+.055*sin(a*3.+TIME*5.)+.022*sin(a*7.-TIME*8.);
 float arc=exp(-abs(r-arc_radius)*120.);
 float gaps=smoothstep(-.35,.25,sin(a*3.-TIME*4.));
 float outer=exp(-abs(r-(.77+.035*sin(a*5.-TIME*3.)))*95.);
 float veins=arc*gaps+outer*smoothstep(.35,.8,sin(a*4.+TIME*3.))*.50;
 float haze=exp(-r*r*7.)*.17;
 ALBEDO=mix(vec3(.40,.07,.95),vec3(.90,.67,1.),clamp(veins,0.,1.));
 ALPHA=clamp(veins*.85+haze,0.,1.)*(1.-smoothstep(.9,1.,r));
}

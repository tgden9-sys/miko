shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, shadows_disabled, depth_draw_never;
uniform vec4 tint:source_color=vec4(.7,.3,1.,1.);
uniform float travel_age=0.0;
uniform bool quick=false;
void fragment(){
 float x=UV.x;
 float across=abs(UV.y-.5)*2.;
 float envelope=pow(x,.65)*(1.-smoothstep(.94,1.,x));
 float width=(quick?.36:.43)*pow(x,.65);
 float body=exp(-pow(across/max(width,.01),2.)*4.);
 float filament=exp(-abs(across-(.20+.08*sin(x*18.-TIME*23.))*(1.-x))*75.);
 float nose=exp(-pow((x-.88)*12.,2.)-across*across*45.);
 float core=body*.55+nose;
 ALBEDO=mix(tint.rgb,vec3(.92,1.,.96),clamp(core,0.,1.));
 float halo=quick?exp(-across*across*8.)*.22:0.;
 ALPHA=clamp((core+halo+filament*(quick?.28:.5))*envelope*(quick?2.4:1.8),0.,1.)*smoothstep(0.,.025,travel_age);
}

shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, shadows_disabled, depth_draw_never;
uniform float progress=0.0;
uniform vec4 tint : source_color = vec4(.56,.12,1.,1.);
void fragment(){
 vec2 p=(UV-.5)*2.;
 float r=length(p);
 float a=atan(p.y,p.x+.00001);
 float expansion=1.-pow(1.-progress,3.);
 float ring=exp(-abs(r-(.08+expansion*.78))*90.);
 float broken=ring*(.45+.55*smoothstep(-.3,.4,sin(a*7.+r*20.)));
 float flash=exp(-r*r*32.)*pow(1.-progress,5.)*2.;
 float rays=pow(abs(sin(a*5.+.4)),28.)*exp(-r*4.)*(1.-progress)*.55;
 ALBEDO=mix(tint.rgb,vec3(1.),clamp(flash+broken*.5,0.,1.));
 ALPHA=clamp((broken*.75+flash+rays)*pow(1.-progress,1.3),0.,1.);
}

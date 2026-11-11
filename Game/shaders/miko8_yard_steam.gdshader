shader_type spatial;
render_mode unshaded,cull_disabled,depth_draw_never,shadows_disabled;
varying float seed;
varying float age;
void vertex(){seed=INSTANCE_CUSTOM.g;age=INSTANCE_CUSTOM.r;}
void fragment(){
 vec2 p=(UV-.5)*2.;
 p.x+=sin(p.y*4.+age*4.+seed*6.28)*.065*(1.-abs(p.y));
 float r=min(length((p-vec2(-.24,.02))*vec2(1.3,1.05)),length((p-vec2(.23,-.05))*vec2(1.3,1.15)));
 r=min(r,length((p-vec2(.02,.26))*vec2(1.7,1.5)));
 float rim=1.-smoothstep(.55,.91,r);
 float fold=.88+.12*sin(p.x*5.+p.y*4.+seed*6.28);
 float light=-p.x-p.y*.4+.12*sin(p.y*5.+seed*6.28);
 vec3 tone=mix(vec3(.40,.49,.54),vec3(.66,.75,.77),smoothstep(-.26,-.10,light));
 tone=mix(tone,vec3(.85,.89,.88),smoothstep(.46,.64,light));
 ALBEDO=tone*COLOR.rgb;ALPHA=COLOR.a*rim*fold;
}

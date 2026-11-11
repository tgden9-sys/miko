shader_type spatial;
render_mode unshaded,cull_disabled,depth_draw_never;
uniform float strength=0.;
float rectangle(vec2 p,vec2 half_size){
 vec2 q=abs(p)-half_size;
 return length(max(q,vec2(0.)))+min(max(q.x,q.y),0.);
}
void fragment(){
 vec2 p=(UV-.5)*vec2(2.7,2.3);
 float inner=abs(rectangle(p,vec2(.88,.67)));
 float outer=abs(rectangle(p,vec2(1.22,1.02)));
 float line=(1.-smoothstep(.008,.024,inner))+.45*(1.-smoothstep(.006,.018,outer));
 float halo=exp(-inner*20.)*.36+exp(-outer*26.)*.20;
 float pulse=.82+.18*sin(TIME*4.2);
 ALBEDO=vec3(.55,.11,1.);
 ALPHA=clamp((line+halo)*strength*pulse,0.,.88);
}

shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;
uniform float age=0.0;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void fragment(){
 vec2 p=vec2((UV.x-.5)*8.,(.833333-UV.y)*3.);
 if(p.y<.012)discard;
 float t=clamp(age/.72,0.,1.);
 float expand=1.-pow(1.-t,2.5);
 float fade=1.-smoothstep(.22,.70,age);
 float n=noise(p*14.+vec2(age*9.,-age*5.));
 float radius=.12+3.3*expand;
 float ellipse=length(vec2(p.x,(p.y-.05)*5.));
 float ring=exp(-pow((ellipse-radius)/.075,2.));
 float ringglow=exp(-pow((ellipse-radius)/.24,2.))*.32;
 // Broad curved pressure fronts, bright leading rim and a blue inner wash.
 float u=abs(p.x)/max(radius,.2);
 float curve=.09+.65*sin(clamp(u,0.,1.)*2.6)*pow(1.-t,.65);
 float thickness=.055+.22*sin(clamp(u,0.,1.)*3.14159);
 float band=(p.y-curve)/thickness;
 float inside=(1.-smoothstep(.86,1.03,u))*smoothstep(.02,.16,u);
 float front=exp(-pow((band-.55)/.19,2.))*inside;
 float wash=exp(-band*band*2.)*inside*.8;
 float pressure=(front+wash)*(1.-smoothstep(.16,.42,age));
 float flash=exp(-dot(p/vec2(.7,.5),p/vec2(.7,.5))*2.)*(1.-smoothstep(.025,.13,age));
 float jet=exp(-pow(p.x/(.055+p.y*.045),2.))*(1.-smoothstep(.8,2.4,p.y))*(1.-smoothstep(.025,.14,age));
 // Turbulent, rounded dust rolls travel away from the contact point.
 float dust=0.;
 for(int i=0;i<8;i++){
  float k=float(i)-3.5;
  vec2 center=vec2(k*.74*expand,.08+.14*sin(float(i)*4.2)+t*.46);
  vec2 d=(p-center)/vec2(.22+t*.65,.16+t*.35);
  dust+=exp(-dot(d,d)*2.)*(.32+.68*n)*.37;
 }
 float electric=(ring+ringglow)*fade+pressure+flash+jet;
 float alpha=clamp(electric+dust*fade,0.,1.);
 float core=clamp(front*(1.-smoothstep(.1,.39,age))+ring*fade+flash+jet,0.,1.);
 vec3 color=mix(vec3(.20,.27,.34),vec3(.16,.43,1.),clamp(electric*2.,0.,1.));
 color=mix(color,vec3(.94,1.,1.),core);
 ALBEDO=color;
 ALPHA=alpha;
}

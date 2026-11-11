shader_type spatial;
render_mode unshaded, shadows_disabled;
uniform vec4 energy_color : source_color=vec4(.65,.15,1.,1.);
uniform float agitation=1.0;
varying vec3 surface_point;
float hash(vec3 p){p=fract(p*.3183099+vec3(.11,.27,.43));p*=17.;return fract(p.x*p.y*p.z*(p.x+p.y+p.z));}
float noise3(vec3 p){vec3 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);}
void vertex(){
 surface_point=VERTEX;
 float churn=agitation>.8?.5+.25*sin(NORMAL.y*6.+TIME*5.)*cos(NORMAL.x*5.-TIME*3.):noise3(NORMAL*4.+vec3(TIME*1.7,-TIME*2.9,TIME*.6));
 VERTEX+=NORMAL*(churn-.5)*.045*agitation;
}
void fragment(){
 vec3 p=surface_point*26.;p.y-=TIME*3.8;
 float n=noise3(p+noise3(p*1.7+TIME)*2.4);
 float cells=abs(sin(n*13.+TIME*1.8));
 float veins=pow(1.-cells,5.);
 float facing=clamp(dot(normalize(NORMAL),normalize(VIEW)),0.,1.);
 float rim=pow(1.-facing,2.1);
 float heat=clamp(veins*.85+pow(facing,7.)*.7,0.,1.);
 vec3 color=mix(energy_color.rgb*(.18+n*.65),vec3(1.,.88,1.),heat);
 color+=energy_color.rgb*rim*.8;
 if(agitation>.8){
   vec3 sphere=normalize(surface_point);
   float angle=atan(sphere.x,sphere.z+.00001);
   float flow=sin(sphere.y*7.+angle*2.+sin(angle*3.-TIME*2.)*.8-TIME*5.);
   float ribbon=smoothstep(.67,.88,flow);
   float heart=pow(facing,4.)*.9;
   float heat_band=max(ribbon*.88,heart);
   color=mix(vec3(.12,.018,.34),energy_color.rgb,smoothstep(-.55,.35,flow)*.7+.3);
   color=mix(color,vec3(1.,.88,1.),heat_band);
   color+=energy_color.rgb*rim*.45;
 }
 ALBEDO=color;EMISSION=color*.65;
}

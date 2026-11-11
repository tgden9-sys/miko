shader_type spatial;
render_mode unshaded,cull_disabled,depth_draw_never,shadows_disabled;
uniform float seed=1.0;
uniform float haze=0.25;
uniform float softness=0.11;
uniform vec4 city_color:source_color=vec4(0.12,0.18,0.28,1.0);
float hash(float x){return fract(sin(x*127.1+seed*37.3)*43758.5453);}
void fragment(){
 vec2 p=vec2(UV.x*60.0,(1.0-UV.y)*18.0);
 float id=floor(p.x);float f=fract(p.x);
 float height=6.0+hash(id)*9.0;
 float body=(1.0-smoothstep(height-softness,height+softness,p.y))*smoothstep(0.0,softness,f)*(1.0-smoothstep(1.0-softness,1.0,f));
 vec3 color=city_color.rgb*(0.82+hash(id+120.0)*0.3);
 float facet=smoothstep(0.65,0.8,f);color*=1.0-facet*0.18;
 vec2 grid=vec2(f*5.0,p.y*2.3);
 vec2 cell=floor(grid);vec2 q=fract(grid)-0.5;
 float lit=step(0.69,hash(id*79.0+cell.x*11.0+cell.y*31.0));
 float radius=mix(0.16,0.39,hash(id*43.0+cell.y));
 float d=length(q*vec2(1.0,1.6));
 float disc=(1.0-smoothstep(radius*0.35,radius+0.17,d))*lit;
 vec3 warm=mix(vec3(0.9,0.43,0.12),vec3(1.0,0.77,0.43),hash(id+cell.y*3.0));
 color=mix(color,warm,disc*0.85);
 color=mix(color,vec3(0.12,0.18,0.28),haze);
 ALBEDO=color;ALPHA=body*0.92;
}

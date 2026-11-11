shader_type spatial;
render_mode unshaded;
#include "res://shaders/miko8_cel_scene_common.gdshaderinc"
uniform vec4 base_color:source_color=vec4(.3,.33,.35,1.);
varying vec3 part_point;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){
 vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);
 return mix(mix(hash(i),hash(i+vec2(1.,0.)),f.x),mix(hash(i+vec2(0.,1.)),hash(i+vec2(1.,1.)),f.x),f.y);
}
void vertex(){part_point=VERTEX;cel_world_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);}
void fragment(){
 vec2 p=part_point.xz;
 float grain=hash(floor(p*170.));
 float patch=noise(p*3.5);
 float brushed=step(.992,fract(p.x*84.))*smoothstep(.72,.84,noise(p*18.));
 vec3 metal=base_color.rgb*mix(.94,1.035,patch)*mix(.985,1.015,grain)+vec3(.018)*brushed;
 ALBEDO=metal*cel_light(cel_world_normal);
}

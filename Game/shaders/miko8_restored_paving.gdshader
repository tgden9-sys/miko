shader_type spatial;
uniform sampler2D grain:source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform float damp_amount=.65;
varying vec3 world_point;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){
 vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void vertex(){world_point=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 vec3 texture_color=texture(grain,world_point.xz*.8).rgb;
 float detail=dot(texture_color,vec3(.333));
 float wet=noise(world_point.xz*.72)*.65+noise(world_point.xz*1.6+vec2(17,29))*.35;
 wet=smoothstep(.60,.79,wet)*damp_amount;
 ALBEDO=mix(vec3(.24,.25,.245),texture_color*.9,.62)*mix(1.0,.73,wet);
 ROUGHNESS=mix(.91,.34,wet);METALLIC=0.0;SPECULAR=.43;
 vec3 dx=dFdx(VERTEX),dy=dFdy(VERTEX);
 vec3 r1=cross(dy,NORMAL),r2=cross(NORMAL,dx);
 float det=dot(dx,r1);
 vec3 gradient=sign(det)*(dFdx(detail)*r1+dFdy(detail)*r2);
 NORMAL=normalize(abs(det)*NORMAL-.0004*gradient);
}

shader_type spatial;
render_mode unshaded;
#include "res://shaders/miko8_cel_scene_common.gdshaderinc"
uniform sampler2D concrete:source_color,repeat_enable,filter_linear_mipmap_anisotropic;
uniform sampler2D panels:source_color,repeat_enable,filter_linear_mipmap_anisotropic;
uniform vec3 origin=vec3(72.,0.,-.35);
varying vec3 p;
void vertex(){p=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz-origin;cel_world_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);}
void fragment(){
 vec3 n=normalize(cel_world_normal);vec3 w=pow(abs(n),vec3(8.));w/=max(dot(w,vec3(1.)),.001);
 vec3 side=texture(panels,vec2(p.z,-p.y)/2.4).rgb;
 vec3 front=texture(panels,vec2(p.x,-p.y)/2.4).rgb;
 vec3 top=texture(concrete,p.xz/2.4).rgb*.78;
 vec3 base=side*w.x+front*w.z+top*w.y;
 float stripe=smoothstep(4.6,4.62,p.y)*(1.-smoothstep(4.84,4.86,p.y))*(1.-w.y);
 base=mix(base,vec3(.62,.41,.12),stripe*.85);
 if(n.y<-.5)base=texture(concrete,p.xz/2.4).rgb*.6;
 base*=mix(.65,1.,smoothstep(0.,.45,p.y));
 ALBEDO=base*cel_light(n);
}

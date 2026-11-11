shader_type spatial;
render_mode unshaded;
#include "res://shaders/miko8_cel_scene_common.gdshaderinc"
uniform vec4 paint:source_color=vec4(.3,.35,.37,1.);
uniform sampler2D wear:source_color,filter_linear_mipmap_anisotropic,repeat_enable;
varying vec3 local_point;
varying vec3 local_normal;
void vertex(){cel_world_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);local_point=VERTEX;local_normal=NORMAL;}
void fragment(){
 // Restrained broad paint variation, without photographic noise or specular sparkle.
 float panel=sin(local_point.y*17.0+local_point.z*3.1)*sin(local_point.x*9.0+local_point.z*5.0);
 vec3 n=abs(normalize(local_normal));n/=max(n.x+n.y+n.z,.001);
 vec3 grain=texture(wear,vec2(.51)+fract(local_point.zy*.34)*.48).rgb*n.x+texture(wear,vec2(.51)+fract(local_point.xz*.34)*.48).rgb*n.y+texture(wear,vec2(.51)+fract(local_point.xy*.34)*.48).rgb*n.z;
 float value=dot(grain,vec3(.333));
 vec3 c=paint.rgb*(.72+.68*value+.03*step(.4,panel));
 // Small scattered chips in the same muted warm metal as the surrounding fittings.
 float chip=smoothstep(.57,.72,value)*.30;
 c=mix(c,vec3(.44,.37,.25),chip);
 ALBEDO=c*cel_light(cel_world_normal);
}

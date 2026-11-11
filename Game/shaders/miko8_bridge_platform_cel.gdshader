shader_type spatial;
render_mode unshaded;
#include "res://shaders/miko8_cel_scene_common.gdshaderinc"
uniform sampler2D base_texture:source_color,hint_default_white,filter_linear_mipmap_anisotropic;
uniform vec4 base_color:source_color=vec4(1.0);
void vertex(){cel_world_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);}
void fragment(){
 vec3 source=texture(base_texture,UV).rgb*base_color.rgb;
 float light=dot(normalize(cel_world_normal),normalize(vec3(.25,.70,.68)));
 vec3 tone=mix(vec3(.26,.30,.37),vec3(.61,.64,.68),smoothstep(.12,.16,light));
 tone=mix(tone,vec3(1.03,1.01,.95),smoothstep(.56,.60,light));
 ALBEDO=source*tone;
}

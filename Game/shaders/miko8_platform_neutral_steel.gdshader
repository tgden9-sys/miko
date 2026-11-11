shader_type spatial;
render_mode unshaded;
#include "res://shaders/miko8_cel_scene_common.gdshaderinc"
uniform sampler2D base_texture:source_color,hint_default_white,filter_linear_mipmap_anisotropic;
uniform vec4 base_color:source_color=vec4(1.);
void vertex(){cel_world_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);}
void fragment(){
 vec3 source=textureLod(base_texture,UV,1.2).rgb*base_color.rgb;
 float value=dot(source,vec3(.2126,.7152,.0722));
 vec3 steel=vec3(.84,.94,1.03)*value;
 ALBEDO=mix(source,steel,.78)*cel_light(cel_world_normal);
}

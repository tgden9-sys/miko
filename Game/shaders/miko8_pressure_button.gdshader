shader_type spatial;
render_mode unshaded;
#include "res://shaders/miko8_cel_scene_common.gdshaderinc"
uniform sampler2D base_texture:source_color,hint_default_white,filter_linear_mipmap_anisotropic;
uniform vec4 base_color:source_color=vec4(1.);
uniform float strength=0.;
void vertex(){cel_world_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);}
void fragment(){
 vec3 base=textureLod(base_texture,UV,1.).rgb*base_color.rgb*cel_light(cel_world_normal);
 float value=dot(base,vec3(.2126,.7152,.0722));
 vec3 charged=vec3(.35,.045,.72)*(.35+value*1.8);
 ALBEDO=mix(base,charged,strength*(.66+.06*sin(TIME*4.2)));
}

shader_type spatial;
render_mode unshaded;
#include "res://shaders/miko8_cel_scene_common.gdshaderinc"
uniform sampler2D art:source_color,filter_linear_mipmap_anisotropic,repeat_disable;
uniform vec4 atlas_rect=vec4(0.,0.,.5,.5);
uniform float gain=1.;
void vertex(){cel_world_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);}
void fragment(){
 vec2 uv=atlas_rect.xy+mix(vec2(.006),vec2(.994),UV)*atlas_rect.zw;
 ALBEDO=texture(art,uv).rgb*cel_light(cel_world_normal)*gain;
}

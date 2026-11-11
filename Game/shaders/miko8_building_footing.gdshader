shader_type spatial;
render_mode unshaded,cull_disabled;
#include "res://shaders/miko8_cel_scene_common.gdshaderinc"
varying float floor_height;
void vertex(){cel_world_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);floor_height=(MODEL_MATRIX*vec4(VERTEX,1.)).y;}
void fragment(){
 vec3 base=mix(vec3(.075,.085,.078),vec3(.24,.255,.235),smoothstep(-.01,.15,floor_height));
 ALBEDO=base*cel_light(cel_world_normal);
}

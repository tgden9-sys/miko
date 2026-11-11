shader_type spatial;
render_mode unshaded;
#include "res://shaders/miko8_cel_scene_common.gdshaderinc"
uniform sampler2D base_texture:source_color,hint_default_white,filter_linear_mipmap_anisotropic;
uniform vec4 base_color:source_color=vec4(1.0);
uniform bool use_vertex_color=false;
uniform float dissolve : hint_range(0.0, 1.0) = 0.0;
void vertex(){cel_world_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);}
void fragment(){
 if (dissolve > 0.0) {
  // Fade coverage while keeping the opaque depth test for overlapping armour.
  float threshold = fract(52.9829189 * fract(dot(FRAGCOORD.xy, vec2(0.06711056, 0.00583715))));
  if (dissolve >= threshold) { discard; }
 }
 ALBEDO=cel_paint(textureLod(base_texture,UV,1.5).rgb*base_color.rgb*(use_vertex_color ? COLOR.rgb : vec3(1.0)))*cel_light(cel_world_normal);
}

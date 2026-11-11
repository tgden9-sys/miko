shader_type spatial;
render_mode unshaded;
#include "res://shaders/miko8_cel_scene_common.gdshaderinc"
uniform sampler2D base_texture:source_color,hint_default_white,filter_linear_mipmap_anisotropic;
uniform vec4 base_color:source_color=vec4(1.);
void vertex(){cel_world_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);}
void fragment(){
 vec3 c=texture(base_texture,UV).rgb*base_color.rgb;
 float ochre=smoothstep(.12,.35,c.r-c.b)*smoothstep(.08,.30,c.g-c.b);
 float value=max(c.r,max(c.g,c.b));
 c=mix(c,vec3(.60,.40,.14)*(.6+.4*value),ochre*.85);
 ALBEDO=c*cel_light(cel_world_normal);
}

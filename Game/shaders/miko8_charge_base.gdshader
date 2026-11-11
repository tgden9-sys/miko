shader_type spatial;
render_mode unshaded;
#include "res://shaders/miko8_cel_scene_common.gdshaderinc"
uniform sampler2D base_texture:source_color,hint_default_white,filter_linear_mipmap_anisotropic;
uniform vec4 base_color:source_color=vec4(1.0);
uniform int polarity=0;
void vertex(){cel_world_normal=normalize((MODEL_NORMAL_MATRIX*NORMAL));}
void fragment(){
 vec3 c=texture(base_texture,UV).rgb*base_color.rgb;
 float v=dot(c,vec3(.2126,.7152,.0722));
 float panel=smoothstep(.25,.65,v)*(1.0-smoothstep(.10,.23,max(c.r,max(c.g,c.b))-min(c.r,min(c.g,c.b))));
 vec3 tint=polarity==1?vec3(.8,.12,.09):vec3(.08,.38,.9);
 if(polarity!=0)c=mix(c,tint*(.4+v*.65),panel*.88);
 ALBEDO=c*cel_light(cel_world_normal);
}

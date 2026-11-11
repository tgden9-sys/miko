shader_type spatial;
uniform vec4 base_color : source_color = vec4(0.3,0.35,0.36,1.0);
uniform float metal = 0.15;
uniform sampler2D wear_texture : source_color, repeat_enable, filter_linear_mipmap;
varying vec3 local_pos;
varying vec3 local_normal;
void vertex(){local_pos=VERTEX;local_normal=NORMAL;}
void fragment(){
 float stain=sin(local_pos.x*2.7+sin(local_pos.z*3.1))*sin(local_pos.y*1.9+local_pos.z*2.3);
 float brushing=sin(local_pos.x*52.0+local_pos.z*13.0)*0.008;
 vec2 coord=abs(local_normal.y)>0.5?local_pos.xz:(abs(local_normal.z)>0.5?local_pos.xy:local_pos.zy);
 vec3 wear=texture(wear_texture,coord*0.65).rgb;
 float detail=dot(wear,vec3(0.3,0.59,0.11));
 ALBEDO=base_color.rgb*(0.88+stain*0.045+brushing+detail*0.75);
 METALLIC=metal;ROUGHNESS=0.88;
}

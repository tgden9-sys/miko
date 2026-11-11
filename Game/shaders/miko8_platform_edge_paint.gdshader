shader_type spatial;
uniform sampler2D wear:source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform vec4 paint_color:source_color=vec4(.88,.69,.29,1.0);
varying vec3 world_point;
void vertex(){world_point=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 vec3 grain=texture(wear,world_point.xy*2.5).rgb;
 float chips=smoothstep(.08,.19,dot(grain,vec3(.333)));
 ALBEDO=mix(vec3(.25,.27,.26),paint_color.rgb,.72+.28*chips);
 ROUGHNESS=.94;METALLIC=0.0;SPECULAR=.18;
}

shader_type spatial;
uniform vec4 base_color:source_color=vec4(0.3,0.38,0.46,1.0);
uniform float metal=0.0;
uniform bool vertex_ao=false;
void fragment(){
 ALBEDO=base_color.rgb;
 ROUGHNESS=0.76;METALLIC=metal*0.3;SPECULAR=0.18;
 if(vertex_ao){AO=mix(0.65,1.0,COLOR.r);}
}
void light(){
 float n=max(dot(NORMAL,LIGHT),0.0);
 float bands=0.09+0.43*smoothstep(0.16,0.24,n)+0.48*smoothstep(0.62,0.72,n);
 DIFFUSE_LIGHT+=bands*ATTENUATION*LIGHT_COLOR/3.14159265;
}

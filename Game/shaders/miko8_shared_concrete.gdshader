shader_type spatial;
uniform sampler2D grain:source_color,filter_linear_mipmap_anisotropic,repeat_enable;
varying vec3 world_point;
varying vec3 world_normal;
void vertex(){
 world_point=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 world_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);
}
vec3 concrete_sample(vec2 point){
 return texture(grain,vec2(point.x/6.0,.02+fract(point.y/.32)*.16)).rgb;
}
void fragment(){
 vec3 weights=pow(abs(world_normal),vec3(4.0));weights/=max(dot(weights,vec3(1.0)),.001);
 vec3 detail=concrete_sample(world_point.zy)*weights.x;
 detail+=concrete_sample(world_point.xz)*weights.y;
 detail+=concrete_sample(world_point.xy)*weights.z;
 ALBEDO=detail*vec3(2.20,1.75,1.15);
 ROUGHNESS=.94;METALLIC=0.0;SPECULAR=.20;
}

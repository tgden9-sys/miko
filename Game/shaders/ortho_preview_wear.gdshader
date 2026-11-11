shader_type spatial;
uniform vec4 base_color : source_color=vec4(0.3,0.3,0.3,1.0);
uniform sampler2D wear : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float metal=0.0;
uniform float texture_scale=0.55;
uniform float bump_strength=0.02;
uniform bool use_vertex_detail=false;
varying vec3 local_point;
varying vec3 local_normal;
void vertex(){local_point=VERTEX;local_normal=NORMAL;}
void fragment(){
 vec3 weights=pow(abs(local_normal),vec3(4.0));weights/=max(dot(weights,vec3(1.0)),0.001);
 vec3 grain=texture(wear,local_point.zy*texture_scale).rgb*weights.x+texture(wear,local_point.xz*texture_scale).rgb*weights.y+texture(wear,local_point.xy*texture_scale).rgb*weights.z;
 float detail=dot(grain,vec3(0.333));
 ALBEDO=mix(base_color.rgb,grain,0.50);
 // Author wear around the existing construction rather than adding a uniform
 // noise coat. Local coordinates repeat exactly with each six-metre module.
 float front=smoothstep(0.6,0.95,local_normal.z);
 if(metal<0.3){
  float seam=min(fract(local_point.x/0.75),1.0-fract(local_point.x/0.75));
  float streak=pow(0.5+0.5*sin(local_point.x*31.3+sin(local_point.x*7.2)),9.0);
  float length_fade=exp(-max(0.0,-local_point.y-0.25)*1.25);
  float runoff=streak*length_fade*front*(1.0-smoothstep(-0.28,-0.12,local_point.y));
  ALBEDO=mix(ALBEDO,ALBEDO*vec3(0.38,0.44,0.43),runoff*0.62);
  float moss=(1.0-smoothstep(0.012,0.095,seam))*front;
  moss*=smoothstep(-2.25,-0.15,local_point.y)*(0.3+0.7*clamp(detail*3.0,0.0,1.0));
  ALBEDO=mix(ALBEDO,vec3(0.045,0.065,0.024),moss*0.5);
  float lip=exp(-abs(local_point.y+0.11)*26.0)*front;
  ALBEDO=mix(ALBEDO,vec3(0.33,0.30,0.23),lip*0.25);
  float under_lip=exp(-abs(local_point.y+0.31)*18.0)*front;
  float pipe_occlusion=exp(-pow((local_point.y+0.70)/0.14,2.0))*front;
  AO=clamp(1.0-under_lip*0.46-pipe_occlusion*0.25,0.35,1.0);
  ALBEDO*=1.0-under_lip*0.16;
 }else{
  float rust=clamp((grain.r-grain.b)*6.0,0.0,0.65);
  ALBEDO=mix(ALBEDO,vec3(0.16,0.065,0.025),rust*0.45);
 }
 if(use_vertex_detail){
  AO=clamp(COLOR.r,0.22,1.0);
  ALBEDO*=mix(0.58,1.0,COLOR.r);
  ALBEDO=mix(ALBEDO,vec3(0.23,0.20,0.15),COLOR.g*0.28);
 }
 ROUGHNESS=mix(0.94,0.75,metal)+clamp(detail-0.2,-0.05,0.05);METALLIC=metal*0.65;
 vec3 dx=dFdx(VERTEX);vec3 dy=dFdy(VERTEX);
 vec3 r1=cross(dy,NORMAL);vec3 r2=cross(NORMAL,dx);
 float determinant=dot(dx,r1);
 vec3 gradient=sign(determinant)*(dFdx(detail)*r1+dFdy(detail)*r2);
 NORMAL=normalize(abs(determinant)*NORMAL-bump_strength*gradient);
}

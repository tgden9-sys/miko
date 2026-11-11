shader_type spatial;
uniform vec4 paint_color:source_color=vec4(0.3,0.32,0.34,1.0);
uniform sampler2D grain:source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform float texture_strength=0.55;
uniform float texture_scale=0.9;
uniform float metal=0.0;
uniform bool vertex_ao=false;
uniform bool trim_rear_rail=false;
varying vec3 point;
varying vec3 face;
void vertex(){point=VERTEX;face=NORMAL;}
void fragment(){
 if(trim_rear_rail && point.y>.12 && point.z< -1.05){discard;}
 vec3 w=pow(abs(face),vec3(6.0));w/=max(dot(w,vec3(1.0)),0.001);
 vec3 tex=texture(grain,point.zy*texture_scale).rgb*w.x+texture(grain,point.xz*texture_scale).rgb*w.y+texture(grain,point.xy*texture_scale).rgb*w.z;
 float relief=dot(tex,vec3(0.3333));
 ALBEDO=mix(paint_color.rgb,tex,texture_strength);
 float runoff=pow(0.5+0.5*sin(point.x*27.0+sin(point.x*8.0)),12.0)*exp(-abs(point.y+.38)*.8)*max(face.z,0.0);
 ALBEDO*=1.0-runoff*.16;
 ROUGHNESS=clamp(mix(.90,.57,metal)+(relief-.25)*.16,.38,.96);
 METALLIC=metal;SPECULAR=.45;
 if(vertex_ao){AO=clamp(COLOR.r,.35,1.0);ALBEDO*=mix(.8,1.0,COLOR.r);}
 vec3 dx=dFdx(VERTEX),dy=dFdy(VERTEX);
 vec3 r1=cross(dy,NORMAL),r2=cross(NORMAL,dx);
 float det=dot(dx,r1);
 vec3 grad=sign(det)*(dFdx(relief)*r1+dFdy(relief)*r2);
 NORMAL=normalize(abs(det)*NORMAL-.0018*grad);
}

shader_type spatial;
render_mode unshaded, shadows_disabled;
uniform sampler2D art : source_color, filter_linear_mipmap_anisotropic;
// Painted endpoints are measured once, then mapped to the shared pipe sockets.
// Header and lower masonry courses stay fixed. No perspective is introduced.
uniform vec3 upper_left=vec3(0.30,0.36,0.42);
uniform vec3 upper_right=vec3(0.30,0.36,0.42);
uniform vec3 lower_left=vec3(0.60,0.66,0.72);
uniform vec3 lower_right=vec3(0.60,0.66,0.72);
float remap(float v,vec3 u,vec3 l){
 if(v<0.15)return v;
 if(v<0.30)return mix(0.15,u.x,(v-0.15)/0.15);
 if(v<0.36)return mix(u.x,u.y,(v-0.30)/0.06);
 if(v<0.42)return mix(u.y,u.z,(v-0.36)/0.06);
 if(v<0.60)return mix(u.z,l.x,(v-0.42)/0.18);
 if(v<0.66)return mix(l.x,l.y,(v-0.60)/0.06);
 if(v<0.72)return mix(l.y,l.z,(v-0.66)/0.06);
 if(v<0.80)return mix(l.z,0.80,(v-0.72)/0.08);
 return v;
}
void fragment(){
 float x=smoothstep(0.04,0.96,UV.x);
 float v=remap(UV.y,mix(upper_left,upper_right,x),mix(lower_left,lower_right,x));
 ALBEDO=texture(art,vec2(UV.x,v)).rgb;
}

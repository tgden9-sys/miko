shader_type spatial;
render_mode unshaded;
#include "res://shaders/miko8_transfer_common.gdshaderinc"
uniform sampler2D base_texture : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D metal_rough_texture : filter_linear_mipmap_anisotropic;
uniform float metallic_factor=1.0;
uniform float roughness_factor=1.0;
uniform int polarity=0;
uniform vec4 scene_tint : source_color=vec4(1.0);
uniform float scene_roughness_bias=0.0;
// A single art-directed key prevents overlapping yard lights from adding
// extra lighting bands. All values below multiply the original suit colours.
uniform vec3 key_direction=vec3(-0.50,0.65,0.58);
uniform float shadow_threshold=0.16;
uniform float light_threshold=0.62;
uniform float transition_width=0.025;
uniform vec3 shadow_tone=vec3(0.22,0.25,0.31);
uniform vec3 middle_tone=vec3(0.55,0.58,0.63);
uniform vec3 light_tone=vec3(1.07,1.04,0.98);
uniform vec3 rim_light_pos=vec3(0.0);
uniform vec3 rim_light_color=vec3(1.0,0.74,0.49);
uniform float rim_intensity=0.0;
varying vec3 world_normal;
varying vec3 world_pos;
void vertex(){
	world_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);
	world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
}
void fragment(){
 vec3 transfer_point=(INV_VIEW_MATRIX*vec4(VERTEX,1.)).xyz;
 if(transfer_progress>0. && transfer_distance(transfer_point)<0.)discard;
 vec3 base=texture(base_texture,UV).rgb;
 float dominance=base.g-max(base.r,base.b);
 float mask=smoothstep(0.035,0.15,dominance)*smoothstep(0.06,0.22,base.g);
 vec3 pole=polarity==1?vec3(1.0,0.025,0.045):vec3(0.02,0.32,1.0);
 vec3 recolored=pole*max(base.r,max(base.g,base.b));
 vec3 accent=polarity==0?base:recolored;
 float value=max(accent.r,max(accent.g,accent.b));
 vec3 softened=mix(vec3(value*0.58),accent,0.32);
 base=mix(base,softened,mask)*scene_tint.rgb;
 float incidence=dot(normalize(world_normal),normalize(key_direction));
 float mid=smoothstep(shadow_threshold-transition_width,shadow_threshold+transition_width,incidence);
 float lit=smoothstep(light_threshold-transition_width,light_threshold+transition_width,incidence);
 vec3 tone=mix(shadow_tone,middle_tone,mid);
 tone=mix(tone,light_tone,lit);
 vec3 col=base*tone;
 if (rim_intensity > 0.001) {
     vec3 to_light = rim_light_pos - world_pos;
     vec3 light_dir = normalize(to_light);
     vec3 view_dir = normalize(CAMERA_POSITION_WORLD - world_pos);
     float fresnel = pow(1.0 - max(0.0, dot(normalize(world_normal), view_dir)), 2.5);
     float wrap_light = max(0.0, dot(normalize(world_normal), light_dir) * 0.5 + 0.5);
     vec3 rim = rim_light_color * fresnel * wrap_light * rim_intensity;
     col += base * rim;
 }
 ALBEDO=transfer_paint(col,transfer_point,NORMAL,VIEW);
}

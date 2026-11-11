shader_type spatial;
render_mode cull_disabled;
uniform sampler2D base_texture : source_color, hint_default_white, filter_linear_mipmap_anisotropic;
uniform sampler2D metal_rough_texture : hint_default_white, filter_linear_mipmap;
uniform sampler2D normal_texture : hint_normal, filter_linear_mipmap;
uniform vec4 base_color : source_color=vec4(1.0);
uniform float metallic_factor=1.0;
uniform float roughness_factor=1.0;
uniform float normal_scale=1.0;
uniform int polarity=0;
uniform float targeting=0.0;
uniform vec4 target_color : source_color=vec4(1.0);
uniform float grounding_amount=0.0;
uniform float architecture_ao=1.0;
uniform float architecture_gain=1.0;
uniform float architecture_roughness_min=0.35;
uniform float architecture_specular=0.5;
uniform float architecture_metallic_scale=1.0;
varying float local_height;
void vertex(){local_height=VERTEX.y;}
void fragment(){
 vec3 base=texture(base_texture,UV).rgb*base_color.rgb;
 // Isolate the authored green inserts; retain the casing and baked wear.
 float green=base.g-max(base.r,base.b);
 float mask=smoothstep(0.025,0.12,green)*smoothstep(0.10,0.27,base.g);
 float value=max(base.r,max(base.g,base.b));
 vec3 tint=polarity==1?vec3(1.0,0.045,0.065):vec3(0.035,0.32,1.0);
 vec3 paint=tint*value;
 ALBEDO=polarity==0?base:mix(base,paint,mask);
 ALBEDO*=1.-grounding_amount*(1.-smoothstep(.025,.42,local_height));
 ALBEDO*=architecture_gain;
 AO=architecture_ao;
 AO_LIGHT_AFFECT=0.0;
 vec3 glow=polarity==0?base:paint;
 EMISSION=mix(glow,target_color.rgb,targeting*0.5)*mask*(0.18+targeting*0.12);
 vec3 mr=texture(metal_rough_texture,UV).rgb;
 METALLIC=mr.b*metallic_factor*architecture_metallic_scale;
 ROUGHNESS=clamp(mr.g*roughness_factor,architecture_roughness_min,1.0);
 SPECULAR=architecture_specular;
 NORMAL_MAP=texture(normal_texture,UV).rgb;
 NORMAL_MAP_DEPTH=normal_scale;
}

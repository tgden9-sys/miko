shader_type spatial;
// Project in metres so the quiet surfaces repeat at a consistent material scale.
uniform sampler2D facade : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D concrete : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D wall_panels : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool use_wall_panels=false;
uniform vec3 building_origin=vec3(20.6,0.0,-0.39);
uniform float building_height=2.83364;
uniform float facade_height=2.83364;
uniform float facade_end_v=1.0;
uniform float facade_start_x=-0.95;
uniform float facade_width=4.15;
uniform float tile_metres=2.4;
uniform float architecture_ao=1.0;
uniform float architecture_gain=1.0;
varying vec3 skin_position;
varying vec3 skin_normal;
void vertex(){
 skin_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz-building_origin;
 skin_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);
}
void fragment(){
 vec3 p=skin_position;
 vec3 n=normalize(skin_normal);
 vec3 weights=pow(abs(n),vec3(8.0));
 weights/=max(weights.x+weights.y+weights.z,0.0001);
 vec3 side=texture(concrete,vec2(p.z,-p.y)/tile_metres).rgb;
 vec3 wall=texture(concrete,vec2(p.x,-p.y)/tile_metres).rgb;
 if(use_wall_panels){
  side=texture(wall_panels,vec2(p.z,-p.y)/tile_metres).rgb;
  wall=texture(wall_panels,vec2(p.x,-p.y)/tile_metres).rgb;
 }
 vec3 roof=texture(concrete,p.xz/tile_metres).rgb*0.73;
 vec3 base=side*weights.x+roof*weights.y+wall*weights.z;
 // Only the broad outward-facing wall receives the complete service assembly.
 // Its pipe ends turn into wall flanges inside the mapped rectangle.
 float front=smoothstep(0.65,0.94,n.z)*smoothstep(0.45,0.85,p.z);
 front*=1.0-smoothstep(facade_height-.01,facade_height,p.y);
 vec2 uv=vec2((p.x-facade_start_x)/facade_width,(1.0-p.y/facade_height)*facade_end_v);
 // Do not extend a texture's outermost pixel down the corner columns.
 front*=smoothstep(0.0,0.012,uv.x)*(1.0-smoothstep(0.988,1.0,uv.x));
 vec3 face=texture(facade,clamp(uv,vec2(0.0),vec2(1.0))).rgb;
 base=mix(base,face,front);
 base*=mix(0.78,1.0,smoothstep(0.01,0.48,p.y));
 ALBEDO=base*architecture_gain;
 AO=architecture_ao;
 AO_LIGHT_AFFECT=0.0;
 ROUGHNESS=0.88;
 SPECULAR=0.2;
 METALLIC=0.0;
}

shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;
void fragment(){
 vec3 high=vec3(0.035,0.055,0.13);
 vec3 low=vec3(0.20,0.15,0.26);
 ALBEDO=mix(high,low,smoothstep(0.15,0.95,UV.y));
}

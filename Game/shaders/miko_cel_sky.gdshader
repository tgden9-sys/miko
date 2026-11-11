shader_type spatial;
render_mode unshaded,cull_disabled,fog_disabled;
void fragment(){ALBEDO=mix(vec3(0.015,0.025,0.05),vec3(0.065,0.095,0.15),smoothstep(0.15,0.95,UV.y));}

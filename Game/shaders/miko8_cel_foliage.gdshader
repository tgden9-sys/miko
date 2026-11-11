shader_type spatial;
render_mode unshaded,cull_disabled;
uniform sampler2D leaf_texture:source_color,filter_linear_mipmap;
uniform vec2 uv_scale=vec2(1.0);
uniform vec2 uv_offset=vec2(0.0);
void fragment(){
 vec4 leaf=texture(leaf_texture,UV*uv_scale+uv_offset);
 if(leaf.a<.38)discard;
 float value=dot(leaf.rgb,vec3(.21,.72,.07));
 vec3 colour=mix(vec3(.055,.075,.035),vec3(.16,.20,.085),smoothstep(.11,.15,value));
 ALBEDO=mix(colour,vec3(.29,.33,.15),smoothstep(.30,.34,value));
}

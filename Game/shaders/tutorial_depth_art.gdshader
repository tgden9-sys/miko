shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform sampler2D art : source_color, filter_linear_mipmap;
uniform float blur_lod=0.0;
uniform float mist=0.0;
uniform vec4 mist_color : source_color=vec4(0.49,0.55,0.67,1.0);
uniform vec3 scene_tint=vec3(1.0);
void fragment(){
 vec4 image=textureLod(art,UV,blur_lod);
 ALBEDO=mix(image.rgb*scene_tint,mist_color.rgb,mist);
 ALPHA=image.a;
}

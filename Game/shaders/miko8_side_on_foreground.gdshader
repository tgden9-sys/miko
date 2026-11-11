shader_type spatial;
render_mode unshaded,cull_disabled,depth_draw_never,shadows_disabled;
uniform sampler2D art:source_color,filter_linear_mipmap;
uniform vec4 region=vec4(0,0,1,1);
uniform float blur_lod=3.0;
void fragment(){
 vec4 pixel=textureLod(art,region.xy+UV*region.zw,blur_lod);
 ALBEDO=pixel.rgb*vec3(.65,.69,.76);
 ALPHA=pixel.a*.98;
}

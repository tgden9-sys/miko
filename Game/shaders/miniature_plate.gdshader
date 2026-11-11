shader_type spatial;
render_mode unshaded,cull_disabled,depth_draw_never,shadows_disabled,fog_disabled;
uniform sampler2D art:source_color,filter_linear;
void fragment(){vec4 pixel=texture(art,UV);ALBEDO=pixel.rgb;ALPHA=pixel.a;}

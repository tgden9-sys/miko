shader_type spatial;
render_mode unshaded,blend_add,cull_disabled,depth_draw_never,shadows_disabled;
void fragment(){ALBEDO=COLOR.rgb;EMISSION=COLOR.rgb*.45;ALPHA=COLOR.a;}

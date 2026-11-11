shader_type spatial;
render_mode unshaded, shadows_disabled;
uniform sampler2D art : source_color, filter_linear_mipmap_anisotropic;

void fragment(){
 // The new photograph is authored at the final 3:1 ratio with level sockets.
 // Keep its geometry, pipe height, lighting and small material detail intact.
 ALBEDO=texture(art,UV).rgb;
}

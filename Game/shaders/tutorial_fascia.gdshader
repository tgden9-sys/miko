shader_type spatial;
render_mode unshaded, cull_disabled;
uniform sampler2D art : source_color, repeat_enable, filter_linear_mipmap;
uniform float repeats=1.0;
uniform vec2 vertical_range=vec2(0.0,1.0);
void fragment(){ALBEDO=texture(art,vec2(UV.x*repeats,mix(vertical_range.x,vertical_range.y,UV.y))).rgb;ROUGHNESS=0.95;}

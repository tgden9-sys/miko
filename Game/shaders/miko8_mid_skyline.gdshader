shader_type spatial;
render_mode unshaded,cull_disabled,depth_draw_never;
uniform sampler2D art:source_color,filter_linear_mipmap,repeat_disable;
uniform float brightness=.5;
uniform float vertical_fill=1.42;
uniform float horizontal_fill=1.0;
void fragment(){
 // Repeat only horizontally. Wrapping vertically bleeds the opaque bottom
 // into the transparent skyline edge and draws a line across the sky.
 vec4 painted=texture(art,vec2(fract(UV.x*1.8*horizontal_fill),clamp(UV.y*vertical_fill,.002,.998)));
 // Bring the cool source artwork into the yard's muted charcoal palette.
 float grey=dot(painted.rgb,vec3(.2126,.7152,.0722));
 vec3 toned=mix(painted.rgb,vec3(grey)*vec3(1.,.99,.96),.42);
 ALBEDO=toned*vec3(1.02,1.,.94)*.78*brightness;
 ALPHA=painted.a*smoothstep(0.,.015,UV.y);
}

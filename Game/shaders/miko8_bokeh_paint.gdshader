shader_type spatial;
render_mode unshaded,cull_disabled,shadows_disabled;
uniform sampler2D art:source_color,filter_linear_mipmap;
uniform float brightness=.50;
uniform float horizontal_fill=1.0;
uniform float paint_strength:hint_range(0.0,1.0)=.32;
void fragment(){
 vec2 uv=UV;
 uv.x=1.0-abs(mod(uv.x*horizontal_fill,2.0)-1.0);
 vec3 original=texture(art,uv).rgb;
 float luminance=max(dot(original,vec3(.2126,.7152,.0722)),.00001);
 // Soft tonal shoulders, with the same gain on every colour channel.
 // This keeps the blue/amber palette and avoids RGB posterisation speckles.
 float value=sqrt(luminance)*8.0;
 float painted=(floor(value)+smoothstep(.18,.82,fract(value)))/8.0;
 float gain=painted*painted/luminance;
 // Keep the warm defocused lamps and their luminous falloff especially soft.
 float lamp=smoothstep(.13,.42,luminance)*smoothstep(.02,.12,original.r-original.b);
 ALBEDO=mix(original,original*gain,paint_strength*(1.0-lamp))*brightness;
}

shader_type spatial;
render_mode unshaded, shadows_disabled;
uniform sampler2D art : source_color, filter_linear_mipmap_anisotropic;
uniform int polarity=0;
uniform float targeting=0.0;
void fragment(){
 vec3 base=texture(art,UV).rgb;
 float mask=smoothstep(.04,.16,base.g-max(base.r,base.b));
 vec3 tint=polarity==1?vec3(1.,.055,.075):vec3(.04,.40,1.);
 vec3 colored=tint*max(base.g,.35);
 ALBEDO=(polarity==0?base:mix(base,colored,mask))*.88;
 EMISSION=(polarity==0?base:colored)*mask*(.12+targeting*.20);
}

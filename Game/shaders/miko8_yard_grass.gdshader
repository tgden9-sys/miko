shader_type spatial;
render_mode cull_disabled;
varying vec3 world_root;
void vertex(){
 world_root=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;
 float gust=sin(TIME*1.15+world_root.x*1.4+world_root.z*2.7);
 VERTEX.x+=gust*.012*UV.y*UV.y;
 VERTEX.z+=sin(TIME*.73+world_root.x)*.008*UV.y*UV.y;
}
void fragment(){
 ALBEDO=COLOR.rgb*(.65+.35*UV.y);
 // A little transmitted/ambient light keeps fine blades readable at dusk.
 EMISSION=COLOR.rgb*.18*(.6+.4*UV.y);
 ROUGHNESS=.95;SPECULAR=.12;
 if(!FRONT_FACING){NORMAL=-NORMAL;}
}

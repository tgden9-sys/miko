shader_type spatial;
render_mode unshaded;
varying vec3 point;
void vertex(){point=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;}
void fragment(){
 float slat=step(.69,fract(point.x/.095));
 ALBEDO=mix(vec3(.014,.019,.021),vec3(.16,.18,.17),slat);
}

shader_type spatial;
render_mode unshaded;
uniform float strength=0.;
void fragment(){
 vec3 ready=vec3(.08,.80,.23);
 vec3 pressed=vec3(.61,.08,1.);
 float pulse=1.+.10*strength*sin(TIME*4.2);
 ALBEDO=mix(ready,pressed,strength)*pulse;
}

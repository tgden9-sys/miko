shader_type sky;
void sky(){
 float horizon=pow(1.0-abs(EYEDIR.y),3.0);
 COLOR=mix(vec3(.003,.006,.014),vec3(.025,.039,.060),horizon);
}

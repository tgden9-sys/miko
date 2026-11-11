varying vec3 cel_world_normal;
vec3 cel_paint(vec3 c){
 // The artwork supplies the painted shapes. Quantising RGB independently
 // creates coloured speckles in neutral concrete; only lighting is banded.
 return c;
}
vec3 cel_light(vec3 n){
 float light=dot(normalize(n),normalize(vec3(.28,.62,.73)));
 vec3 colour=mix(vec3(.26,.30,.37),vec3(.61,.64,.68),smoothstep(.12,.16,light));
 return mix(colour,vec3(1.06,1.01,.92),smoothstep(.59,.63,light));
}

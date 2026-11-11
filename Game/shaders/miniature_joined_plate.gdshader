shader_type spatial;
render_mode unshaded,cull_disabled,depth_draw_never,shadows_disabled,fog_disabled;
uniform sampler2D art:source_color,filter_linear,repeat_disable;
// Register the measured art bands to one common pavement/foot/coping datum.
uniform vec3 source_rows=vec3(.505,.54,.605);
uniform vec3 output_rows=vec3(.505,.54,.605);
uniform float back_width_ratio=.953;
uniform float vanishing_x=.395;
uniform bool register_upper=false;
float map_row(float y){
 if(y<output_rows.x){
  if(register_upper){
   if(y<.02){return mix(-.008,.01,y/.02);}
   if(y<.065){return mix(.01,.055,(y-.02)/.045);}
   if(y<.10){return mix(.055,.074,(y-.065)/.035);}
   return mix(.074,source_rows.x,(y-.10)/(output_rows.x-.10));
  }
  return y*source_rows.x/output_rows.x;
 }
 if(y<output_rows.y){return mix(source_rows.x,source_rows.y,(y-output_rows.x)/(output_rows.y-output_rows.x));}
 if(y<output_rows.z){return mix(source_rows.y,source_rows.z,(y-output_rows.y)/(output_rows.z-output_rows.y));}
 return mix(source_rows.z,1.0,(y-output_rows.z)/(1.0-output_rows.z));
}
void fragment(){
 float v=map_row(UV.y);float u=UV.x;
 if(UV.y>=output_rows.x && UV.y<=output_rows.z){
  float t=clamp((v-source_rows.x)/(source_rows.z-source_rows.x),0.0,1.0);
  u=vanishing_x+(u-vanishing_x)*mix(back_width_ratio,1.0,t);
 }
 vec4 pixel=v<0.0?vec4(0.0):texture(art,vec2(u,v));ALBEDO=pixel.rgb;ALPHA=pixel.a;
}

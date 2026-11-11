shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, depth_test_disabled, shadows_disabled;
varying float phase;
varying float kind;
uniform bool debug_view=false;
uniform float master_opacity : hint_range(0.0, 2.0) = 1.0;

void vertex(){phase=INSTANCE_CUSTOM.r*6.2831853;kind=INSTANCE_CUSTOM.g;}
void fragment(){
 vec2 p=UV-vec2(0.5);
 float r=length(p);
 float soft=exp(-r*r*18.0)*(1.0-smoothstep(0.35,0.5,r));
 float core=1.0-smoothstep(0.02,0.18,r);
 float cross=(1.0-smoothstep(0.005,0.025,min(abs(p.x),abs(p.y))))*(1.0-smoothstep(0.04,0.34,r));
 float twinkle=0.70+0.30*sin(TIME*0.9+phase);
 float shape=kind>0.5&&kind<1.5?soft*0.55:kind>2.5?soft*0.65:soft*0.25+core*0.75+cross*0.15;
 ALBEDO=COLOR.rgb;
 ALPHA=COLOR.a*shape*twinkle*master_opacity;
 if(debug_view){ALBEDO=vec3(1.0,0.0,0.0);ALPHA=1.0;}
}

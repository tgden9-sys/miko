shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never, shadows_disabled;
uniform vec4 pole_color : source_color = vec4(0.22,0.57,1.0,1.0);
uniform float field_strength : hint_range(0.0,1.0) = 1.0;

float hash(float v) { return fract(sin(v*127.1+17.7)*43758.5453); }
float noise(float x,float seed) {
	float cell=floor(x);
	return mix(hash(cell+seed),hash(cell+seed+1.0),fract(x))-.5;
}
float filament(vec2 uv,float height,float seed,float phase) {
	float envelope=sin(uv.x*PI);
	float path=height+envelope*(noise(uv.x*10.0+phase,seed)*.09
		+noise(uv.x*27.0-phase*1.3,seed+19.0)*.028);
	float d=abs(uv.y-path);
	float aa=max(fwidth(uv.y)*.7,.0011);
	float core=1.0-smoothstep(.001,aa+.001,d);
	return core*.62+exp(-d*105.0)*.11;
}
void fragment() {
	vec2 uv=UV;
	float edge=min(uv.x,1.0-uv.x);
	float border=smoothstep(0.0,.012,edge)*smoothstep(0.0,.025,min(uv.y,1.0-uv.y));
	// Quiet continuous containment skin, occasional discharges anchored to three emitters.
	float flow=sin(uv.y*76.0+sin(uv.x*12.0+TIME*.6)*.32-TIME*1.7)*.5+.5;
	float skin=.085+pow(flow,8.0)*.022;
	float charge=pow(.5+.5*sin(TIME*1.7+1.2),18.0);
	float second=pow(.5+.5*sin(TIME*1.23+3.8),22.0);
	float third=pow(.5+.5*sin(TIME*1.43+5.1),20.0);
	float arcs=filament(uv,.20,17.0,TIME*1.4)*charge
		+filament(uv,.50,53.0,-TIME*1.1)*second
		+filament(uv,.80,97.0,TIME*1.7)*third;
	float edge_light=exp(-edge*46.0)*.42;
	float release=smoothstep(0.0,.8,field_strength);
	ALBEDO=mix(pole_color.rgb,vec3(.78,.9,1.0),clamp(arcs*.8,0.0,.55));
	ALPHA=(skin+edge_light+arcs*1.35)*border*release;
}

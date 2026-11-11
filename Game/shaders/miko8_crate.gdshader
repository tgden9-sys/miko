shader_type spatial;
uniform sampler2D base_texture : source_color, hint_default_white, filter_linear_mipmap_anisotropic;
uniform vec4 base_color : source_color=vec4(1.0);
uniform sampler2D metal_rough_texture : hint_default_white, filter_linear_mipmap;
uniform float metallic_factor=0.3;
uniform float roughness_factor=0.8;
uniform int polarity=0;
uniform vec2 energy_from=vec2(0.0);
uniform vec2 energy_to=vec2(0.0);
uniform float charge_progress=1.0;
uniform vec3 charge_origin=vec3(0.0,0.0,0.4);
uniform vec3 bounds_center=vec3(0.0);
uniform vec3 bounds_half=vec3(0.4);
varying vec3 local_position;
void vertex(){local_position=VERTEX;}
void fragment(){
 vec3 base=texture(base_texture,UV).rgb*base_color.rgb;
 vec3 normalized_position=(local_position-bounds_center)/bounds_half;
 vec3 p=abs(normalized_position);
 vec2 q=p.x>=p.y&&p.x>=p.z?p.yz:p.y>=p.z?p.xz:p.xy;
 float panel=(1.0-smoothstep(0.68,0.78,max(q.x,q.y)))*(1.0-smoothstep(1.26,1.44,q.x+q.y));
 float distance_from_hit=length((local_position-charge_origin)/bounds_half)/3.5;
 float front=charge_progress*1.45;
 float spread=smoothstep(distance_from_hit-.10,distance_from_hit+.10,front);
 spread=mix(spread,1.0,step(.999,charge_progress));
 vec2 energy=mix(energy_from,energy_to,spread);
 float strength=clamp(energy.x+energy.y,0.0,1.0);
 vec3 tint=(vec3(1.0,.045,.025)*energy.x+vec3(.025,.38,1.0)*energy.y)/max(strength,.001);
 float aa=max(length(fwidth(q))*.5,.004);
 // An inset octagonal conductor follows the panel, inside the protective frame.
 float seam=max(max(q.x,q.y)-.66,(q.x+q.y-1.16)*.7071);
 float groove=1.0-smoothstep(.046-aa,.046+aa,abs(seam));
 float conductor=1.0-smoothstep(.018-aa,.018+aa,abs(seam));
 float corner=1.0-smoothstep(.065-aa,.065+aa,length(q-vec2(.72)));
 float bars=(1.0-smoothstep(.023-aa,.023+aa,abs(q.y-.45)))*
   (1.0-smoothstep(.20,.23,q.x));
 float hardware=max(max(conductor,corner),bars);
 float original_lights=smoothstep(.045,.16,base.g-max(base.r,base.b));
 float halo=exp(-abs(seam)*28.0)*panel;
 ALBEDO=base*mix(1.0,.48,groove*.75);
 ALBEDO=mix(ALBEDO,ALBEDO*(vec3(.80)+tint*.45),panel*strength*.36);
 ALBEDO+=tint*halo*strength*.10;
 ALBEDO=mix(ALBEDO,ALBEDO*(vec3(.25)+tint*.65),original_lights*strength);
 // Light lives in the fittings. The broad metal panels retain the texture and shading.
 float breathe=.90+.10*sin(TIME*2.4);
 float surge=exp(-pow((distance_from_hit-front)/.065,2.0))*
   (1.0-smoothstep(.72,1.0,charge_progress))*step(.01,energy_to.x+energy_to.y);
 float contact=exp(-distance_from_hit*26.0)*(1.0-smoothstep(.0,.22,charge_progress))*
   step(.01,energy_to.x+energy_to.y);
 EMISSION=tint*hardware*strength*breathe*.82;
 float hot_core=1.0-smoothstep(.005-aa*.3,.005+aa*.3,abs(seam));
 EMISSION+=mix(tint,vec3(1.0),.45)*hot_core*strength*.24;
 EMISSION+=tint*(halo*.055+original_lights*.65)*strength*breathe;
 EMISSION+=mix(tint,vec3(1.0,.94,.83),.72)*(surge*(hardware*.85+panel*.13)+contact*.8);
 vec3 mr=texture(metal_rough_texture,UV).rgb;
 METALLIC=mr.b*metallic_factor;
 ROUGHNESS=clamp(mr.g*roughness_factor,0.60,1.0);
}

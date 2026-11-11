shader_type spatial;
render_mode unshaded;

// Imported colour is a paint/ink mask; baked light never shades the kit twice.
uniform sampler2D source_paint:source_color,hint_default_white,filter_linear_mipmap_anisotropic;
uniform int surface_kind=0; // scan, steel, amber, deck, rung, ink, bolt
uniform vec4 steel_light:source_color=vec4(.62,.65,.60,1.);
uniform vec4 steel_mid:source_color=vec4(.30,.325,.31,1.);
uniform vec4 steel_shadow:source_color=vec4(.085,.115,.115,1.);
uniform vec4 amber_light:source_color=vec4(.91,.68,.31,1.);
uniform vec4 amber_mid:source_color=vec4(.67,.42,.15,1.);
uniform vec4 amber_shadow:source_color=vec4(.30,.20,.08,1.);
uniform vec4 ink_colour:source_color=vec4(.055,.075,.073,1.);
varying vec3 world_normal;
void vertex(){world_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);}
void fragment(){
	vec3 n=normalize(world_normal);
	// Stabilise large flat scan faces while retaining manufactured bevels.
	n=normalize(n*pow(abs(n)+vec3(.0001),vec3(2.0)));
	float key=dot(n,normalize(vec3(.34,.84,.53)));
	float mid=smoothstep(.25,.31,key);float lit=smoothstep(.73,.79,key);
	vec3 steel=mix(steel_shadow.rgb,steel_mid.rgb,mid);steel=mix(steel,steel_light.rgb,lit);
	vec3 amber=mix(amber_shadow.rgb,amber_mid.rgb,mid);amber=mix(amber,amber_light.rgb,lit);
	float paint_mask=0.;float ink_mask=0.;float relief=1.;
	if(surface_kind==0){
		vec3 source=textureLod(source_paint,UV,.7).rgb;
		paint_mask=smoothstep(.055,.16,source.r-source.g)*smoothstep(.025,.10,source.g-source.b);
		float value=dot(source,vec3(.2126,.7152,.0722));
		ink_mask=(1.-smoothstep(.018,.075,value))*.55;
		// Preserve recess/brace separation within a controlled common range.
		relief=clamp(pow(max(value,.001)/.18,.45),.32,1.14);
	}
	if(surface_kind==2){paint_mask=1.;}
	vec3 colour=mix(steel,amber,paint_mask);
	if(surface_kind==3){colour=mix(colour,steel_light.rgb,.24);}
	if(surface_kind==4){colour=mix(colour,steel_light.rgb,.45);}
	if(surface_kind==5){colour=ink_colour.rgb;}
	if(surface_kind==6){colour=mix(colour,steel_light.rgb,.30);}
	ALBEDO=mix(colour*relief,ink_colour.rgb,ink_mask);
}

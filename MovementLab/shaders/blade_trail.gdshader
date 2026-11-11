shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;

// 10 Distinct Stylized Anime Sword Trail Modes:
// 0: Pure White Razor (Minimalist precision, pure white cutting line)
// 1: Ozone Cel Smoke Wake (Scalloped anime SDF smoke puffs, cel rim, dark underbelly)
// 2: High-Voltage Lightning (High-frequency jagged electric bolts & cyan crackles)
// 3: Molten Ember Cleave (Blazing volcanic magma, white-hot core, fire gradient)
// 4: Shadow Ink Sumi-e (Calligraphic Japanese ink wash, bristle streaks, obsidian core)
// 5: Ghost Phantom Mirage (Ethereal spiritual aurora ribbon, prismatic shift)
// 6: Heavy Iron Meat Cleaver (Chunky industrial cel steel with stark ink outline)
// 7: Cyber Neon Glitch (Synthwave digital laser with scanlines, raster notches, magenta/cyan)
// 8: Sakura Blossom Storm (Gentle wind-swept floral cutting ribbon, pastel pink/ivory)
// 9: Supernova Maximum Juice (Colossal comic ray blast, starburst speed notches, radiant aura)

#include "res://shaders/lab_sword_wall.gdshaderinc"

uniform int style_mode = 2;

void vertex() {
	sword_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

// Pseudo-random 2D hash
float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void fragment() {
	if (beyond_sword_wall()) {
		discard;
	}
	// UV.x: 0.0 at oldest tail, 1.0 at leading sword blade
	// UV.y: 0.0 at inner blade base, 1.0 at outer razor cutting tip
	
	float tail_fade = smoothstep(0.0, 0.18, UV.x);
	float inner_fade = smoothstep(0.0, 0.08, UV.y);
	float outer_fade = 1.0 - smoothstep(0.96, 1.0, UV.y);
	float ribbon_mask = inner_fade * outer_fade * tail_fade;
	
	bool is_finisher = (COLOR.r > 0.8 && COLOR.b < 0.6);
	
	vec3 out_color = vec3(1.0);
	float out_alpha = 0.0;
	
	if (style_mode == 0) {
		// ----------------------------------------------------
		// 0: PURE WHITE RAZOR (MINIMALIST PRECISION)
		// ----------------------------------------------------
		float wave = sin(UV.x * 14.0 - TIME * 35.0) * 0.04;
		float d_arc = abs(UV.y - (0.76 + wave));
		float line = 1.0 - smoothstep(0.010, 0.045, d_arc);
		float edge = smoothstep(0.78, 0.94, UV.y);
		float energy = clamp(line * 1.2 + edge * 0.95, 0.0, 1.0) * tail_fade;
		vec3 halo = is_finisher ? vec3(1.0, 0.90, 0.45) : vec3(0.92, 0.97, 1.0);
		out_color = mix(halo, vec3(1.0), clamp(line * 1.6 + edge * 1.2 - 0.35, 0.0, 1.0));
		out_alpha = clamp(energy * ribbon_mask * 1.35 * COLOR.a, 0.0, 1.0);
	}
	else if (style_mode == 1) {
		// ----------------------------------------------------
		// 1: OZONE CEL SMOKE WAKE (ANIME SCALLOPED PUFFS)
		// ----------------------------------------------------
		float cut_wave = sin(UV.x * 9.0 - TIME * 8.0) * 0.018;
		float y_cut = 0.44 + cut_wave;
		float d_cut = abs(UV.y - y_cut);
		float razor_core = (1.0 - smoothstep(0.010, 0.030, d_cut)) * tail_fade;
		float razor_halo = (1.0 - smoothstep(0.024, 0.090, d_cut)) * tail_fade;
		
		const int NUM_PUFFS = 8;
		float puff_u[8] = float[](0.92, 0.80, 0.68, 0.55, 0.42, 0.30, 0.18, 0.06);
		float puff_y[8] = float[](0.48, 0.54, 0.61, 0.66, 0.67, 0.63, 0.56, 0.48);
		float puff_r[8] = float[](0.14, 0.20, 0.25, 0.27, 0.27, 0.25, 0.21, 0.15);
		float min_sdf = 999.0;
		float nearest_r = 0.25;
		float nearest_dist = 0.0;
		
		for (int i = 0; i < NUM_PUFFS; i++) {
			float anim_y = puff_y[i] + 0.020 * sin(TIME * 13.0 + float(i) * 1.9);
			float anim_r = puff_r[i] + 0.012 * cos(TIME * 11.0 + float(i) * 2.3);
			vec2 diff = vec2((UV.x - puff_u[i]) * 2.7, UV.y - anim_y);
			float d_center = length(diff);
			float sdf = d_center - anim_r;
			if (sdf < min_sdf) {
				min_sdf = sdf;
				nearest_r = anim_r;
				nearest_dist = d_center;
			}
		}
		float corridor_sdf = d_cut - 0.16 * smoothstep(0.02, 0.35, UV.x);
		float smoke_sdf = min(min_sdf, corridor_sdf);
		float smoke_mask = (1.0 - smoothstep(-0.015, 0.015, smoke_sdf)) * tail_fade;
		float is_rim = smoothstep(nearest_r * 0.74, nearest_r * 0.78, nearest_dist);
		float cel_rim = is_rim * (1.0 - smoothstep(nearest_r - 0.02, nearest_r + 0.02, nearest_dist));
		
		vec3 col_shadow = is_finisher ? vec3(0.12, 0.06, 0.03) : vec3(0.05, 0.08, 0.12);
		vec3 col_smoke = is_finisher ? vec3(0.52, 0.33, 0.12) : vec3(0.08, 0.32, 0.38);
		vec3 col_rim = is_finisher ? vec3(1.0, 0.82, 0.30) : vec3(0.32, 0.98, 0.86);
		float is_upper = smoothstep(y_cut - 0.02, y_cut + 0.06, UV.y);
		vec3 base = mix(col_shadow, col_smoke, is_upper * 0.88);
		out_color = mix(base, col_rim, cel_rim * 0.92);
		out_color = mix(out_color, col_rim, razor_halo * 0.95);
		out_color = mix(out_color, vec3(1.0), razor_core);
		out_alpha = clamp(max(mix(0.68, 0.82, is_upper), max(razor_core, cel_rim)) * smoke_mask * COLOR.a, 0.0, 1.0);
	}
	else if (style_mode == 2) {
		// ----------------------------------------------------
		// 2: HIGH-VOLTAGE LIGHTNING (JAGGED ARCS & CRACKLES)
		// ----------------------------------------------------
		float t_fast = TIME * 60.0;
		float bolt1_jitter = sin(UV.x * 25.0 + t_fast) * 0.09 + (hash21(vec2(floor(UV.x * 24.0), floor(t_fast * 0.4))) - 0.5) * 0.06;
		float bolt1 = 1.0 - smoothstep(0.005, 0.032, abs(UV.y - (0.72 + bolt1_jitter)));
		float bolt2_jitter = cos(UV.x * 32.0 - t_fast * 0.9) * 0.10 + (hash21(vec2(floor(UV.x * 20.0) + 5.2, floor(t_fast * 0.5))) - 0.5) * 0.07;
		float bolt2 = 1.0 - smoothstep(0.004, 0.026, abs(UV.y - (0.42 + bolt2_jitter)));
		float spark_dot = (1.0 - smoothstep(0.08, 0.25, length(fract(vec2(UV.x * 22.0, UV.y * 9.0)) - vec2(0.5)))) * step(0.72, hash21(floor(vec2(UV.x * 22.0, UV.y * 9.0)) + vec2(floor(t_fast * 0.35), 0.0)));
		float edge_spark = smoothstep(0.82, 0.96, UV.y);
		float plasma_glow = pow(sin(clamp(UV.y, 0.0, 1.0) * 3.14159), 2.2) * 0.30;
		float elec = clamp(bolt1 * 1.35 + bolt2 * 0.95 + spark_dot * 0.9 + edge_spark * 0.85 + plasma_glow, 0.0, 1.0) * tail_fade;
		vec3 elec_col = is_finisher ? vec3(1.0, 0.86, 0.30) : vec3(0.32, 0.92, 1.0);
		out_color = mix(elec_col, vec3(1.0), clamp(bolt1 * 1.8 + edge_spark * 1.2 + plasma_glow * 0.35 - 0.35, 0.0, 1.0));
		out_alpha = clamp(elec * ribbon_mask * 1.50 * COLOR.a, 0.0, 1.0);
	}
	else if (style_mode == 3) {
		// ----------------------------------------------------
		// 3: MOLTEN EMBER CLEAVE (VOLCANIC FIRE / MAGMA)
		// ----------------------------------------------------
		float fire_wave = sin(UV.x * 12.0 - TIME * 20.0) * 0.06 + sin(UV.x * 24.0 + TIME * 14.0) * 0.03;
		float core_y = 0.70 + fire_wave;
		float heat_core = 1.0 - smoothstep(0.012, 0.060, abs(UV.y - core_y));
		float flame_body = smoothstep(0.12, 0.85, UV.y);
		vec3 dark_soot = vec3(0.15, 0.03, 0.02);
		vec3 hot_red = vec3(0.95, 0.15, 0.05);
		vec3 bright_orange = vec3(1.0, 0.60, 0.05);
		vec3 white_heat = vec3(1.0, 0.98, 0.88);
		vec3 fire_col = mix(dark_soot, hot_red, flame_body);
		fire_col = mix(fire_col, bright_orange, clamp(heat_core * 1.2 + flame_body * 0.5, 0.0, 1.0));
		fire_col = mix(fire_col, white_heat, clamp(heat_core * 1.8 - 0.3, 0.0, 1.0));
		out_color = fire_col;
		out_alpha = clamp((heat_core * 1.2 + flame_body * 0.75) * ribbon_mask * COLOR.a, 0.0, 1.0);
	}
	else if (style_mode == 4) {
		// ----------------------------------------------------
		// 4: SHADOW INK (SUMI-E CALLIGRAPHIC BRUSH)
		// ----------------------------------------------------
		float bristle = pow(0.5 + 0.5 * sin(UV.y * 65.0 + UV.x * 18.0), 3.0) * 0.25;
		float ink_core = smoothstep(0.10, 0.38, UV.y) * (1.0 - smoothstep(0.85, 0.98, UV.y));
		float white_slit = 1.0 - smoothstep(0.008, 0.035, abs(UV.y - 0.74));
		float splat_noise = step(0.68, hash21(floor(vec2(UV.x * 28.0, UV.y * 14.0))));
		vec3 ink_black = is_finisher ? vec3(0.80, 0.12, 0.08) : vec3(0.06, 0.07, 0.09); // Vermillion seal for finisher
		vec3 paper_white = vec3(0.98, 0.99, 1.0);
		out_color = mix(ink_black, paper_white, white_slit * 0.95);
		float ink_alpha = clamp((ink_core + bristle + white_slit + splat_noise * 0.35) * ribbon_mask * 1.35 * COLOR.a, 0.0, 1.0);
		out_alpha = ink_alpha;
	}
	else if (style_mode == 5) {
		// ----------------------------------------------------
		// 5: GHOST PHANTOM MIRAGE (SPIRIT AURORA)
		// ----------------------------------------------------
		float mirage1 = sin(UV.x * 8.0 - TIME * 12.0) * 0.08;
		float mirage2 = cos(UV.x * 16.0 + TIME * 15.0) * 0.05;
		float band1 = 1.0 - smoothstep(0.02, 0.12, abs(UV.y - (0.65 + mirage1)));
		float band2 = 1.0 - smoothstep(0.02, 0.14, abs(UV.y - (0.45 + mirage2)));
		vec3 col_violet = vec3(0.65, 0.30, 1.0);
		vec3 col_cyan = vec3(0.20, 0.95, 0.88);
		vec3 spirit_core = vec3(1.0, 0.95, 1.0);
		vec3 spirit_col = mix(col_violet, col_cyan, sin(UV.x * 6.0 + TIME * 4.0) * 0.5 + 0.5);
		spirit_col = mix(spirit_col, spirit_core, clamp((band1 + band2) * 0.9 - 0.2, 0.0, 1.0));
		out_color = spirit_col;
		out_alpha = clamp((band1 * 0.9 + band2 * 0.75) * ribbon_mask * 1.15 * COLOR.a, 0.0, 1.0);
	}
	else if (style_mode == 6) {
		// ----------------------------------------------------
		// 6: HEAVY IRON MEAT CLEAVER (COMPACT INDUSTRIAL STEEL)
		// ----------------------------------------------------
		float edge_sharp = smoothstep(0.82, 0.96, UV.y);
		float steel_body = smoothstep(0.25, 0.65, UV.y);
		vec3 iron_dark = vec3(0.12, 0.16, 0.18);
		vec3 steel_mid = vec3(0.55, 0.65, 0.70);
		vec3 chrome_white = vec3(1.0, 1.0, 1.0);
		vec3 cleaver_col = mix(iron_dark, steel_mid, steel_body);
		cleaver_col = mix(cleaver_col, chrome_white, edge_sharp);
		out_color = cleaver_col;
		out_alpha = clamp((steel_body * 0.85 + edge_sharp * 0.95) * ribbon_mask * COLOR.a, 0.0, 1.0);
	}
	else if (style_mode == 7) {
		// ----------------------------------------------------
		// 7: CYBER NEON GLITCH (SYNTHWAVE SCANLINES)
		// ----------------------------------------------------
		float scanline = step(0.40, sin(UV.y * 90.0));
		float glitch_notch = step(0.75, sin(UV.x * 35.0 + floor(TIME * 18.0) * 1.5));
		float beam = 1.0 - smoothstep(0.015, 0.065, abs(UV.y - 0.78));
		vec3 neon_magenta = vec3(1.0, 0.08, 0.65);
		vec3 neon_cyan = vec3(0.05, 0.95, 0.90);
		vec3 cyber_col = mix(neon_magenta, neon_cyan, UV.x);
		if (glitch_notch > 0.5) cyber_col = vec3(1.0);
		out_color = mix(cyber_col, vec3(1.0), beam * 0.85);
		out_alpha = clamp((beam * 1.3 + scanline * 0.45) * ribbon_mask * COLOR.a, 0.0, 1.0);
	}
	else if (style_mode == 8) {
		// ----------------------------------------------------
		// 8: SAKURA BLOSSOM STORM (FLORAL STREAM)
		// ----------------------------------------------------
		float petal_wave = sin(UV.x * 10.0 - TIME * 14.0) * 0.06;
		float petal_ribbon = 1.0 - smoothstep(0.02, 0.09, abs(UV.y - (0.68 + petal_wave)));
		float wind_stream = smoothstep(0.35, 0.85, UV.y);
		vec3 rose_pink = vec3(1.0, 0.55, 0.75);
		vec3 pale_blossom = vec3(1.0, 0.88, 0.94);
		vec3 petal_col = mix(rose_pink, pale_blossom, wind_stream);
		petal_col = mix(petal_col, vec3(1.0), petal_ribbon * 0.9);
		out_color = petal_col;
		out_alpha = clamp((petal_ribbon * 1.1 + wind_stream * 0.65) * ribbon_mask * COLOR.a, 0.0, 1.0);
	}
	else if (style_mode == 9) {
		// ----------------------------------------------------
		// 9: SUPERNOVA MAXIMUM JUICE (EXPLOSIVE CLIMAX BLAST)
		// ----------------------------------------------------
		float beam_wave = sin(UV.x * 18.0 - TIME * 45.0) * 0.04;
		float core = 1.0 - smoothstep(0.012, 0.040, abs(UV.y - (0.68 + beam_wave)));
		float radiant_aura = smoothstep(0.10, 0.85, UV.y);
		float ray_burst = pow(0.5 + 0.5 * sin(UV.x * 40.0 + UV.y * 30.0), 3.0) * 0.4;
		vec3 gold_corona = vec3(1.0, 0.70, 0.15);
		vec3 cyan_flare = vec3(0.25, 0.95, 1.0);
		vec3 super_col = mix(gold_corona, cyan_flare, sin(UV.x * 8.0 + TIME * 10.0) * 0.5 + 0.5);
		super_col = mix(super_col, vec3(1.0), clamp(core * 2.0 + ray_burst - 0.2, 0.0, 1.0));
		out_color = super_col;
		out_alpha = clamp((core * 1.4 + radiant_aura * 0.75 + ray_burst) * ribbon_mask * 1.35 * COLOR.a, 0.0, 1.0);
	}
	
	ALBEDO = out_color;
	ALPHA = out_alpha;
}

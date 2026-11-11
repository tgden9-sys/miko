shader_type canvas_item;

uniform vec4 grid_color : source_color = vec4(1.0, 0.16, 0.25, 1.0);
uniform vec4 glow_color : source_color = vec4(1.0, 0.35, 0.45, 0.6);
uniform vec2 grid_size = vec2(10.0, 6.0);
uniform float line_thickness : hint_range(0.001, 0.05) = 0.018;
uniform float pulse_speed : hint_range(0.0, 10.0) = 2.0;
uniform float pulse_intensity : hint_range(0.0, 1.0) = 0.25;
uniform float border_thickness : hint_range(0.0, 0.1) = 0.02;

void fragment() {
    vec2 uv = UV;
    
    // Grid coordinates
    vec2 cell = fract(uv * grid_size);
    vec2 dist_to_line = min(cell, 1.0 - cell);
    
    // Normalized distance to grid lines
    float line_dist_x = dist_to_line.x / (grid_size.x * 0.1);
    float line_dist_y = dist_to_line.y / (grid_size.y * 0.1);
    float min_dist = min(dist_to_line.x, dist_to_line.y);
    
    // Core line and outer glow
    float core = smoothstep(line_thickness * 0.5, 0.0, min_dist);
    float glow = smoothstep(line_thickness * 2.8, 0.0, min_dist);
    
    // Border frame
    vec2 border_dist = min(uv, 1.0 - uv);
    float border_min = min(border_dist.x, border_dist.y);
    float border_core = smoothstep(border_thickness, 0.0, border_min);
    float border_glow = smoothstep(border_thickness * 2.5, 0.0, border_min);
    
    // Pulse animation
    float pulse = 1.0 + sin(TIME * pulse_speed) * pulse_intensity;
    
    // Combine
    float total_core = max(core, border_core);
    float total_glow = max(glow, border_glow);
    
    vec4 final_color = mix(glow_color * total_glow, grid_color, total_core) * pulse;
    
    // Subtle backdrop tint
    vec4 bg_tint = vec4(grid_color.rgb * 0.04, 0.08);
    
    COLOR = mix(bg_tint, final_color, clamp(total_core + total_glow * 0.8, 0.0, 1.0));
}

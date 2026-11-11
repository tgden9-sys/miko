shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
uniform float floor_height = 0.0;
varying float world_y;
void vertex() { world_y = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y; }
void fragment() {
    if (world_y < floor_height + 0.012) discard;
    ALBEDO = COLOR.rgb;
    ALPHA = COLOR.a;
}

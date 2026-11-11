shader_type spatial;
#include "res://shaders/miko8_transfer_common.gdshaderinc"
uniform sampler2D base_texture : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D metal_rough_texture : filter_linear_mipmap_anisotropic;
uniform float metallic_factor = 1.0;
uniform float roughness_factor = 1.0;
uniform int polarity = 0;
uniform vec4 scene_tint : source_color = vec4(1.0);
uniform float scene_roughness_bias = 0.0;
void fragment() {
    vec3 transfer_point = (INV_VIEW_MATRIX * vec4(VERTEX, 1.)).xyz;
    if (transfer_progress > 0. && transfer_distance(transfer_point) < 0.) discard;
    vec3 base = texture(base_texture, UV).rgb;
    float dominance = base.g - max(base.r, base.b);
    float mask = smoothstep(0.035, 0.15, dominance) * smoothstep(0.06, 0.22, base.g);
    vec3 pole = polarity == 1 ? vec3(1.0, 0.025, 0.045) : vec3(0.02, 0.32, 1.0);
    vec3 recolored = pole * max(base.r, max(base.g, base.b));
    vec3 accent = polarity == 0 ? base : recolored;
    float value = max(accent.r, max(accent.g, accent.b));
    vec3 softened = mix(vec3(value * 0.58), accent, 0.32);
    ALBEDO = transfer_paint(mix(base, softened, mask) * scene_tint.rgb, transfer_point, NORMAL, VIEW);
    vec3 mr = texture(metal_rough_texture, UV).rgb;
    METALLIC = mr.b * metallic_factor;
    ROUGHNESS = clamp(mr.g * roughness_factor + scene_roughness_bias,0.0,1.0);
}


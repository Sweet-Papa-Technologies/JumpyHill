shader_type spatial;
render_mode cull_disabled, depth_prepass_alpha;
uniform vec4 tint : source_color = vec4(0.42, 0.85, 0.95, 0.22);
void fragment() {
 float border = 1.0 - step(0.022, min(min(UV.x, 1.0-UV.x), min(UV.y, 1.0-UV.y)));
 float shine = (1.0-smoothstep(0.0,0.025,abs(UV.x-UV.y*0.3-0.32))) * 0.28;
 ALBEDO = mix(tint.rgb, vec3(0.91,1.0,1.0), border * 0.85 + shine);
 ALPHA = max(tint.a + shine, border * 0.85);
 ROUGHNESS = 0.16;
 METALLIC = 0.15;
 EMISSION = tint.rgb * border * 0.24;
}

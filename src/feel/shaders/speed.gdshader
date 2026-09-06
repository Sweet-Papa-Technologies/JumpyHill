shader_type canvas_item;
uniform float speed : hint_range(0.0, 1.0) = 0.0;
uniform float combo : hint_range(0.0, 1.0) = 0.0;
void fragment() {
    vec2 direction = UV - vec2(0.5);
    vec4 sharp = texture(TEXTURE, UV);
    vec4 smear = texture(TEXTURE, UV - direction * speed * 0.006);
    smear += texture(TEXTURE, UV - direction * speed * 0.012);
    vec3 rgb = mix(sharp.rgb, smear.rgb * 0.5, speed * 0.15);
    float edge = smoothstep(0.3, 0.75, length(direction));
    rgb *= 1.0 - edge * combo * 0.08;
    COLOR = vec4(rgb, sharp.a);
}

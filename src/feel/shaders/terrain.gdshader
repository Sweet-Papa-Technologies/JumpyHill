shader_type spatial;
render_mode diffuse_burley;
uniform vec4 ground_color : source_color;
uniform vec4 verge_color : source_color;
uniform float track_width = 16.0;
uniform int biome = 0;
varying vec3 local_pos;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
 vec2 i = floor(p), f = fract(p); f = f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void vertex() { local_pos = VERTEX; }
void fragment() {
 float grain = noise(local_pos.xz * 19.0);
 float broad = noise(local_pos.xz * 0.5);
 float verge = smoothstep(track_width * 0.37, track_width * 0.45, abs(local_pos.x));
 vec3 base = mix(ground_color.rgb, verge_color.rgb, verge * 0.65);
 float tracks = smoothstep(0.92,1.0, sin(local_pos.x * 3.1 + sin(local_pos.z * 0.22)));
 ALBEDO = base * (0.90 + broad * 0.12 + grain * 0.09 - tracks * 0.025);
 ROUGHNESS = 0.9;
 if (biome == 3) {
  float grid = pow(max(abs(sin(local_pos.x * 1.57)),abs(sin(local_pos.z * 1.57))),70.0);
  EMISSION = verge_color.rgb * grid * 0.10;
 }
}

extends RefCounted
## Colours the shared card frame (drawn in Mira's purple) for the other characters in battle, the way the codex already does:
## Severin crimson, Calamo moss green, Esca ember orange. Starter cards (owner "common") take the colour of the hero in the fight.
const SHADER := """shader_type canvas_item;
uniform float hue = 0.0;
uniform float sat = 1.0;
uniform float val = 1.0;
vec3 rgb2hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}
vec3 hsv2rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}
void fragment() {
	vec4 t = texture(TEXTURE, UV);
	vec3 h = rgb2hsv(t.rgb);
	h.x = fract(h.x + hue);
	h.y = clamp(h.y * sat, 0.0, 1.0);
	h.z = clamp(h.z * val, 0.0, 1.0);
	COLOR = vec4(hsv2rgb(h), t.a) * COLOR;
}"""
## owner -> [hue shift, saturation, value] relative to the purple frame (the same numbers as codex_screen.OWNER_TINT)
const TINT := {"severin": [0.24, 1.0, 1.0], "calamo": [0.5, 0.8, 1.0], "esca": [0.36, 1.0, 1.1]}
## The character in the current fight (set by main.show_battle).
static var hero := ""
static var _materials: Dictionary = {}

## The tint for a card of `owner` (a "common" card takes the hero's), or null when the frame stays as it is.
static func material_for(owner: String) -> Material:
	var key := hero if owner == "common" or owner.is_empty() else owner
	if not TINT.has(key): return null
	if not _materials.has(key):
		var shader := Shader.new()
		shader.code = SHADER
		var material := ShaderMaterial.new()
		material.shader = shader
		material.set_shader_parameter("hue", TINT[key][0])
		material.set_shader_parameter("sat", TINT[key][1])
		material.set_shader_parameter("val", TINT[key][2])
		_materials[key] = material
	return _materials[key]

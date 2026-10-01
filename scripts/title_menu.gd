extends Control
signal chosen(action: String)
const TITLE := "잿빛 원정대"
var canvas: Control
var buttons: Array[Button] = []
var highlights: Array[TextureRect] = []
var elapsed := 0.0
var hovered := -1

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := TextureRect.new()
	backdrop.texture = load("res://assets/backgrounds/title_ruins_v1.png")
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	canvas = Control.new()
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(canvas)
	var logo := TextureRect.new()
	logo.name = "GameTitle"
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.texture = load("res://assets/ui/title/ashen_logo_v2.png")
	logo.position = Vector2(470, 80)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.size = Vector2(660, 330)
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(logo)
	logo.set_deferred("size", Vector2(660, 330))
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Batang", "Noto Serif CJK KR", "serif"])
	font.font_weight = 700
	var shader := Shader.new()
	shader.code = """shader_type canvas_item;
render_mode blend_add;
uniform float strength = 0.7;
void fragment() {
 vec4 tex = texture(TEXTURE, UV);
 float brightness = max(tex.r, max(tex.g, tex.b));
 float edge = 0.0;
 for (int x = -2; x <= 2; x++) {
  for (int y = -2; y <= 2; y++) {
   vec4 n = texture(TEXTURE, UV + vec2(float(x)*0.003, float(y)*0.018));
   edge += max(n.r, max(n.g, n.b))*n.a/25.0;
  }
 }
 COLOR = vec4(vec3(0.05,0.95,0.88), clamp(edge*1.8 + brightness*tex.a*0.65,0.0,1.0) * strength);
}"""
	var labels := ["싱글 플레이", "멀티 플레이", "도감", "설정", "종료하기"]
	var actions := ["single", "multi", "codex", "settings", "quit"]
	for i in range(labels.size()):
		var button := Button.new()
		button.name = actions[i]
		button.text = labels[i]
		button.position = Vector2(600, 452 + i * 64)
		button.size = Vector2(400, 54)
		button.add_theme_font_override("font", font)
		button.add_theme_font_size_override("font_size", 26)
		button.add_theme_color_override("font_color", Color("dfd1b8"))
		button.add_theme_color_override("font_hover_color", Color("fff6df"))
		button.add_theme_color_override("font_focus_color", Color("fff6df"))
		button.add_theme_color_override("font_outline_color", Color("c5bda9"))
		button.add_theme_constant_override("outline_size", 1)
		button.add_theme_color_override("font_shadow_color", Color("030808"))
		button.add_theme_constant_override("shadow_offset_y", 2)
		for state in ["normal", "hover", "pressed", "focus"]:
			button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		var art := TextureRect.new()
		art.texture = load("res://assets/ui/title/menu_frame_v2.png")
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.position = Vector2(-25, -30)
		art.size = Vector2(450, 114)
		art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.show_behind_parent = true
		button.add_child(art)
		var light := art.duplicate() as TextureRect
		var glow_material := ShaderMaterial.new()
		glow_material.shader = shader
		light.material = glow_material
		button.add_child(light)
		highlights.append(light)
		button.mouse_entered.connect(func(): hovered = i)
		button.mouse_exited.connect(func():
			if hovered == i: hovered = -1
		)
		button.pressed.connect(func(): chosen.emit(actions[i]))
		canvas.add_child(button)
		buttons.append(button)
	buttons[1].tooltip_text = "친구 원정 · 네트워크 기능 준비 중"
	buttons[3].tooltip_text = "설정 기능 준비 중"
	resized.connect(_layout)
	_layout()
	buttons[0].grab_focus()

func _layout() -> void:
	var ratio := minf(size.x / 1600.0, size.y / 900.0)
	canvas.scale = Vector2.ONE * ratio
	canvas.position = (size - Vector2(1600, 900) * ratio) / 2.0

func _process(delta: float) -> void:
	elapsed += delta
	for i in range(buttons.size()):
		var active := hovered == i or (hovered < 0 and buttons[i].has_focus())
		highlights[i].visible = active
		highlights[i].material.set_shader_parameter("strength", 0.65 + sin(elapsed * 2.0) * 0.15)
		buttons[i].get_child(0).modulate = Color(0.7, 0.85, 0.85) if buttons[i].button_pressed else Color.WHITE

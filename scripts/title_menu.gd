extends Control

signal chosen(action: String)
var canvas: Control
var buttons: Array[Button] = []
var elapsed := 0.0
var glow: Label

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
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Batang", "Noto Serif CJK KR", "serif"])
	_label("ASHEN EXPEDITION", Rect2(320, 130, 800, 35), 19, Color("b4b7af"), font)
	glow = _label("✦", Rect2(620, 60, 200, 70), 52, Color("a6d4d4"), font)
	var heading := _label("잿빛 원정대", Rect2(230, 170, 980, 130), 92, Color("ebe7d8"), font)
	heading.name = "GameTitle"
	heading.add_theme_color_override("font_shadow_color", Color("050c12"))
	heading.add_theme_constant_override("shadow_offset_y", 6)
	heading.add_theme_color_override("font_outline_color", Color("152127"))
	heading.add_theme_constant_override("outline_size", 5)
	_label("재 너머, 아직 꺼지지 않은 맹세", Rect2(370, 307, 700, 40), 19, Color("b9c3c1"), font)
	var labels := ["싱글 플레이", "멀티 플레이", "도감", "설정", "종료하기"]
	var actions := ["single", "multi", "codex", "settings", "quit"]
	for i in range(labels.size()):
		var button := Button.new()
		button.name = actions[i]
		button.text = labels[i]
		button.position = Vector2(535, 412 + i * 68)
		button.size = Vector2(370, 55)
		button.add_theme_font_override("font", font)
		button.add_theme_font_size_override("font_size", 25)
		button.add_theme_color_override("font_color", Color("d8d0bd"))
		button.add_theme_color_override("font_hover_color", Color("fff4d7"))
		button.add_theme_color_override("font_focus_color", Color("fff4d7"))
		for state in ["normal", "hover", "pressed", "focus"]:
			var box := StyleBoxFlat.new()
			box.bg_color = Color(0.025, 0.06, 0.07, 0.94)
			box.border_color = Color("80765c") if state == "normal" else Color("9ad9d3")
			box.set_border_width_all(1 if state == "normal" else 2)
			box.corner_radius_top_left = 12
			box.corner_radius_bottom_right = 12
			box.shadow_color = Color(0.2, 0.8, 0.78, 0.25) if state != "normal" else Color(0, 0, 0, 0.6)
			box.shadow_size = 10 if state != "normal" else 4
			button.add_theme_stylebox_override(state, box)
		button.pressed.connect(func(): chosen.emit(actions[i]))
		canvas.add_child(button)
		buttons.append(button)
		_label("◇", Rect2(505, 420+i*68, 30, 40), 25, Color("b9a579"), font)
		_label("◇", Rect2(905, 420+i*68, 30, 40), 25, Color("b9a579"), font)
	buttons[1].tooltip_text = "친구 원정 · 네트워크 기능 준비 중"
	buttons[3].tooltip_text = "설정 기능 준비 중"
	_label("검은 안개 너머로, 원정은 다시 시작된다", Rect2(300, 828, 840, 30), 15, Color("9dacae"), font)
	resized.connect(_layout)
	_layout()
	buttons[0].grab_focus()

func _label(value: String, rect: Rect2, font_size: int, color: Color, font: Font) -> Label:
	var label := Label.new()
	label.text = value
	label.position = rect.position
	label.size = rect.size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	canvas.add_child(label)
	return label

func _layout() -> void:
	var ratio := minf(size.x / 1440.0, size.y / 900.0)
	canvas.scale = Vector2.ONE * ratio
	canvas.position = (size - Vector2(1440, 900) * ratio) / 2.0

func _process(delta: float) -> void:
	elapsed += delta
	if is_instance_valid(glow):
		glow.modulate.a = 0.75 + sin(elapsed * 1.2) * 0.2

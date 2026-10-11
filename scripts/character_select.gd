extends Control
signal character_chosen(character: Dictionary)
signal back_requested
signal codex_requested
const Assets = preload("res://scripts/character_assets.gd")
const Data = preload("res://scripts/game_data.gd")
var roster: Array = []
var selected_index := 0
var canvas := Control.new()
var background := TextureRect.new()
var portrait := TextureRect.new()
var heading: Label
var slot: Label
var biography: Label
var information: Label
var relic_icon := TextureRect.new()
var relic_name: Label
var relic_effect: Label
var selectors: Array[Button] = []
var selector_frames: Array[TextureRect] = []
var selector_labels: Array[Label] = []
var serif := SystemFont.new()
func setup(characters: Array) -> void: roster = characters
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	serif.font_names = PackedStringArray(["Batang", "Noto Serif CJK KR", "serif"])
	var surround := ColorRect.new()
	surround.color = Color("09070e")
	surround.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	surround.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(surround)
	add_child(canvas)
	canvas.size = Vector2(1440,900)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.size = canvas.size
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(background)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.position = Vector2(10,80)
	portrait.size = Vector2(760,720)
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(portrait)
	var back := action("← 돌아가기",Vector2(28,24),Vector2(180,46))
	back.name = "Back"
	for state in ["normal", "hover", "pressed"]: back.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	back.pressed.connect(func(): back_requested.emit())
	heading = text("",Vector2(830,150),Vector2(520,100),72,Color("ecdec4"))
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot = text("",Vector2(830,266),Vector2(520,34),24,Color("d3c3ad"))
	slot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var line := ColorRect.new()
	line.position = Vector2(862,326)
	line.size = Vector2(456,1)
	line.color = Color("8d7654")
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(line)
	biography = text("",Vector2(838,360),Vector2(510,125),23,Color("e5dbce"))
	biography.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	information = text("",Vector2(830,502),Vector2(520,34),18,Color("c1b396"))
	information.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	relic_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	relic_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	relic_icon.position = Vector2(861,550)
	relic_icon.size = Vector2(88,88)
	relic_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	relic_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(relic_icon)
	relic_name = text("",Vector2(968,552),Vector2(340,32),21,Color("ddc69d"))
	relic_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	relic_effect = text("",Vector2(968,592),Vector2(340,50),17,Color("c6b9a9"))
	relic_effect.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var start := action("",Vector2(910,654),Vector2(360,76))
	start.name = "StartExpedition"
	for state in ["normal", "hover", "pressed", "focus"]: start.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	var start_frame := decoration("res://assets/ui/selection/expedition_button.svg", start, Vector2.ZERO, Vector2(360,76))
	start.mouse_entered.connect(func(): start_frame.modulate = Color(1.25,1.18,1.3))
	start.mouse_exited.connect(func(): start_frame.modulate = Color.WHITE)
	var start_caption := text("원정 시작",Vector2(910,654),Vector2(360,76),25,Color("ebddc5"))
	start_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	start_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var button_font := SystemFont.new()
	button_font.font_names = PackedStringArray(["Noto Serif KR", "Noto Serif CJK KR", "Batang"])
	button_font.font_weight = 600
	start_caption.add_theme_font_override("font", button_font)
	start_caption.add_theme_constant_override("outline_size", 0)
	start_caption.add_theme_constant_override("shadow_offset_y", 1)
	start_caption.add_theme_color_override("font_color", Color("f2e6cf"))
	start.pressed.connect(func(): character_chosen.emit(roster[selected_index]))
	var difficulty := text("난이도 0 · 기본 원정",Vector2(910,743),Vector2(360,28),16,Color("b6a58e"))
	difficulty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for i in range(roster.size()):
		var ch: Dictionary = roster[i]
		var button := action("",Vector2(496+i*120,766),Vector2(104,114))
		button.name = "Character_" + str(ch.id)
		button.tooltip_text = ch.name + " · " + ch.class
		var art := TextureRect.new()
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.texture = Assets.picture(ch.id,"map_portrait")
		art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		art.position = Vector2(15,15)
		art.size = Vector2(74,84)
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var mask := Shader.new()
		mask.code = "shader_type canvas_item; void fragment(){ vec2 p=(UV-vec2(0.5))*2.0; vec4 c=texture(TEXTURE,UV); c.a*=1.0-smoothstep(0.96,1.0,length(p)); COLOR=c; }"
		var material := ShaderMaterial.new()
		material.shader = mask
		art.material = material
		button.add_child(art)
		for state in ["normal", "hover", "pressed", "focus"]: button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		var frame := decoration("res://assets/ui/selection/portrait_medallion.svg",button,Vector2.ZERO,Vector2(104,114))
		selector_frames.append(frame)
		button.mouse_entered.connect(func(): frame.modulate = Color(1.3,1.18,1.3))
		button.mouse_exited.connect(func(): _refresh_selectors())
		button.focus_entered.connect(func(): frame.modulate = Color(1.3,1.18,1.3))
		button.focus_exited.connect(func(): _refresh_selectors())
		var caption := text(ch.name,Vector2(496+i*120,875),Vector2(104,24),16,Color("dac8a4"))
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		selector_labels.append(caption)
		button.pressed.connect(_select.bind(i))
		selectors.append(button)
	resized.connect(_fit)
	_fit()
	_select(0)

func _fit() -> void:
	var ratio := minf(size.x/1440.0,size.y/900.0)
	canvas.scale = Vector2.ONE * ratio
	canvas.position = (size-Vector2(1440,900)*ratio)*0.5

func box(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	return style

func text(value: String, at: Vector2, dimensions: Vector2, font_size: int, color: Color) -> Label:
	var item := Label.new()
	item.text = value
	item.position = at
	item.size = dimensions
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.add_theme_font_size_override("font_size",font_size)
	if font_size >= 22:
		item.add_theme_font_override("font", serif)
		item.add_theme_constant_override("outline_size", 1)
		item.add_theme_color_override("font_outline_color", color.darkened(0.2))
	item.add_theme_color_override("font_shadow_color", Color.BLACK)
	item.add_theme_constant_override("shadow_offset_y", 2)
	item.add_theme_color_override("font_color",color)
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(item)
	return item

func action(value: String, at: Vector2, dimensions: Vector2) -> Button:
	var item := Button.new()
	item.text = value
	item.position = at
	item.size = dimensions
	item.add_theme_font_size_override("font_size",22)
	item.add_theme_font_override("font", serif)
	item.add_theme_color_override("font_color",Color("f1e2c9"))
	item.add_theme_stylebox_override("normal",box(Color("10141a"),Color("93754d")))
	item.add_theme_stylebox_override("hover",box(Color("462851"),Color("e0bc80")))
	item.add_theme_stylebox_override("pressed",box(Color("100c17"),Color("b59665")))
	canvas.add_child(item)
	return item


func _select(index: int) -> void:
	selected_index = index
	var ch: Dictionary = roster[index]
	background.texture = load("res://assets/backgrounds/mira_selection_gallery_v1.png" if ch.id == "mira" else "res://assets/backgrounds/selection_ruins_v2.png")
	portrait.visible = ch.id != "mira"
	if portrait.visible: portrait.texture = Assets.picture(ch.id,"selection")
	heading.text = ch.name
	slot.text = ch.class
	biography.text = "성당 구호원에서 약을 만들던 연금술사.\n지워진 사람들의 흔적을 따라\n다시 성당으로 돌아간다." if ch.id == "mira" else ch.get("selection_bio", ch.theme)
	information.text = "생명력 %d   ·   소지금 120   ·   에너지 3" % ch.max_hp
	var relic := Data.starting_relic(ch.id)
	var relic_path: String = relic.get("art", "")
	relic_icon.texture = load(relic_path) if not relic_path.is_empty() and ResourceLoader.exists(relic_path) else null
	relic_name.text = relic.get("name", "")
	relic_effect.text = Data.relic_text(relic) if not relic.is_empty() else ""
	_refresh_selectors()

func _refresh_selectors() -> void:
	for i in range(selectors.size()):
		selector_frames[i].modulate = Color(1.3,1.15,1.4) if i==selected_index else Color(0.55,0.5,0.48)
		selector_labels[i].visible = i==selected_index
func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		back_requested.emit()
		get_viewport().set_input_as_handled()

func decoration(path: String, parent: Node, at: Vector2, dimensions: Vector2) -> TextureRect:
	var art := TextureRect.new()
	art.texture = load(path)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.position = at
	art.size = dimensions
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(art)
	return art


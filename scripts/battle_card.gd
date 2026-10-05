extends Control
const Data = preload("res://scripts/game_data.gd")
const CardStyle = preload("res://scripts/card_style.gd")
const CARD_SIZE := Vector2(220, 330)
var definition: Dictionary
var active := false

func setup(card: Dictionary) -> void:
	definition = card
	size = CARD_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var window := Control.new()
	window.name = "ArtWindow"
	window.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(window)
	var art := TextureRect.new()
	art.name = "Illustration"
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.texture = load(card.art)
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	art.position = Vector2(19, 44)
	art.size = Vector2(183, 175)
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	window.add_child(art)
	var frame := TextureRect.new()
	frame.name = "CharacterFrame"
	frame.texture = load("res://assets/ui/cards/mira_frame_approved_v2.png")
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.size = CARD_SIZE
	frame.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)
	_label("Name", str(card.name), Rect2(51, 21, 134, 25), 22 if str(card.name).length() < 6 else 18, Color("211721"), true)
	var energy := _label("Energy", str(int(card.cost)), Rect2(13, 22, 31, 34), 28, Color("fff5e0"), true)
	energy.add_theme_color_override("font_shadow_color", Color("281031"))
	energy.add_theme_constant_override("shadow_offset_y", 1)
	_label("Type", str(card.type), Rect2(85, 214, 51, 13), 12, Color("211721"), true)
	var text := Data.effect_text(card).replace(". ", ".\n")
	var words := text.split(" ")
	for i in range(words.size()): words[i] = "\u2060".join(words[i].split(""))
	var effect := _label("Effect", " ".join(words), Rect2(28, 239, 164, 63), 16, Color("f7edda"))
	effect.add_theme_constant_override("line_spacing", 3)

func _label(node_name: String, value: String, rect: Rect2, font_size: int, color: Color, bold := false) -> Label:
	var label := Label.new()
	label.name = node_name
	if node_name == "Effect": label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = value
	label.position = rect.position
	label.size = rect.size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Batang", "Noto Serif CJK KR", "serif"])
	font.font_weight = 700 if bold else 400
	var face := FontVariation.new()
	face.base_font = font
	face.variation_embolden = 0.8 if bold else 0.3
	label.add_theme_font_override("font", face)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label

func set_active(value: bool) -> void:
	if active != value:
		active = value
		queue_redraw()

func _draw() -> void:
	if active:
		var outline := StyleBoxFlat.new()
		outline.bg_color = Color.TRANSPARENT
		outline.border_color = Color("8ad8cb")
		outline.set_border_width_all(2)
		outline.set_corner_radius_all(15)
		outline.shadow_color = Color(0.3, 0.9, 0.75, 0.45)
		outline.shadow_size = 10
		draw_style_box(outline, Rect2(10, 13, 200, 305))

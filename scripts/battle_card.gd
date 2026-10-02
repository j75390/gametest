extends Control
const Data = preload("res://scripts/game_data.gd")
const CardStyle = preload("res://scripts/card_style.gd")
const CARD_SIZE := Vector2(220, 330)
var definition: Dictionary
var active := false

func setup(card: Dictionary) -> void:
	definition = card
	var style := CardStyle.resolve(card)
	size = CARD_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var base := StyleBoxFlat.new()
	base.bg_color = style.owner_color.darkened(0.75)
	base.set_corner_radius_all(14)
	base.shadow_color = Color(0, 0, 0, 0.7)
	base.shadow_size = 10
	var backing := Panel.new()
	backing.position = Vector2(8, 8)
	backing.size = Vector2(204, 314)
	backing.add_theme_stylebox_override("panel", base)
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backing)
	var art := TextureRect.new()
	art.name = "Illustration"
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.texture = load(card.art)
	art.position = Vector2(20, 44)
	art.size = Vector2(180, 158)
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)
	var frame := TextureRect.new()
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.texture = load("res://assets/ui/cards/gothic_frame_v1.png")
	frame.size = CARD_SIZE
	frame.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.name = "CharacterFrame"
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; uniform vec4 tint : source_color; void fragment() { vec4 c = texture(TEXTURE, UV); if (UV.y < 0.65 || UV.y > 0.90 || UV.x < 0.13 || UV.x > 0.87) { float l = dot(c.rgb, vec3(0.299, 0.587, 0.114)); c.rgb = mix(c.rgb, tint.rgb * l * 1.6, 0.70); } COLOR = c; }"
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("tint", style.owner_color)
	frame.material = material
	add_child(frame)
	var type_band := ColorRect.new()
	type_band.name = "RarityBand"
	type_band.color = style.rarity_color.darkened(0.55)
	type_band.position = Vector2(30, 183)
	type_band.size = Vector2(160, 20)
	type_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(type_band)
	_label("Name", str(card.name), Rect2(47, 19, 150, 25), 16, Color("f6e6c7"))
	_label("Energy", str(int(card.cost)), Rect2(7, 13, 40, 42), 27, Color("fff0c1"))
	_label("Type", "%s · %s" % [card.type, card.rarity], Rect2(30, 183, 160, 20), 12, style.rarity_color.lightened(0.55))
	var effect := _label("Effect", Data.effect_text(card), Rect2(31, 217, 158, 76), 13, Color("251925"))
	effect.add_theme_constant_override("line_spacing", 1)
	var owner: String = style.owner_label
	_label("Owner", owner + (" · 강화" if card.get("upgraded", false) else " · 기본"), Rect2(30, 299, 160, 19), 11, Color("f1dac0"))

func _label(node_name: String, value: String, rect: Rect2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.name = node_name
	if node_name == "Effect": label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = value
	label.position = rect.position
	label.size = rect.size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
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
		draw_style_box(outline, Rect2(5, 5, 210, 320))

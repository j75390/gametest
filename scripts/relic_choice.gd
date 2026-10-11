extends HBoxContainer
## A row of relic cards (picture, name, rarity, effect) to pick one from. Used by the treasure room and
## by elite/boss rewards. Each card is one button named `<prefix><relic id>`.
signal picked(id: String)
const Data = preload("res://scripts/game_data.gd")
const UiFont = preload("res://scripts/ui_font.gd")
const SLOT := Vector2(300, 340)
const RARITY_TINT := {
	"일반": Color("b9aa95"), "고급": Color("7fc7a0"), "희귀": Color("b58cff"),
	"영웅": Color("e0a35a"), "전설": Color("f2d27a"), "고대": Color("d86a6a")}

func setup(records: Array, prefix: String) -> void:
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 18)
	custom_minimum_size = Vector2(0, SLOT.y + 8)
	for record in records: add_child(_slot(record, prefix))

func _box(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	return style

func _label(parent: Control, value: String, rect: Rect2, size: int, tint: Color, bold := false) -> Label:
	var item := Label.new()
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.custom_minimum_size = rect.size
	item.position = rect.position
	item.size = rect.size
	item.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.add_theme_font_size_override("font_size", size)
	item.add_theme_font_override("font", UiFont.serif(bold))
	item.add_theme_color_override("font_color", tint)
	item.text = value
	parent.add_child(item)
	return item

func _slot(record: Dictionary, prefix: String) -> Button:
	var tint: Color = RARITY_TINT.get(str(record.get("rarity", "일반")), Color("b9aa95"))
	var button := Button.new()
	button.name = prefix + str(record.id)
	button.custom_minimum_size = SLOT
	button.add_theme_stylebox_override("normal", _box(Color("14101b"), tint.darkened(0.45)))
	button.add_theme_stylebox_override("hover", _box(Color("221a2e"), tint))
	button.add_theme_stylebox_override("pressed", _box(Color("2c2240"), tint))
	button.add_theme_stylebox_override("focus", _box(Color("221a2e"), Color("e2bb7e")))
	var art_path := str(record.get("art", ""))
	if not art_path.is_empty() and ResourceLoader.exists(art_path):
		var picture := TextureRect.new()
		picture.texture = load(art_path)
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.position = Vector2(70, 14)
		picture.size = Vector2(160, 160)
		picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(picture)
	_label(button, str(record.name), Rect2(12, 180, 276, 34), 26, Color("ebd8b7"), true)
	_label(button, str(record.get("rarity", "")), Rect2(12, 214, 276, 24), 18, tint)
	var effect := _label(button, Data.relic_text(record), Rect2(18, 242, 264, 90), 18, Color("d4c7c0"))
	effect.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	var id := str(record.id)
	button.pressed.connect(func(): picked.emit(id))
	return button

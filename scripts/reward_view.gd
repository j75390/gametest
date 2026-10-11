extends Control
## Victory screen: gold / potion / relic notes as chips, an optional relic choice (elite, boss) and
## the card choices drawn as real cards. Pure view: main.gd applies whatever is picked.
signal relic_picked(id: String)
signal card_picked(card: Dictionary)
signal skipped

const UiFont = preload("res://scripts/ui_font.gd")
const BattleCard = preload("res://scripts/battle_card.gd")
const RelicChoice = preload("res://scripts/relic_choice.gd")
const BACKGROUND := "res://assets/backgrounds/battle_cathedral_v1.png"
const GOLD := Color("d8b47a")

var canvas := Control.new()
var info: Dictionary

## info: notes (Array of {text, tint}), relic_options (Array of relic records), relic_taken (String), cards (Array)
func setup(data: Dictionary) -> void:
	name = "RewardView"
	info = data

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := ColorRect.new()
	backdrop.color = Color("070509")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	add_child(canvas)
	canvas.size = Vector2(1440, 900)
	if ResourceLoader.exists(BACKGROUND):
		var bg := TextureRect.new()
		bg.texture = load(BACKGROUND)
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.size = Vector2(1440, 900)
		bg.modulate = Color(0.34, 0.30, 0.42)
		canvas.add_child(bg)
	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.02, 0.06, 0.45)
	shade.size = Vector2(1440, 900)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(shade)
	_label("승리", Rect2(0, 22, 1440, 64), 52, Color("e8c171"), canvas)
	_label("전투 보상", Rect2(0, 84, 1440, 32), 22, Color("c9b8d6"), canvas)
	_build_notes()
	var has_relics: bool = not info.get("relic_options", []).is_empty() and str(info.get("relic_taken", "")).is_empty()
	var cards_top := 270.0
	var cards_scale := 1.12
	if has_relics:
		_build_relics()
		cards_top = 576.0
		cards_scale = 0.72
	_build_cards(cards_top, cards_scale, has_relics)
	var skip := Button.new()
	skip.name = "SkipReward"
	skip.text = "보상 스킵 →"
	skip.position = Vector2(570, 826)
	skip.size = Vector2(300, 56)
	skip.focus_mode = Control.FOCUS_NONE
	skip.add_theme_font_size_override("font_size", 24)
	skip.add_theme_font_override("font", UiFont.serif())
	skip.pressed.connect(func(): skipped.emit())
	canvas.add_child(skip)
	resized.connect(_fit)
	_fit()

func _fit() -> void:
	var ratio := minf(size.x / 1440.0, size.y / 900.0)
	canvas.scale = Vector2.ONE * ratio
	canvas.position = (size - Vector2(1440, 900) * ratio) / 2.0

func _label(value: String, rect: Rect2, font_size: int, tint: Color, parent: Control) -> Label:
	var item := Label.new()
	item.text = value
	item.position = rect.position
	item.size = rect.size
	item.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.add_theme_font_size_override("font_size", font_size)
	item.add_theme_font_override("font", UiFont.serif())
	item.add_theme_color_override("font_color", tint)
	item.add_theme_color_override("font_outline_color", Color("120a18"))
	item.add_theme_constant_override("outline_size", 6)
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(item)
	return item

func _box(fill: Color, border: Color, radius := 12, width := 2) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(radius)
	return box

## Gold, potion and relic notes, stacked on the right.
func _build_notes() -> void:
	var y := 24.0
	for note in info.get("notes", []):
		var chip := Panel.new()
		chip.name = "Note"
		chip.position = Vector2(1090, y)
		chip.size = Vector2(330, 46)
		chip.add_theme_stylebox_override("panel", _box(Color(0.09, 0.06, 0.13, 0.9), Color("ad8953")))
		canvas.add_child(chip)
		_label(str(note.text), Rect2(8, 0, 314, 46), 20, note.get("tint", Color("e7dccd")), chip)
		y += 54.0

func _build_relics() -> void:
	_label("유물 보상 · 1개 선택", Rect2(0, 116, 1440, 40), 28, GOLD, canvas)
	var row := RelicChoice.new()
	row.setup(info.relic_options, "RewardRelic_")
	row.position = Vector2(60, 160)
	row.size = Vector2(1320, 348)
	row.picked.connect(func(id): relic_picked.emit(id))
	canvas.add_child(row)

func _build_cards(top: float, scale: float, compact: bool) -> void:
	var cards: Array = info.get("cards", [])
	_label("전용 카드 · 1장 선택", Rect2(0, top - 44 if not compact else top - 40, 1440, 36), 26, GOLD, canvas)
	var size_px := BattleCard.CARD_SIZE * scale
	var gap := 36.0
	var total := cards.size() * size_px.x + maxf(0.0, cards.size() - 1.0) * gap
	var x := (1440.0 - total) / 2.0
	for card in cards:
		var cell := Control.new()
		cell.name = "RewardCard_%s" % card.get("id", "")
		cell.position = Vector2(x, top)
		cell.size = size_px
		canvas.add_child(cell)
		var view := BattleCard.new()
		view.setup(card)
		view.scale = Vector2.ONE * scale
		view.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(view)
		var hit := Button.new()
		hit.name = "Pick"
		hit.size = size_px
		hit.focus_mode = Control.FOCUS_NONE
		var clear := StyleBoxEmpty.new()
		for state in ["normal", "pressed", "disabled", "focus"]:
			hit.add_theme_stylebox_override(state, clear)
		hit.add_theme_stylebox_override("hover", _box(Color(1, 0.9, 0.5, 0.06), Color("f2cf72"), 12, 4))
		hit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		cell.add_child(hit)
		hit.mouse_entered.connect(func():
			cell.z_index = 5
			create_tween().tween_property(view, "position:y", -16.0, 0.12))
		hit.mouse_exited.connect(func():
			cell.z_index = 0
			create_tween().tween_property(view, "position:y", 0.0, 0.12))
		hit.pressed.connect(func(): card_picked.emit(card))
		x += size_px.x + gap

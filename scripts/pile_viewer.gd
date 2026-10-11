extends Control
## Full-screen card grid over a dimmed battle: draw pile, discard pile or the whole deck.
signal closed
const BattleCard = preload("res://scripts/battle_card.gd")
const RARITY_ORDER := ["일반", "고급", "희귀", "영웅", "전설"]
const CARD_SCALE := 0.84
const COLUMNS := 5

func setup(heading: String, cards: Array, caption: String, sort_by_rarity: bool) -> void:
	name = "PileViewer"
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 200
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.05, 0.88)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var title := _label("Heading", heading, Rect2(0, 92, 1440, 44), 32, Color("e8c171"))
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 6)
	var shown := cards.duplicate()
	if sort_by_rarity:
		# The draw pile is shuffled: sorting hides the real draw order.
		shown.sort_custom(func(a, b):
			var ra := RARITY_ORDER.find(str(a.get("rarity", "")))
			var rb := RARITY_ORDER.find(str(b.get("rarity", "")))
			if ra != rb: return ra < rb
			if int(a.get("cost", 0)) != int(b.get("cost", 0)): return int(a.get("cost", 0)) < int(b.get("cost", 0))
			return str(a.get("name", "")) < str(b.get("name", "")))
	if shown.is_empty():
		_label("Empty", "카드가 없습니다.", Rect2(0, 420, 1440, 50), 28, Color("c2adc9"))
	else:
		var scroll := ScrollContainer.new()
		scroll.name = "Scroll"
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.position = Vector2(220, 150)
		scroll.size = Vector2(1000, 640)
		add_child(scroll)
		var grid := GridContainer.new()
		grid.columns = COLUMNS
		grid.add_theme_constant_override("h_separation", 14)
		grid.add_theme_constant_override("v_separation", 14)
		scroll.add_child(grid)
		for card in shown:
			var cell := Control.new()
			cell.custom_minimum_size = BattleCard.CARD_SIZE * CARD_SCALE
			cell.mouse_filter = Control.MOUSE_FILTER_PASS
			grid.add_child(cell)
			var view = BattleCard.new()
			view.setup(card)
			view.scale = Vector2.ONE * CARD_SCALE
			cell.add_child(view)
	var note := _label("Caption", caption, Rect2(0, 806, 1440, 70), 22, Color("f1deb0"))
	note.add_theme_color_override("font_outline_color", Color.BLACK)
	note.add_theme_constant_override("outline_size", 5)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var back := Button.new()
	back.name = "Back"
	back.text = "←  돌아가기"
	back.add_theme_font_size_override("font_size", 24)
	back.add_theme_font_override("font", preload("res://scripts/ui_font.gd").serif())
	back.add_theme_color_override("font_color", Color("fff3d0"))
	for slot in ["normal", "hover", "pressed"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color("5a1a2a") if slot == "normal" else Color("7a2338")
		box.border_color = Color("e0c27a")
		box.set_border_width_all(2)
		box.corner_radius_top_right = 10
		box.corner_radius_bottom_right = 10
		back.add_theme_stylebox_override(slot, box)
	back.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	back.position = Vector2(0, 700)
	back.size = Vector2(230, 66)
	back.pressed.connect(close)
	add_child(back)

func _label(id: String, text: String, rect: Rect2, font: int, color: Color) -> Label:
	var label := Label.new()
	label.name = id
	label.text = text
	label.position = rect.position
	label.size = rect.size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font)
	label.add_theme_font_override("font", preload("res://scripts/ui_font.gd").serif())
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label

func close() -> void:
	if is_queued_for_deletion(): return
	closed.emit()
	queue_free()

func _input(event: InputEvent) -> void:
	if (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE) \
			or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT):
		get_viewport().set_input_as_handled()
		close()

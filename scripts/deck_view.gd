extends Control
## The current deck as real card images. Copies of the same card are stacked with a "x3" badge so a
## starter deck of five Strikes does not fill the page; the filter row narrows it to one card type.
signal closed
const BattleCard = preload("res://scripts/battle_card.gd")
const CARD_SCALE := 0.72
const COLUMNS := 7
const TYPE_ORDER := ["공격", "방어", "스킬", "파워", "저주"]
var cards: Array = []
var hero_name := ""
var filter := "전체"
var canvas := Control.new()
var grid: GridContainer
var scroll: ScrollContainer
var filter_buttons := {}

func setup(deck: Array, character_name: String) -> void:
	cards = deck
	hero_name = character_name

func _ready() -> void:
	name = "DeckView"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.04, 0.03, 0.06, 1.0)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	add_child(canvas)
	canvas.size = Vector2(1440, 900)
	_label("현재 덱", Rect2(70, 34, 500, 64), 46, Color("ebd8b7"))
	_label("%s · 카드 %d장" % [hero_name, cards.size()], Rect2(72, 100, 520, 30), 21, Color("bba0d1"))
	var rule := ColorRect.new()
	rule.color = Color(0.68, 0.56, 0.38, 0.45)
	rule.position = Vector2(70, 142)
	rule.size = Vector2(1300, 1)
	canvas.add_child(rule)
	var types := ["전체"]
	var kinds: Array = []
	for card in cards:
		if not kinds.has(str(card.get("type", ""))): kinds.append(str(card.get("type", "")))
	kinds.sort_custom(func(a, b): return _type_rank(a) < _type_rank(b))
	types.append_array(kinds)
	for i in types.size():
		var kind: String = types[i]
		var count := cards.size() if kind == "전체" else cards.filter(func(c): return str(c.get("type", "")) == kind).size()
		var tab := _button("%s %d" % [kind, count], Rect2(70 + i * 138, 158, 126, 42), 19)
		tab.pressed.connect(_set_filter.bind(kind))
		filter_buttons[kind] = tab
	var close := _button("닫기", Rect2(1210, 40, 160, 52), 22)
	close.pressed.connect(close_view)
	scroll = ScrollContainer.new()
	scroll.name = "DeckScroll"
	scroll.position = Vector2(54, 216)
	scroll.size = Vector2(1332, 660)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	canvas.add_child(scroll)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 24)
	scroll.add_child(margin)
	grid = GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 18)
	margin.add_child(grid)
	resized.connect(fit)
	fit()
	_set_filter("전체")

func fit() -> void:
	var ratio := minf(size.x / 1440.0, size.y / 900.0)
	canvas.scale = Vector2.ONE * ratio
	canvas.position = (size - Vector2(1440, 900) * ratio) * 0.5

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		close_view()
		get_viewport().set_input_as_handled()

func close_view() -> void:
	closed.emit()

## Groups identical cards (same id and upgrade) and orders them by type, cost, name.
func stacks() -> Array:
	var groups := {}
	var order: Array = []
	for card in cards:
		if filter != "전체" and str(card.get("type", "")) != filter: continue
		var key := "%s|%s" % [str(card.get("id", card.get("name", ""))), str(card.get("upgraded", false))]
		if not groups.has(key):
			groups[key] = {"card": card, "count": 0}
			order.append(key)
		groups[key].count += 1
	var list: Array = order.map(func(k): return groups[k])
	list.sort_custom(func(a, b):
		var ta := _type_rank(str(a.card.get("type", "")))
		var tb := _type_rank(str(b.card.get("type", "")))
		if ta != tb: return ta < tb
		if int(a.card.get("cost", 0)) != int(b.card.get("cost", 0)): return int(a.card.get("cost", 0)) < int(b.card.get("cost", 0))
		return str(a.card.get("name", "")) < str(b.card.get("name", "")))
	return list

func _type_rank(kind: String) -> int:
	var at := TYPE_ORDER.find(kind)
	return at if at >= 0 else TYPE_ORDER.size()

func _set_filter(kind: String) -> void:
	filter = kind
	for key in filter_buttons:
		var tab: Button = filter_buttons[key]
		tab.add_theme_stylebox_override("normal", _box(Color("3a2b45") if key == kind else Color("1b1422"), Color("e2bb7e") if key == kind else Color("5d4a3a")))
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
	var cell_size: Vector2 = BattleCard.CARD_SIZE * CARD_SCALE
	for stack in stacks():
		var cell := Control.new()
		cell.custom_minimum_size = cell_size + Vector2(10, 10)
		cell.name = "Stack_" + str(stack.card.get("id", "")).validate_node_name()
		grid.add_child(cell)
		var holder := Control.new()
		holder.position = Vector2(5, 5)
		holder.size = cell_size
		holder.pivot_offset = cell_size * 0.5
		cell.add_child(holder)
		if str(stack.card.get("art", "")).is_empty():
			_plain_card(stack.card, holder, cell_size)
		else:
			var view := BattleCard.new()
			view.setup(stack.card)
			view.scale = Vector2.ONE * CARD_SCALE
			holder.add_child(view)
		if int(stack.count) > 1:
			var badge := Panel.new()
			badge.position = Vector2(cell_size.x - 52, cell_size.y - 20)
			badge.size = Vector2(56, 34)
			badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
			badge.add_theme_stylebox_override("panel", _box(Color(0.07, 0.04, 0.1, 0.94), Color("e2bb7e"), 17))
			holder.add_child(badge)
			var count := Label.new()
			count.text = "×%d" % int(stack.count)
			count.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			count.add_theme_font_size_override("font_size", 20)
			count.add_theme_color_override("font_color", Color("f2dca8"))
			badge.add_child(count)
		cell.mouse_entered.connect(func(): _lift(holder, 1.05))
		cell.mouse_exited.connect(func(): _lift(holder, 1.0))
	scroll.scroll_vertical = 0

func _lift(holder: Control, amount: float) -> void:
	var tween := create_tween()
	tween.tween_property(holder, "scale", Vector2.ONE * amount, 0.1)

func _plain_card(card: Dictionary, parent: Control, cell_size: Vector2) -> void:
	var panel := Panel.new()
	panel.size = cell_size
	panel.add_theme_stylebox_override("panel", _box(Color("1d1526"), Color("8f7250"), 8))
	parent.add_child(panel)
	var text := Label.new()
	text.text = "%s\n비용 %d\n%s" % [card.get("name", ""), int(card.get("cost", 0)), preload("res://scripts/game_data.gd").effect_text(card)]
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.position = Vector2(10, 10)
	text.size = cell_size - Vector2(20, 20)
	text.add_theme_font_size_override("font_size", 17)
	panel.add_child(text)

func _box(fill: Color, border: Color, radius := 4) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	return style

func _label(value: String, rect: Rect2, font_size: int, tint: Color) -> Label:
	var item := Label.new()
	item.text = value
	item.position = rect.position
	item.size = rect.size
	item.add_theme_font_size_override("font_size", font_size)
	item.add_theme_color_override("font_color", tint)
	canvas.add_child(item)
	return item

func _button(value: String, rect: Rect2, font_size: int) -> Button:
	var item := Button.new()
	item.text = value
	item.position = rect.position
	item.size = rect.size
	item.add_theme_font_size_override("font_size", font_size)
	item.add_theme_color_override("font_color", Color("eadcc4"))
	item.add_theme_stylebox_override("normal", _box(Color("1b1422"), Color("5d4a3a")))
	item.add_theme_stylebox_override("hover", _box(Color("33263f"), Color("e2bb7e")))
	item.add_theme_stylebox_override("pressed", _box(Color("33263f"), Color("e2bb7e")))
	item.add_theme_stylebox_override("focus", _box(Color("33263f"), Color("e2bb7e")))
	canvas.add_child(item)
	return item

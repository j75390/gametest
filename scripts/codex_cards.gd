extends "res://scripts/codex_screen.gd"
## Card codex: filter panel on the left, a grid of real cards on the right.
## Hidden cards keep their frame but blur the art and show "미지 / ???". Frames are tinted per owner
## until each character gets its own frame art.
const CodexData = preload("res://scripts/codex_data.gd")
const Data = preload("res://scripts/game_data.gd")
const CARD_SCALE := 0.8
var rows: Array = []
var shown_owners: Array[String] = []
var shown_types: Array[String] = []
var shown_rarities: Array[String] = []
var shown_costs: Array[String] = []
var show_upgraded := false
var preset_owner := ""
var search_text := ""
var search: LineEdit
var grid: GridContainer
var scroll: ScrollContainer
var count_label: Label
var empty_label: Label
var owner_buttons := {}

func build() -> void:
	rows = CodexData.cards(card_character)
	_build_filter_panel()
	scroll = ScrollContainer.new()
	scroll.name = "CardScroll"
	scroll.position = Vector2(336, 34)
	scroll.size = Vector2(1070, 764)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	canvas.add_child(scroll)
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_top", 18)
	pad.add_theme_constant_override("margin_left", 8)
	scroll.add_child(pad)
	grid = GridContainer.new()
	grid.name = "CardGrid"
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 22)
	pad.add_child(grid)
	empty_label = make_label(canvas, "조건에 맞는 카드가 없습니다.", Rect2(336, 360, 1070, 60), 24, MUTED)
	count_label = make_label(canvas, "", Rect2(1196, 806, 210, 46), 26, GOLD, true, HORIZONTAL_ALIGNMENT_RIGHT)
	if not preset_owner.is_empty() and owner_buttons.has(preset_owner): owner_buttons[preset_owner].button_pressed = true
	else: refresh()

func _build_filter_panel() -> void:
	var panel := make_panel(canvas, Rect2(24, 34, 292, 740), Color(0.07, 0.06, 0.1, 0.94), EDGE, 12)
	panel.name = "FilterPanel"
	search = LineEdit.new()
	search.name = "SearchBox"
	search.placeholder_text = "카드 검색"
	search.position = Vector2(14, 14)
	search.size = Vector2(264, 40)
	search.add_theme_font_size_override("font_size", 19)
	search.add_theme_font_override("font", UiFont.serif(false))
	search.text_changed.connect(func(value: String):
		search_text = value.strip_edges()
		refresh())
	panel.add_child(search)
	var y := 68.0
	y = _heading(panel, "캐릭터", y)
	var owners: Array = []
	for row in rows:
		if not owners.has(row.owner): owners.append(row.owner)
	var x := 14.0
	for owner in owners:
		var label := "공용" if owner == "common" else CodexData.owner_name(owner)
		var button := _toggle(panel, label, Rect2(x, y, 124, 36), func(on: bool): _set_filter(shown_owners, owner, on))
		owner_buttons[owner] = button
		x += 130
		if x > 200:
			x = 14.0
			y += 42
	if x > 14.0: y += 42
	y += 6
	y = _heading(panel, "카드 유형", y)
	var types: Array[String] = []
	for row in rows:
		if not types.has(str(row.record.type)): types.append(str(row.record.type))
	x = 14.0
	for kind in types:
		_toggle(panel, kind, Rect2(x, y, 84, 36), func(on: bool): _set_filter(shown_types, kind, on))
		x += 90
	y += 48
	y = _heading(panel, "희귀도", y)
	var rarities: Array[String] = []
	for tier in ["일반", "고급", "희귀", "영웅"]:
		for row in rows:
			if str(row.record.rarity) == tier and not rarities.has(tier): rarities.append(tier)
	x = 14.0
	for tier in rarities:
		_toggle(panel, tier, Rect2(x, y, 124, 36), func(on: bool): _set_filter(shown_rarities, tier, on))
		x += 130
		if x > 200:
			x = 14.0
			y += 42
	if x > 14.0: y += 42
	y += 6
	y = _heading(panel, "비용", y)
	x = 14.0
	for cost in ["0", "1", "2", "3+", "X"]:
		_toggle(panel, cost, Rect2(x, y, 46, 40), func(on: bool): _set_filter(shown_costs, cost, on))
		x += 52
	y += 58
	var upgraded := _toggle(panel, "강화 상태 보기", Rect2(14, y, 264, 40), func(on: bool):
		show_upgraded = on
		refresh())
	upgraded.name = "UpgradeToggle"

func _heading(panel: Panel, text: String, y: float) -> float:
	var plate := make_panel(panel, Rect2(10, y, 272, 34), Color("20202b"), Color("3b4a52"), 6)
	make_label(plate, text, Rect2(0, 0, 272, 34), 20, GOLD, true)
	return y + 42.0

func _toggle(parent: Node, text: String, rect: Rect2, on_change: Callable) -> Button:
	var button := Button.new()
	button.toggle_mode = true
	button.text = text
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_font_override("font", UiFont.serif())
	button.add_theme_color_override("font_color", MUTED)
	button.add_theme_color_override("font_pressed_color", PARCHMENT)
	button.add_theme_color_override("font_hover_color", PARCHMENT)
	button.add_theme_stylebox_override("normal", box(Color("17141d"), Color("3a3342"), 2, 6))
	button.add_theme_stylebox_override("hover", box(Color("231c2c"), Color("8d7bb0"), 2, 6))
	button.add_theme_stylebox_override("pressed", box(Color("3a2b4d"), GOLD, 2, 6))
	button.add_theme_stylebox_override("focus", box(Color("231c2c"), GOLD, 2, 6))
	button.toggled.connect(on_change)
	parent.add_child(button)
	return button

func _set_filter(list: Array, value: String, on: bool) -> void:
	if on and not list.has(value): list.append(value)
	if not on: list.erase(value)
	refresh()

func _cost_key(cost: Variant) -> String:
	if str(cost) == "X": return "X"
	var value := int(cost)
	return "3+" if value >= 3 else str(value)

func _passes(row: Dictionary) -> bool:
	var record: Dictionary = row.record
	if not shown_owners.is_empty() and not shown_owners.has(str(row.owner)): return false
	if not shown_types.is_empty() and not shown_types.has(str(record.type)): return false
	if not shown_rarities.is_empty() and not shown_rarities.has(str(record.rarity)): return false
	if not shown_costs.is_empty() and not shown_costs.has(_cost_key(record.get("cost", 0))): return false
	if not search_text.is_empty():
		# Hidden cards must not be findable by their real name.
		if row.state != "found" or str(record.name).find(search_text) == -1: return false
	return true

func refresh() -> void:
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
	var shown_count := 0
	for row in rows:
		if not _passes(row): continue
		shown_count += 1
		grid.add_child(_card_slot(row))
	empty_label.visible = shown_count == 0
	count_label.text = "%d장" % shown_count if shown_count == rows.size() else "%d장 / 전체 %d장" % [shown_count, rows.size()]

func _card_slot(row: Dictionary) -> Control:
	var slot := Control.new()
	slot.custom_minimum_size = CardView.CARD_SIZE * CARD_SCALE
	var record: Dictionary = row.record
	var shown: Dictionary = Data.upgraded(record) if show_upgraded and not record.get("upgrade", {}).is_empty() else record.duplicate(true)
	var card: Control = _make_card(shown, str(row.owner), row.state)
	card.scale = Vector2.ONE * CARD_SCALE
	slot.add_child(card)
	var hit := click_area(slot, Rect2(Vector2.ZERO, slot.custom_minimum_size), 12)
	hit.name = "Card_" + str(record.id)
	hit.pressed.connect(_open_detail.bind(row))
	if row.state == "found":
		hit.tooltip_text = "%s\n%s" % [shown.name, Data.effect_text(shown)]
	elif row.state == "hidden":
		hit.tooltip_text = "미발견\n아직 이 카드를 발견하지 못했습니다."
	else:
		hit.tooltip_text = "잠김\n이 카드는 스토리에서 해금해야 앞으로의 원정에 등장합니다.\n" + CodexData.unlock_hint(record)
	return slot

func _make_card(record: Dictionary, owner: String, state: String) -> Control:
	return card_view(record, owner, state)

func _open_detail(row: Dictionary) -> void:
	var record: Dictionary = row.record
	var inner := open_popup(Vector2(900, 560))
	var big: Control = _make_card(record, str(row.owner), row.state)
	big.scale = Vector2.ONE * 1.3
	big.position = Vector2(34, 36)
	inner.add_child(big)
	var x := 360.0
	if row.state == "found":
		make_label(inner, str(record.name), Rect2(x, 28, 500, 50), 36, GOLD, true, HORIZONTAL_ALIGNMENT_LEFT)
		make_label(inner, "%s · %s · %s" % [CodexData.owner_name(str(row.owner)) if row.owner != "common" else "공용", record.rarity, record.type], Rect2(x, 80, 500, 30), 20, MUTED, false, HORIZONTAL_ALIGNMENT_LEFT)
		make_label(inner, "비용 %s" % (str(record.cost) if str(record.get("cost", 0)) == "X" else str(int(record.get("cost", 0)))), Rect2(x, 112, 500, 30), 20, PARCHMENT, false, HORIZONTAL_ALIGNMENT_LEFT)
		make_label(inner, Data.effect_text(record), Rect2(x, 156, 500, 120), 24, PARCHMENT, false, HORIZONTAL_ALIGNMENT_LEFT)
		if not record.get("upgrade", {}).is_empty():
			make_label(inner, "강화", Rect2(x, 294, 500, 30), 20, GOLD, true, HORIZONTAL_ALIGNMENT_LEFT)
			make_label(inner, Data.effect_text(Data.upgraded(record)), Rect2(x, 328, 500, 110), 22, PARCHMENT, false, HORIZONTAL_ALIGNMENT_LEFT)
	elif row.state == "hidden":
		make_label(inner, "미지", Rect2(x, 28, 500, 50), 36, GOLD, true, HORIZONTAL_ALIGNMENT_LEFT)
		make_label(inner, "아직 이 카드를 발견하지 못했습니다.\n원정 중에 만나면 이곳에 기록됩니다.", Rect2(x, 120, 500, 120), 24, PARCHMENT, false, HORIZONTAL_ALIGNMENT_LEFT)
	else:
		make_label(inner, "잠김", Rect2(x, 28, 500, 50), 36, GOLD, true, HORIZONTAL_ALIGNMENT_LEFT)
		make_label(inner, "이 카드는 스토리에서 해금해야 앞으로의 원정에 등장합니다.\n" + CodexData.unlock_hint(record), Rect2(x, 120, 500, 200), 24, PARCHMENT, false, HORIZONTAL_ALIGNMENT_LEFT)
	var done := Button.new()
	done.text = "닫기"
	done.position = Vector2(700, 490)
	done.size = Vector2(160, 48)
	done.add_theme_font_size_override("font_size", 22)
	done.add_theme_font_override("font", UiFont.serif())
	done.pressed.connect(close_popup)
	inner.add_child(done)
	done.grab_focus()

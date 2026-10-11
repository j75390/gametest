extends "res://scripts/codex_screen.gd"
## Story = the chronicle. Entries sit on a horizontal time axis in their era columns. Open ones show
## their picture; visible-but-locked ones are dimmed with a hint; the rest are only an empty outline.
## Clicking an entry opens its situation, goal, story and what it unlocked.
const Timeline = preload("res://scripts/timeline.gd")
const LockIcon = preload("res://scripts/codex_lock_icon.gd")
const CodexData = preload("res://scripts/codex_data.gd")
const CARD := Vector2(224, 128)
const COLUMN_W := 262.0
const ROW_H := 140.0
const LEFT := 40.0
const ERA_COLORS := {
	"가려진 역사": Color("b9955a"), "원정": Color("c26a5a"), "미라": Color("a47bd6"), "칼리안": Color("d86a5a"),
	"세라": Color("6a9bd6"), "루시안": Color("d8c25a"), "이야기들": Color("7ac2a6"), "그 이후": Color("9aa0aa")}

var state: Dictionary
var new_ids: Array = []
var scroll: ScrollContainer
var strip: Control
var points_label: Label
var cards := {}

func build() -> void:
	state = Timeline.load_state()
	new_ids = state.new_entries.duplicate()
	make_label(canvas, "스토리", Rect2(0, 22, 1440, 56), 44, GOLD, true)
	make_label(canvas, "사건을 해결하면 이야기와 새 기록이 열립니다.", Rect2(0, 76, 1440, 30), 20, MUTED)
	points_label = make_label(canvas, "연대표 점수  %d" % int(state.points), Rect2(1020, 28, 380, 40), 26, GOLD, true, HORIZONTAL_ALIGNMENT_RIGHT)
	scroll = ScrollContainer.new()
	scroll.name = "TimelineScroll"
	scroll.position = Vector2(0, 110)
	scroll.size = Vector2(1440, 690)
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	canvas.add_child(scroll)
	var columns := 0
	for item in Timeline.entries(): columns = maxi(columns, int(item.column) + 1)
	strip = Control.new()
	strip.custom_minimum_size = Vector2(LEFT * 2 + columns * COLUMN_W, 680)
	scroll.add_child(strip)
	scroll.gui_input.connect(_wheel)
	_build_axis(columns)
	for item in Timeline.entries(): _entry_card(item)
	# The "new" markers are shown once, then cleared.
	Timeline.clear_new()

func _wheel(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN: scroll.scroll_horizontal += 160
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP: scroll.scroll_horizontal -= 160

func _column_x(column: int) -> float:
	return LEFT + column * COLUMN_W

## Four stacked rows plus the axis and era band fit the 690px strip without vertical scrolling.
func _axis_local_y() -> float:
	return 590.0

func _build_axis(columns: int) -> void:
	var line := ColorRect.new()
	line.color = Color("a98a4a")
	line.position = Vector2(LEFT - 20, _axis_local_y())
	line.size = Vector2(columns * COLUMN_W + 40, 3)
	strip.add_child(line)
	# era bands under the axis
	var eras: Dictionary = {}
	for item in Timeline.entries():
		var era: String = item.epoch
		var col := int(item.column)
		if not eras.has(era): eras[era] = [col, col]
		eras[era][0] = mini(eras[era][0], col)
		eras[era][1] = maxi(eras[era][1], col)
	for col in range(columns):
		var diamond := ColorRect.new()
		diamond.color = Color("d8b47a")
		diamond.size = Vector2(14, 14)
		diamond.pivot_offset = Vector2(7, 7)
		diamond.rotation = PI / 4
		diamond.position = Vector2(_column_x(col) + CARD.x * 0.5 - 7, _axis_local_y() - 5)
		strip.add_child(diamond)
	for era in eras:
		var span: Array = eras[era]
		var x0 := _column_x(span[0]) + 6
		var width: float = (span[1] - span[0] + 1) * COLUMN_W - 40
		var band := ColorRect.new()
		band.color = Color(ERA_COLORS.get(era, Color("9aa0aa")), 0.85)
		band.position = Vector2(x0, _axis_local_y() + 22)
		band.size = Vector2(width, 5)
		strip.add_child(band)
		make_label(strip, era, Rect2(x0, _axis_local_y() + 30, width, 34), 22, ERA_COLORS.get(era, PARCHMENT), true)

func _entry_card(item: Dictionary) -> void:
	var is_open: bool = state.unlocked.has(item.id)
	var is_visible: bool = is_open or state.visible.has(item.id)
	var at := Vector2(_column_x(int(item.column)), _axis_local_y() - 12 - int(item.row) * ROW_H - CARD.y)
	var panel := make_panel(strip, Rect2(at, CARD), Color("0f0b14"), Color("3a3342"), 8)
	panel.name = "Entry_" + str(item.id)
	cards[item.id] = panel
	if not is_visible:
		make_label(panel, "?", Rect2(0, 0, CARD.x, CARD.y), 44, Color("3a3342"), true)
		return
	var pic := make_texture(panel, str(item.art), Rect2(4, 4, CARD.x - 8, CARD.y - 8))
	if not is_open:
		pic.modulate = Color(0.28, 0.26, 0.34)
		var lock := LockIcon.new()
		lock.size = Vector2(46, 46)
		lock.position = Vector2(CARD.x - 54, 8)
		panel.add_child(lock)
	var edge: Color = ERA_COLORS.get(item.epoch, GOLD) if is_open else Color("4b4357")
	panel.add_theme_stylebox_override("panel", box(Color("0f0b14"), edge, 2, 8))
	var strip_bg := ColorRect.new()
	strip_bg.color = Color(0.03, 0.02, 0.05, 0.78)
	strip_bg.position = Vector2(4, CARD.y - 36)
	strip_bg.size = Vector2(CARD.x - 8, 32)
	strip_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(strip_bg)
	make_label(panel, str(item.title) if is_open else "???", Rect2(8, CARD.y - 36, CARD.x - 16, 32), 17, PARCHMENT if is_open else MUTED, true)
	if new_ids.has(item.id):
		var tag := make_panel(panel, Rect2(8, 8, 58, 26), Color("c9a24a"), Color("fff0b8"), 6)
		make_label(tag, "새 기록", Rect2(0, 0, 58, 26), 15, Color("1b0f0f"), true)
	var hit := click_area(panel, Rect2(Vector2.ZERO, CARD), 8)
	hit.name = "Open_" + str(item.id)
	hit.tooltip_text = _tooltip(item, is_open)
	hit.pressed.connect(_open_detail.bind(item))

func _tooltip(item: Dictionary, is_open: bool) -> String:
	if is_open: return "%s\n%s" % [item.title, item.goal]
	return "%s\n%s" % [item.situation, Timeline.hint(item)]

func _open_detail(item: Dictionary) -> void:
	var is_open: bool = state.unlocked.has(item.id)
	var inner := open_popup(Vector2(1040, 600))
	var art_panel := make_panel(inner, Rect2(30, 30, 420, 300), Color("0b080f"), Color("c9a86a"), 6)
	var pic := make_texture(art_panel, str(item.art), Rect2(4, 4, 412, 292))
	if not is_open:
		pic.modulate = Color(0.28, 0.26, 0.34)
		var lock := LockIcon.new()
		lock.size = Vector2(90, 90)
		lock.position = Vector2(165, 105)
		art_panel.add_child(lock)
	var x := 480.0
	make_label(inner, str(item.title) if is_open else "???", Rect2(x, 24, 530, 56), 40, GOLD, true, HORIZONTAL_ALIGNMENT_LEFT)
	make_label(inner, "%s · %s" % [item.epoch, "열림" if is_open else "잠김"], Rect2(x, 80, 530, 28), 20, ERA_COLORS.get(item.epoch, MUTED), false, HORIZONTAL_ALIGNMENT_LEFT)
	make_label(inner, "상황", Rect2(x, 120, 120, 28), 20, GOLD, true, HORIZONTAL_ALIGNMENT_LEFT)
	make_label(inner, str(item.situation), Rect2(x, 150, 530, 70), 23, PARCHMENT, false, HORIZONTAL_ALIGNMENT_LEFT)
	make_label(inner, "해결 조건", Rect2(x, 230, 160, 28), 20, GOLD, true, HORIZONTAL_ALIGNMENT_LEFT)
	make_label(inner, str(item.goal) if is_open else Timeline.hint(item), Rect2(x, 260, 530, 64), 22, PARCHMENT if is_open else MUTED, false, HORIZONTAL_ALIGNMENT_LEFT)
	var y := 346.0
	if is_open:
		var rule := ColorRect.new()
		rule.color = Color("5b4a3a")
		rule.position = Vector2(30, 340)
		rule.size = Vector2(980, 2)
		inner.add_child(rule)
		make_label(inner, str(item.story), Rect2(30, 352, 980, 120), 23, PARCHMENT, false, HORIZONTAL_ALIGNMENT_LEFT)
		y = 482.0
		var unlocks: Array = item.get("unlocks", [])
		var line := "해금: 이야기" if unlocks.is_empty() else "해금: " + ", ".join(unlocks.map(func(u): return str(u.get("name", u.get("id", "")))))
		make_label(inner, line, Rect2(30, y, 980, 32), 21, GOLD, true, HORIZONTAL_ALIGNMENT_LEFT)
	else:
		make_label(inner, "이 사건을 해결하면 이야기와 새 기록이 열립니다.", Rect2(30, 380, 980, 40), 22, MUTED, false, HORIZONTAL_ALIGNMENT_LEFT)
	var clues: Array = item.get("clues", [])
	if not clues.is_empty():
		var got := 0
		var titles: Array = []
		for flag in clues:
			if state.flags_seen.has(flag) or story_flags.has(flag): got += 1
			titles.append(CodexData.clue_title(str(flag), story_flags))
		make_label(inner, "조사 단서  %d / %d  ·  %s" % [got, clues.size(), "  /  ".join(titles)], Rect2(30, 520, 820, 56), 19, MUTED, false, HORIZONTAL_ALIGNMENT_LEFT)
	var done := Button.new()
	done.text = "닫기"
	done.position = Vector2(870, 530)
	done.size = Vector2(140, 46)
	done.add_theme_font_size_override("font_size", 22)
	done.add_theme_font_override("font", UiFont.serif())
	done.pressed.connect(close_popup)
	inner.add_child(done)
	done.grab_focus()

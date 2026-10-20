extends "res://scripts/codex_screen.gd"
## Relic vault and potion lab: framed tiles grouped by rarity, tooltip on hover, a card-style detail on click.
## `kind` is set by the hub before the screen enters the tree ("유물" or "포션").
const CodexData = preload("res://scripts/codex_data.gd")
const Data = preload("res://scripts/game_data.gd")
const LockIcon = preload("res://scripts/codex_lock_icon.gd")
const TILE := Vector2(132, 176)
const SECTION_TEXT := {
	"유물": {
		"시작": "각 인물이 원정을 시작할 때 지니고 있는 유물입니다.",
		"일반": "원정에서 가장 자주 발견되는 유물입니다.",
		"고급": "일반 유물보다 드물게 나타나는 강력한 유물입니다.",
		"희귀": "아주 드물게 만나는 희귀한 유물입니다.",
		"영웅": "큰 힘과 함께 대가를 요구하는 유물입니다.",
		"전설": "세계의 비밀과 이어진 유물입니다.",
		"고대": "특정 인물의 개인 사건에서만 얻는 고대 유물입니다."},
	"포션": {
		"일반": "원정 중 가장 자주 발견되는 포션입니다.",
		"고급": "일반 포션보다 드물게 나타나는 강력한 포션입니다.",
		"희귀": "아주 드물게 만나는 희귀한 포션입니다."}}
const UNKNOWN_ICON := {"유물": "res://assets/ui/selection/codex_unknown_relic.svg", "포션": "res://assets/ui/selection/codex_unknown_potion.svg"}

var kind := "유물"
var blur_material := ShaderMaterial.new()
var rows: Array = []
var scroll: ScrollContainer
var count_label: Label

func build() -> void:
	rows = CodexData.collectibles(kind)
	var blur_shader := Shader.new()
	blur_shader.code = HIDDEN_BLUR
	blur_material.shader = blur_shader
	var title := "유물 보관함" if kind == "유물" else "포션 연구실"
	make_label(canvas, title, Rect2(0, 22, 1440, 54), 40, GOLD, true)
	scroll = ScrollContainer.new()
	scroll.name = "CollectionScroll"
	scroll.position = Vector2(60, 90)
	scroll.size = Vector2(1320, 700)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	canvas.add_child(scroll)
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 1300
	column.add_theme_constant_override("separation", 14)
	scroll.add_child(column)
	var found := 0
	for section in CodexData.RARITY_ORDER:
		var members: Array = rows.filter(func(row): return row.section == section)
		if members.is_empty(): continue
		var head := RichTextLabel.new()
		head.bbcode_enabled = true
		head.fit_content = true
		head.scroll_active = false
		head.custom_minimum_size = Vector2(1280, 34)
		head.add_theme_font_size_override("normal_font_size", 22)
		head.add_theme_font_override("normal_font", UiFont.serif(false))
		head.add_theme_color_override("default_color", PARCHMENT)
		head.text = "[color=#%s][b]%s[/b][/color]  %s" % [GOLD.to_html(false), section, SECTION_TEXT[kind].get(section, "")]
		column.add_child(head)
		var grid := GridContainer.new()
		grid.columns = 8
		grid.add_theme_constant_override("h_separation", 18)
		grid.add_theme_constant_override("v_separation", 18)
		column.add_child(grid)
		for row in members:
			grid.add_child(_tile(row, TILE, 1.0))
			if row.state == "found": found += 1
		var gap := Control.new()
		gap.custom_minimum_size.y = 8
		column.add_child(gap)
	count_label = make_label(canvas, "발견 %d / %d" % [found, rows.size()], Rect2(1100, 806, 306, 46), 26, GOLD, true, HORIZONTAL_ALIGNMENT_RIGHT)

func _rarity_color(row: Dictionary) -> Color:
	return CodexData.RARITY_COLORS.get(row.section, Color("b9b3a5"))

func _icon_path(row: Dictionary) -> String:
	var path := str(row.record.get("art", ""))
	if path.is_empty() or not ResourceLoader.exists(path): return UNKNOWN_ICON[kind]
	return path

func _tile(row: Dictionary, tile_size: Vector2, factor: float) -> Control:
	var slot := Control.new()
	slot.custom_minimum_size = tile_size
	var state: String = row.state
	var accent := _rarity_color(row)
	var edge := accent if state == "found" else (Color("8d7bb0") if state == "hidden" else Color("5b6a73"))
	var panel := make_panel(slot, Rect2(Vector2.ZERO, tile_size), Color("1b1522"), edge, int(10 * factor))
	var ribbon := make_panel(panel, Rect2(6 * factor, 6 * factor, tile_size.x - 12 * factor, 30 * factor), Color("2a2030"), Color("5b4a3a"), int(6 * factor))
	var shown_name := str(row.record.name) if state != "hidden" else "미지"
	var name_label := make_label(ribbon, shown_name, Rect2(2, 0, ribbon.size.x - 4, ribbon.size.y), int(15 * factor), PARCHMENT if state == "found" else MUTED, true)
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_label.clip_text = true
	var window := make_panel(panel, Rect2(16 * factor, 44 * factor, tile_size.x - 32 * factor, tile_size.x - 32 * factor), Color("0b080f"), Color("3a3342"), int(6 * factor))
	var icon := make_texture(window, _icon_path(row), Rect2(6, 6, window.size.x - 12, window.size.y - 12), TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	if state == "hidden":
		icon.material = blur_material
		icon.modulate = Color(0.34, 0.3, 0.42)
	elif state == "locked":
		icon.modulate = Color(0.12, 0.14, 0.17)
		var lock := LockIcon.new()
		lock.size = window.size * 0.7
		lock.position = window.size * 0.15
		window.add_child(lock)
	var gem := Panel.new()
	gem.add_theme_stylebox_override("panel", box(accent if state == "found" else Color("3a3342"), Color("0b080f"), 2, int(9 * factor)))
	gem.size = Vector2(18, 18) * factor
	gem.position = Vector2((tile_size.x - gem.size.x) * 0.5, tile_size.y - 24 * factor)
	panel.add_child(gem)
	var hit := click_area(slot, Rect2(Vector2.ZERO, tile_size), int(10 * factor))
	hit.name = "Tile_" + str(row.record.id)
	hit.tooltip_text = _tooltip(row)
	hit.pressed.connect(_open_detail.bind(row))
	return slot

func _effect_text(record: Dictionary) -> String:
	return Data.effect_text(record) if kind == "포션" else Data.relic_text(record)

func _tooltip(row: Dictionary) -> String:
	var record: Dictionary = row.record
	match row.state:
		"found":
			var text := "%s\n%s" % [record.name, _effect_text(record)]
			if not str(record.get("flavor_text", "")).is_empty(): text += "\n\n" + str(record.flavor_text)
			return text
		"hidden":
			return "미발견\n아직 이 %s을(를) 발견하지 못했습니다." % kind
		_:
			return "잠김\n이 %s은(는) 스토리에서 해금해야 앞으로의 원정에 등장합니다.\n%s" % [kind, CodexData.unlock_hint(record)]

func _open_detail(row: Dictionary) -> void:
	var record: Dictionary = row.record
	var inner := open_popup(Vector2(860, 480))
	var big := _tile(row, TILE * 1.7, 1.7)
	big.position = Vector2(40, 40)
	inner.add_child(big)
	var x := 330.0
	match row.state:
		"found":
			make_label(inner, str(record.name), Rect2(x, 30, 500, 50), 36, GOLD, true, HORIZONTAL_ALIGNMENT_LEFT)
			make_label(inner, "%s · %s" % [row.section, kind], Rect2(x, 82, 500, 30), 20, _rarity_color(row), false, HORIZONTAL_ALIGNMENT_LEFT)
			make_label(inner, _effect_text(record), Rect2(x, 130, 500, 100), 24, PARCHMENT, false, HORIZONTAL_ALIGNMENT_LEFT)
			if not str(record.get("flavor_text", "")).is_empty():
				var rule := ColorRect.new()
				rule.color = Color("5b4a3a")
				rule.position = Vector2(x, 250)
				rule.size = Vector2(500, 2)
				inner.add_child(rule)
				make_label(inner, str(record.flavor_text), Rect2(x, 262, 500, 150), 21, MUTED, false, HORIZONTAL_ALIGNMENT_LEFT)
		"hidden":
			make_label(inner, "미지", Rect2(x, 30, 500, 50), 36, GOLD, true, HORIZONTAL_ALIGNMENT_LEFT)
			make_label(inner, "아직 이 %s을(를) 발견하지 못했습니다.\n원정 중에 만나면 이곳에 기록됩니다." % kind, Rect2(x, 130, 500, 120), 24, PARCHMENT, false, HORIZONTAL_ALIGNMENT_LEFT)
		_:
			make_label(inner, "잠김", Rect2(x, 30, 500, 50), 36, GOLD, true, HORIZONTAL_ALIGNMENT_LEFT)
			make_label(inner, "이 %s은(는) 스토리에서 해금해야 앞으로의 원정에 등장합니다." % kind, Rect2(x, 130, 500, 120), 24, PARCHMENT, false, HORIZONTAL_ALIGNMENT_LEFT)
	var done := Button.new()
	done.text = "닫기"
	done.position = Vector2(660, 410)
	done.size = Vector2(160, 48)
	done.add_theme_font_size_override("font_size", 22)
	done.add_theme_font_override("font", UiFont.serif())
	done.pressed.connect(close_popup)
	inner.add_child(done)
	done.grab_focus()

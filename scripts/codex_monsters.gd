extends "res://scripts/codex_screen.gd"
## Monster codex: one monster at a time. Name on top, picture in the middle, its moves on the left
## and the list grouped by act on the right. Unmet monsters stay a silhouette with a red notice.
const CodexData = preload("res://scripts/codex_data.gd")
const Data = preload("res://scripts/game_data.gd")

var rows: Array = []
var selected := 0
var name_label: Label
var sub_label: Label
var picture: TextureRect
var notice: Label
var move_box: VBoxContainer
var list_box: VBoxContainer
var list_buttons: Array[Button] = []

func build() -> void:
	rows = CodexData.monsters()
	name_label = make_label(canvas, "", Rect2(360, 40, 720, 70), 52, GOLD, true)
	sub_label = make_label(canvas, "", Rect2(360, 108, 720, 34), 22, MUTED)
	picture = make_texture(canvas, "", Rect2(430, 170, 580, 520), TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	picture.name = "MonsterPicture"
	notice = make_label(canvas, "이 몬스터에 관한 정보는 아직 드러나지 않았습니다…", Rect2(260, 720, 920, 50), 28, Color("e0584f"))
	make_label(canvas, "행동", Rect2(70, 250, 200, 40), 28, GOLD, true, HORIZONTAL_ALIGNMENT_LEFT)
	move_box = VBoxContainer.new()
	move_box.position = Vector2(70, 300)
	move_box.size = Vector2(330, 360)
	move_box.add_theme_constant_override("separation", 8)
	canvas.add_child(move_box)
	var list_scroll := ScrollContainer.new()
	list_scroll.name = "MonsterList"
	list_scroll.position = Vector2(1090, 150)
	list_scroll.size = Vector2(320, 640)
	list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	canvas.add_child(list_scroll)
	list_box = VBoxContainer.new()
	list_box.custom_minimum_size.x = 300
	list_box.add_theme_constant_override("separation", 4)
	list_scroll.add_child(list_box)
	_build_list()
	_select(0)

func _act_title(act: int) -> String:
	for region in Data.read("regions"):
		if int(region.get("act", 0)) == act: return "ACT %d · %s" % [act, region.name]
	return "ACT %d" % act

func _build_list() -> void:
	var acts: Array = []
	for row in rows:
		var act := int(row.record.get("act", 1))
		if not acts.has(act): acts.append(act)
	acts.sort()
	for act in acts:
		var head := make_label(list_box, _act_title(act), Rect2(0, 0, 300, 36), 22, Color("8fc6e8"), true, HORIZONTAL_ALIGNMENT_LEFT)
		head.custom_minimum_size = Vector2(300, 36)
		for i in range(rows.size()):
			if int(rows[i].record.get("act", 1)) != act: continue
			var button := Button.new()
			button.name = "Monster_" + str(rows[i].record.id)
			button.flat = true
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.custom_minimum_size = Vector2(300, 34)
			button.text = ("   " + str(rows[i].record.name)) if rows[i].state == "found" else "   미지"
			button.add_theme_font_size_override("font_size", 21)
			button.add_theme_font_override("font", UiFont.serif(false))
			button.add_theme_color_override("font_color", PARCHMENT if rows[i].state == "found" else MUTED)
			button.add_theme_color_override("font_hover_color", GOLD)
			button.pressed.connect(_select.bind(i))
			list_box.add_child(button)
			list_buttons.append(button)

func _select(index: int) -> void:
	selected = clampi(index, 0, maxi(0, rows.size() - 1))
	for child in move_box.get_children():
		move_box.remove_child(child)
		child.queue_free()
	if rows.is_empty():
		name_label.text = ""
		return
	var row: Dictionary = rows[selected]
	var record: Dictionary = row.record
	var path := str(record.get("art", record.get("image", "")))
	picture.texture = load(path) if not path.is_empty() and ResourceLoader.exists(path) else null
	var found: bool = row.state == "found"
	picture.modulate = Color.WHITE if found else Color(0.04, 0.04, 0.06)
	notice.visible = not found
	name_label.text = str(record.name) if found else "미지"
	sub_label.text = "%s · HP %d" % [record.get("type", ""), int(record.get("hp", 0))] if found else ""
	for i in range(list_buttons.size()):
		var marked: bool = list_buttons[i].name == "Monster_" + str(record.id)
		list_buttons[i].text = ("▶ " if marked else "   ") + (str(rows[_row_of(list_buttons[i])].record.name) if rows[_row_of(list_buttons[i])].state == "found" else "미지")
	if found:
		for action in record.get("pattern", []):
			var item := Label.new()
			item.text = "%s  ·  %s" % [action.name, preload("res://scripts/monster_actions.gd").text(action)]
			item.add_theme_font_size_override("font_size", 22)
			item.add_theme_font_override("font", UiFont.serif(false))
			item.add_theme_color_override("font_color", PARCHMENT)
			move_box.add_child(item)

func _row_of(button: Button) -> int:
	var id := button.name.trim_prefix("Monster_")
	for i in range(rows.size()):
		if str(rows[i].record.id) == id: return i
	return 0

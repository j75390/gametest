extends "res://scripts/codex_screen.gd"
## Investigation notes: three shelves (clues, stories, regions). A list grouped by act on the left,
## a reading page on the right. Records appear only once their flag/relic is known, from this run
## or from the permanent story progress.
const CodexData = preload("res://scripts/codex_data.gd")
const TABS := ["조사 기록", "이야기", "지역"]

var data: Dictionary = {}
var tab := "조사 기록"
var selected := ""
var tab_buttons := {}
var list_box: VBoxContainer
var list_scroll: ScrollContainer
var reader_box: VBoxContainer
var reader_scroll: ScrollContainer
var count_label: Label
var first_id := {}

func build() -> void:
	data = CodexData.notes(story_flags)
	make_label(canvas, "조사 기록", Rect2(0, 22, 1440, 56), 44, GOLD, true)
	for tab_name in TABS:
		var button := Button.new()
		button.name = "Tab_" + tab_name
		button.toggle_mode = true
		button.text = tab_name
		button.position = Vector2(40 + TABS.find(tab_name) * 134, 100)
		button.size = Vector2(124, 40)
		button.add_theme_font_size_override("font_size", 20)
		button.add_theme_font_override("font", UiFont.serif())
		button.add_theme_color_override("font_color", MUTED)
		button.add_theme_color_override("font_pressed_color", PARCHMENT)
		button.add_theme_stylebox_override("normal", box(Color("17141d"), Color("3a3342"), 2, 6))
		button.add_theme_stylebox_override("hover", box(Color("231c2c"), Color("8d7bb0"), 2, 6))
		button.add_theme_stylebox_override("pressed", box(Color("3a2b4d"), GOLD, 2, 6))
		button.add_theme_stylebox_override("focus", box(Color("231c2c"), GOLD, 2, 6))
		button.pressed.connect(open_tab.bind(tab_name))
		canvas.add_child(button)
		tab_buttons[tab_name] = button
	var list_panel := make_panel(canvas, Rect2(40, 156, 400, 640), Color(0.07, 0.06, 0.1, 0.94), EDGE, 12)
	list_scroll = ScrollContainer.new()
	list_scroll.name = "NoteList"
	list_scroll.position = Vector2(8, 10)
	list_scroll.size = Vector2(384, 620)
	list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	list_panel.add_child(list_scroll)
	list_box = VBoxContainer.new()
	list_box.custom_minimum_size.x = 364
	list_box.add_theme_constant_override("separation", 2)
	list_scroll.add_child(list_box)
	var reader_panel := make_panel(canvas, Rect2(466, 156, 934, 640), Color(0.09, 0.07, 0.12, 0.94), EDGE, 12)
	reader_scroll = ScrollContainer.new()
	reader_scroll.name = "NoteReader"
	reader_scroll.position = Vector2(12, 12)
	reader_scroll.size = Vector2(910, 616)
	reader_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	reader_panel.add_child(reader_scroll)
	reader_box = VBoxContainer.new()
	reader_box.custom_minimum_size.x = 880
	reader_box.add_theme_constant_override("separation", 12)
	reader_scroll.add_child(reader_box)
	count_label = make_label(canvas, "", Rect2(1000, 806, 400, 46), 24, GOLD, true, HORIZONTAL_ALIGNMENT_RIGHT)
	open_tab(tab)

func open_tab(tab_name: String) -> void:
	if not data.has(tab_name) or not TABS.has(tab_name): return
	tab = tab_name
	for key in tab_buttons: tab_buttons[key].set_pressed_no_signal(key == tab_name)
	for child in list_box.get_children():
		list_box.remove_child(child)
		child.queue_free()
	var records: Array = data[tab_name]
	var found: int = records.size()
	count_label.text = "찾은 기록  %d / %d" % [found, data.total[tab_name]]
	var last_group := ""
	first_id[tab_name] = ""
	for record in records:
		var group := CodexData.act_title(int(record.act)) if int(record.act) > 0 else ""
		if group != last_group and not group.is_empty():
			var head := Label.new()
			head.text = group
			head.add_theme_font_size_override("font_size", 20)
			head.add_theme_font_override("font", UiFont.serif())
			head.add_theme_color_override("font_color", Color("8fc6e8"))
			head.custom_minimum_size.y = 36
			list_box.add_child(head)
			last_group = group
		var button := Button.new()
		button.name = "Note_" + str(record.id)
		button.flat = true
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = "   " + str(record.name)
		button.custom_minimum_size = Vector2(364, 34)
		button.clip_text = true
		button.add_theme_font_size_override("font_size", 19)
		button.add_theme_font_override("font", UiFont.serif(false))
		button.add_theme_color_override("font_color", PARCHMENT)
		button.add_theme_color_override("font_hover_color", GOLD)
		button.pressed.connect(select_record.bind(str(record.id)))
		list_box.add_child(button)
		if first_id[tab_name].is_empty(): first_id[tab_name] = str(record.id)
	if records.is_empty():
		var empty := Label.new()
		empty.text = "아직 이 분류의 기록이 없습니다.\n원정에서 단서를 모으면 이곳에 쌓입니다."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.custom_minimum_size = Vector2(364, 90)
		empty.add_theme_font_size_override("font_size", 19)
		empty.add_theme_color_override("font_color", MUTED)
		list_box.add_child(empty)
	select_record(first_id[tab_name])

func select_record(id: String) -> void:
	selected = id
	for button in list_box.get_children():
		if button is Button:
			var marked: bool = button.name == "Note_" + id
			button.text = ("▶ " if marked else "   ") + button.text.strip_edges().trim_prefix("▶ ")
	for child in reader_box.get_children():
		reader_box.remove_child(child)
		child.queue_free()
	reader_scroll.scroll_vertical = 0
	var record: Dictionary = {}
	for item in data[tab]:
		if str(item.id) == id: record = item
	if record.is_empty():
		_reader_text("기록을 고르면 이곳에서 읽을 수 있습니다.", 22, MUTED)
		return
	_reader_text(str(record.name), 38, GOLD, true)
	if not str(record.subtitle).is_empty(): _reader_text(str(record.subtitle), 20, MUTED)
	var art_path := str(record.art)
	if not art_path.is_empty() and ResourceLoader.exists(art_path):
		var texture := load(art_path) as Texture2D
		if texture == null or texture.get_height() == 0:
			_reader_text(str(record.description), 24, PARCHMENT)
			return
		var holder := AspectRatioContainer.new()
		holder.ratio = float(texture.get_width()) / float(texture.get_height())
		holder.custom_minimum_size = Vector2(0, 340)
		holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		reader_box.add_child(holder)
		var picture := TextureRect.new()
		picture.texture = texture
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		holder.add_child(picture)
		if record.get("map", false):
			picture.mouse_filter = Control.MOUSE_FILTER_STOP
			picture.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			picture.gui_input.connect(func(event):
				if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
					_open_map(texture))
			_reader_text("그림을 누르면 크게 볼 수 있습니다.", 17, MUTED)
	var rule := ColorRect.new()
	rule.color = Color("5b4a3a")
	rule.custom_minimum_size = Vector2(880, 2)
	reader_box.add_child(rule)
	_reader_text(str(record.description), 24, PARCHMENT)

func _reader_text(value: String, font_size: int, tint: Color, bold: bool = false) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(880, 0)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_font_override("font", UiFont.serif(bold))
	label.add_theme_color_override("font_color", tint)
	label.add_theme_constant_override("line_spacing", 8)
	reader_box.add_child(label)
	return label

func _open_map(texture: Texture2D) -> void:
	var inner := open_popup(Vector2(1240, 800))
	var picture := TextureRect.new()
	picture.texture = texture
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.position = Vector2(20, 20)
	picture.size = Vector2(1200, 700)
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	inner.add_child(picture)
	var done := Button.new()
	done.text = "닫기"
	done.position = Vector2(1060, 736)
	done.size = Vector2(160, 48)
	done.add_theme_font_size_override("font_size", 22)
	done.add_theme_font_override("font", UiFont.serif())
	done.pressed.connect(close_popup)
	inner.add_child(done)
	done.grab_focus()

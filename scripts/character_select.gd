extends Control
signal character_chosen(character: Dictionary)
signal back_requested
signal codex_requested
const Assets = preload("res://scripts/character_assets.gd")
const Data = preload("res://scripts/game_data.gd")
var roster: Array = []
var selected_index := 0
var canvas := Control.new()
var portrait := TextureRect.new()
var heading: Label
var information := Label.new()
var slot: Label
var asset_status: Label
var selectors: Array[Button] = []
var detail_popup := AcceptDialog.new()

func setup(characters: Array) -> void:
	roster = characters

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var surround := ColorRect.new()
	surround.color = Color("09070e")
	surround.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	surround.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(surround)
	add_child(canvas)
	canvas.size = Vector2(1440,900)
	var background := TextureRect.new()
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.texture = load("res://assets/backgrounds/selection_cathedral_v1.png")
	background.position = Vector2(0,-36)
	background.size = Vector2(1440,972)
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.modulate = Color(0.38,0.32,0.43)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(background)
	text("운빨 원정대", Vector2(40,25),Vector2(400,46),30,Color("e2c28b"))
	text("원정대원 선택",Vector2(1100,35),Vector2(290,36),20,Color("c7b3cf"))
	panel(Vector2(32,100),Vector2(226,684))
	text("원정대원",Vector2(52,116),Vector2(180,30),20,Color("d8bb88"))
	for i in range(roster.size()):
		var ch: Dictionary = roster[i]
		var button := action("",Vector2(48,164+i*148),Vector2(194,132))
		button.name = "Character_" + str(ch.id)
		button.tooltip_text = ch.name + " · " + ch.class
		var art := TextureRect.new()
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.texture = Assets.picture(ch.id,"selection")
		art.position = Vector2(8,8)
		art.size = Vector2(74,116)
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(art)
		var caption := Label.new()
		caption.text = ch.name + "\n" + ch.class
		caption.position = Vector2(92,38)
		caption.add_theme_font_size_override("font_size",19)
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(caption)
		button.pressed.connect(_select.bind(i))
		selectors.append(button)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.position = Vector2(276,102)
	portrait.size = Vector2(684,678)
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(portrait)
	asset_status = text("",Vector2(294,749),Vector2(640,32),16,Color("ddc08d"))
	asset_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel(Vector2(986,100),Vector2(422,550))
	heading = text("",Vector2(1010,116),Vector2(372,68),48,Color("f2dfbc"))
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(1010,194)
	scroll.size = Vector2(372,430)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	canvas.add_child(scroll)
	information.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	information.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	information.add_theme_font_size_override("font_size",18)
	information.add_theme_color_override("font_color",Color("d8ccd9"))
	scroll.add_child(information)
	panel(Vector2(986,669),Vector2(422,115))
	text("선택된 원정대원",Vector2(1010,681),Vector2(372,26),17,Color("ad94ba"))
	slot = text("",Vector2(1010,719),Vector2(372,46),26,Color("e6c991"))
	panel(Vector2(0,804),Vector2(1440,96))
	var back := action("← 돌아가기",Vector2(32,823),Vector2(190,54))
	back.name = "Back"
	back.pressed.connect(func(): back_requested.emit())
	var detail := action("상세정보",Vector2(242,823),Vector2(170,54))
	detail.name = "Details"
	detail.pressed.connect(_show_details)
	var codex := action("도감",Vector2(432,823),Vector2(150,54))
	codex.name = "Codex"
	codex.pressed.connect(func(): codex_requested.emit())
	text("난이도 0 · 기본 원정",Vector2(658,835),Vector2(330,34),20,Color("c7ad83"))
	var start := action("원정 시작 →",Vector2(1138,817),Vector2(270,66))
	start.name = "StartExpedition"
	start.pressed.connect(func(): character_chosen.emit(roster[selected_index]))
	detail_popup.title = "원정대원 상세정보"
	detail_popup.min_size = Vector2i(540,380)
	add_child(detail_popup)
	resized.connect(_fit)
	_fit()
	_select(0)

func _fit() -> void:
	var ratio := minf(size.x/1440.0,size.y/900.0)
	canvas.scale = Vector2.ONE * ratio
	canvas.position = (size-Vector2(1440,900)*ratio)*0.5

func box(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	return style

func panel(at: Vector2, dimensions: Vector2) -> void:
	var item := Panel.new()
	item.position = at
	item.size = dimensions
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.add_theme_stylebox_override("panel",box(Color(0.035,0.025,0.05,0.94),Color("69513f")))
	canvas.add_child(item)

func text(value: String, at: Vector2, dimensions: Vector2, font_size: int, color: Color) -> Label:
	var item := Label.new()
	item.text = value
	item.position = at
	item.size = dimensions
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.add_theme_font_size_override("font_size",font_size)
	item.add_theme_color_override("font_color",color)
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(item)
	return item

func action(value: String, at: Vector2, dimensions: Vector2) -> Button:
	var item := Button.new()
	item.text = value
	item.position = at
	item.size = dimensions
	item.add_theme_font_size_override("font_size",22)
	item.add_theme_color_override("font_color",Color("f1e2c9"))
	item.add_theme_stylebox_override("normal",box(Color("211629"),Color("93754d")))
	item.add_theme_stylebox_override("hover",box(Color("462851"),Color("e0bc80")))
	item.add_theme_stylebox_override("pressed",box(Color("100c17"),Color("b59665")))
	canvas.add_child(item)
	return item

func _select(index: int) -> void:
	selected_index = index
	var ch: Dictionary = roster[index]
	var profile: Dictionary = Assets.profile(ch.id)
	var path: String = profile.get("illustration","")
	portrait.texture = load(path) if not path.is_empty() and ResourceLoader.exists(path) else Assets.picture(ch.id,"selection")
	asset_status.text = "선택용 투명 전신 일러스트 준비 중" if profile.get("needs_transparent_art",true) else ""
	heading.text = ch.name
	var starter: Array = Data.cards().get("common",[])
	var starter_names: Array[String] = []
	for card in starter.slice(0,2):
		starter_names.append("%s × 5" % card.name)
	information.text = "%s\n\nHP  %d   /   시작 골드  120\n\n전투 특징\n%s\n\n패시브\n%s\n\n시작 덱\n%s\n\n시작 유물\n%s" % [ch.class,ch.max_hp,ch.theme.replace(" / "," · "),ch.get("passive_description","등록된 패시브 없음")," · ".join(starter_names),ch.get("starting_relic_description","없음")]
	slot.text = "01   %s · %s" % [ch.name,ch.class]
	for i in range(selectors.size()):
		selectors[i].add_theme_stylebox_override("normal",box(Color("382440") if i==index else Color("15101b"),Color("e1b775") if i==index else Color("604953")))

func _show_details() -> void:
	detail_popup.title = roster[selected_index].name + " · 상세정보"
	detail_popup.dialog_text = information.text
	detail_popup.popup_centered(Vector2i(560,540))

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not detail_popup.visible:
		back_requested.emit()
		get_viewport().set_input_as_handled()

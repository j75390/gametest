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
var information: Label
var slot: Label
var asset_status: Label
var selectors: Array[Button] = []
var detail_popup := AcceptDialog.new()
var biography: Label
var relic_name: Label
var relic_effect: Label
var relic_art := TextureRect.new()
const INTRO := {
	"mira": "금지된 연금술을 품고 폐허를 떠도는 주술사. 독으로 적을 쇠약하게 만들고 빼앗은 생명으로 버팁니다.",
	"kalian": "무너진 전선을 홀로 지켜 온 검사. 참격과 출혈을 쌓아 끊임없는 공격으로 적을 몰아붙입니다.",
	"sera": "잊힌 주문을 수집하는 마도사. 마력과 저주를 엮어 강력한 마법을 펼칩니다.",
	"lucian": "꺼져 가는 성화를 지키는 성직자. 회복과 축복으로 버티며 신성한 힘으로 맞섭니다."
}

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
	text("원정대원 선택", Vector2(40,25),Vector2(400,46),30,Color("e2c28b"))
	for i in range(roster.size()):
		var ch: Dictionary = roster[i]
		var button := action("",Vector2(280+i*282,704),Vector2(270,96))
		button.name = "Character_" + str(ch.id)
		button.tooltip_text = ch.name + " · " + ch.class
		var art := TextureRect.new()
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.texture = Assets.picture(ch.id,"selection")
		art.position = Vector2(8,8)
		art.size = Vector2(74,80)
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(art)
		var caption := Label.new()
		caption.text = ch.name + "\n" + ch.class
		caption.position = Vector2(92,18)
		caption.add_theme_font_size_override("font_size",19)
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(caption)
		button.pressed.connect(_select.bind(i))
		selectors.append(button)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.position = Vector2(20,90)
	portrait.size = Vector2(700,604)
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(portrait)
	asset_status = text("",Vector2(40,652),Vector2(640,32),16,Color("ddc08d"))
	asset_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading = text("",Vector2(740,100),Vector2(640,68),48,Color("f2dfbc"))
	slot = text("",Vector2(740,176),Vector2(640,34),22,Color("bca2cd"))
	panel(Vector2(730,234),Vector2(224,440))
	text("시작 스탯",Vector2(750,252),Vector2(180,32),23,Color("d8bb88"))
	information = text("",Vector2(750,306),Vector2(184,340),21,Color("e1d5c3"))
	panel(Vector2(974,234),Vector2(434,440))
	text("전투 방식",Vector2(996,252),Vector2(388,32),23,Color("d8bb88"))
	biography = text("",Vector2(996,300),Vector2(384,144),20,Color("e1d5c3"))
	text("시작 유물",Vector2(996,456),Vector2(380,30),21,Color("d8bb88"))
	relic_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	relic_art.position = Vector2(992,510)
	relic_art.size = Vector2(96,112)
	relic_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	relic_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(relic_art)
	relic_name = text("",Vector2(1096,504),Vector2(284,50),21,Color("e6c991"))
	relic_effect = text("",Vector2(1096,560),Vector2(284,96),18,Color("e1d5c3"))
	panel(Vector2(0,804),Vector2(1440,96))
	var back := action("← 돌아가기",Vector2(32,823),Vector2(190,54))
	back.name = "Back"
	back.pressed.connect(func(): back_requested.emit())
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
	asset_status.text = ""
	heading.text = ch.name
	var starter: Array = Data.cards().get("common",[])
	var starter_names: Array[String] = []
	for card in starter.slice(0,2):
		starter_names.append("%s × 5" % card.name)
	information.text = "HP   %d\n\n골드   120\n\n에너지   3\n\n시작 덱\n%s" % [ch.max_hp,"\n".join(starter_names)]
	biography.text = INTRO.get(ch.id, ch.theme)
	slot.text = ch.class + " · " + ch.theme.replace(" / ", " · ")
	var relic := Data.starting_relic(ch.id)
	relic_art.texture = load(relic.art) if not relic.is_empty() else null
	relic_name.text = relic.name + "\n" + relic.rarity + " · 전용" if not relic.is_empty() else "시작 유물 미등록"
	relic_effect.text = Data.relic_text(relic) if not relic.is_empty() else "이 원정대원의 전용 유물은 아직 준비 중입니다."
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

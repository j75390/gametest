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
var serif := SystemFont.new()
var quote: Label
var selection_frames: Array[TextureRect] = []
const INTRO := {
	"mira": "금지된 연금술을 품고 폐허를 떠도는 주술사. 독으로 적을 쇠약하게 만들고 빼앗은 생명으로 버팁니다.",
	"kalian": "무너진 전선을 홀로 지켜 온 검사. 참격과 출혈을 쌓아 끊임없는 공격으로 적을 몰아붙입니다.",
	"sera": "잊힌 주문을 수집하는 마도사. 마력과 저주를 엮어 강력한 마법을 펼칩니다.",
	"lucian": "꺼져 가는 성화를 지키는 성직자. 회복과 축복으로 버티며 신성한 힘으로 맞섭니다."
}

func setup(characters: Array) -> void:
	roster = characters

func _ready() -> void:
	serif.font_names = PackedStringArray(["Batang", "Noto Serif CJK KR", "serif"])
	serif.font_weight = 700
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
	background.texture = load("res://assets/backgrounds/selection_ruins_v2.png")
	background.position = Vector2(0,-36)
	background.size = Vector2(1440,972)
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.modulate = Color(0.92,0.92,0.96)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(background)
	panel(Vector2(34,730),Vector2(1372,110))
	for i in range(roster.size()):
		var ch: Dictionary = roster[i]
		var button := action("",Vector2(102+i*314,730),Vector2(292,108))
		button.name = "Character_" + str(ch.id)
		button.tooltip_text = ch.name + " · " + ch.class
		var art := TextureRect.new()
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.texture = Assets.picture(ch.id,"map_portrait")
		art.position = Vector2(8,6)
		art.size = Vector2(276,96)
		art.stretch_mode = TextureRect.STRETCH_SCALE
		# Display the face area of the independent portrait; never slice full-body art.
		var face_shader := Shader.new()
		face_shader.code = "shader_type canvas_item; uniform float top = 0.18; void fragment() { COLOR = texture(TEXTURE, vec2(UV.x, top + UV.y * (96.0 / 276.0))); }"
		var face_material := ShaderMaterial.new()
		face_material.shader = face_shader
		face_material.set_shader_parameter("top", 0.30 if ch.id in ["mira", "sera"] else 0.18)
		art.material = face_material
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(art)
		var name_band := ColorRect.new()
		name_band.color = Color(0.015,0.012,0.022,0.90)
		name_band.position = Vector2(8,76)
		name_band.size = Vector2(276,26)
		name_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(name_band)
		var caption := Label.new()
		caption.text = ch.name + " · " + ch.class
		caption.position = Vector2(8,76)
		caption.size = Vector2(276,26)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.add_theme_font_size_override("font_size",18)
		caption.add_theme_font_override("font", serif)
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(caption)
		var border := image_layer("res://assets/ui/selection/ornate_frame_v1.png", Vector2(-8,-7),Vector2(308,122), button)
		selection_frames.append(border)
		button.pressed.connect(_select.bind(i))
		selectors.append(button)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.position = Vector2(-24,-2)
	portrait.size = Vector2(770,732)
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var portrait_stage := Control.new()
	portrait_stage.size = Vector2(708,720)
	portrait_stage.clip_contents = true
	portrait_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(portrait_stage)
	portrait_stage.add_child(portrait)
	asset_status = text("",Vector2(40,652),Vector2(640,32),16,Color("ddc08d"))
	asset_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel(Vector2(708,58),Vector2(700,214))
	heading = text("",Vector2(746,76),Vector2(620,76),62,Color("eedcea"))
	slot = text("",Vector2(749,163),Vector2(610,28),18,Color("bca2cd"))
	quote = text("",Vector2(746,210),Vector2(620,35),21,Color("e6bf84"))
	panel(Vector2(712,302),Vector2(244,388))
	text("원정 준비",Vector2(742,324),Vector2(184,32),24,Color("d8bb88"))
	information = text("",Vector2(744,378),Vector2(184,290),19,Color("e1d5c3"))
	panel(Vector2(974,302),Vector2(434,388))
	text("전투 방식",Vector2(1004,324),Vector2(368,32),24,Color("d8bb88"))
	biography = text("",Vector2(1004,376),Vector2(370,110),19,Color("e1d5c3"))
	text("함께할 유물",Vector2(1004,492),Vector2(368,30),22,Color("d8bb88"))
	relic_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	relic_art.position = Vector2(992,538)
	relic_art.size = Vector2(96,112)
	relic_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	relic_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(relic_art)
	relic_name = text("",Vector2(1096,536),Vector2(276,50),20,Color("e6c991"))
	relic_effect = text("",Vector2(1096,594),Vector2(276,66),17,Color("e1d5c3"))
	var back := action("← 돌아가기",Vector2(32,843),Vector2(190,46))
	back.name = "Back"
	back.pressed.connect(func(): back_requested.emit())
	text("난이도 0 · 기본 원정",Vector2(614,849),Vector2(330,30),18,Color("c7ad83"))
	var start := action("원정 시작 →",Vector2(1138,839),Vector2(270,54))
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
	item.add_theme_stylebox_override("panel",box(Color(0.018,0.025,0.033,0.90),Color("69513f")))
	canvas.add_child(item)
	var frame := NinePatchRect.new()
	frame.texture = load("res://assets/ui/selection/ornate_frame_v1.png")
	frame.position = at - Vector2(20,26)
	frame.size = (dimensions + Vector2(40,52)) * 4
	frame.scale = Vector2.ONE * 0.25
	frame.patch_margin_left = 180
	frame.patch_margin_right = 180
	frame.patch_margin_top = 200
	frame.patch_margin_bottom = 200
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(frame)

func image_layer(path: String, at: Vector2, dimensions: Vector2, parent: Node = null) -> TextureRect:
	var item := TextureRect.new()
	item.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item.texture = load(path)
	item.position = at
	item.size = dimensions
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	(parent if parent != null else canvas).add_child(item)
	return item

func text(value: String, at: Vector2, dimensions: Vector2, font_size: int, color: Color) -> Label:
	var item := Label.new()
	item.text = value
	item.position = at
	item.size = dimensions
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.add_theme_font_size_override("font_size",font_size)
	if font_size >= 22:
		item.add_theme_font_override("font", serif)
		item.add_theme_constant_override("outline_size", 1)
		item.add_theme_color_override("font_outline_color", color.darkened(0.2))
	item.add_theme_color_override("font_shadow_color", Color.BLACK)
	item.add_theme_constant_override("shadow_offset_y", 2)
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
	item.add_theme_font_override("font", serif)
	item.add_theme_color_override("font_color",Color("f1e2c9"))
	item.add_theme_stylebox_override("normal",box(Color("10141a"),Color("93754d")))
	item.add_theme_stylebox_override("hover",box(Color("462851"),Color("e0bc80")))
	item.add_theme_stylebox_override("pressed",box(Color("100c17"),Color("b59665")))
	canvas.add_child(item)
	return item

func _select(index: int) -> void:
	selected_index = index
	var ch: Dictionary = roster[index]
	var profile: Dictionary = Assets.profile(ch.id)
	var path: String = profile.get("selection_scene_art",profile.get("illustration",""))
	portrait.texture = load(path) if not path.is_empty() and ResourceLoader.exists(path) else Assets.picture(ch.id,"selection")
	portrait.position = Vector2(-28,8) if ch.id == "mira" else Vector2(-24,-2)
	portrait.size = Vector2(780,960) if ch.id == "mira" else Vector2(770,732)
	asset_status.text = ""
	heading.text = ch.name
	quote.text = {"mira":"“빼앗긴 생명에도, 아직 쓸모는 있어.”", "kalian":"“내 검이 멈추기 전엔 끝나지 않는다.”", "sera":"“잊힌 이름 속에 힘이 잠들어 있다.”", "lucian":"“꺼진 불씨에도 축복은 남는다.”"}.get(ch.id, "")
	information.text = "생명력    %d\n\n소지금    120\n\n에너지    3" % ch.max_hp
	biography.text = INTRO.get(ch.id, ch.theme)
	slot.text = ch.class + " · " + ch.theme.replace(" / ", " · ")
	var relic := Data.starting_relic(ch.id)
	relic_art.texture = load(relic.art) if not relic.is_empty() else null
	relic_name.text = relic.name + "\n" + relic.rarity + " · 전용" if not relic.is_empty() else "시작 유물 미등록"
	relic_effect.text = Data.relic_text(relic) if not relic.is_empty() else "이 원정대원의 전용 유물은 아직 준비 중입니다."
	for i in range(selectors.size()):
		selection_frames[i].modulate = Color("ffe3aa") if i == index else Color("706575")
		selectors[i].add_theme_stylebox_override("normal",box(Color("25171e") if i==index else Color("101015"),Color("e1b775") if i==index else Color("604953")))

func _show_details() -> void:
	detail_popup.title = roster[selected_index].name + " · 상세정보"
	detail_popup.dialog_text = information.text
	detail_popup.popup_centered(Vector2i(560,540))

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not detail_popup.visible:
		back_requested.emit()
		get_viewport().set_input_as_handled()

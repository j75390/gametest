extends "res://scripts/codex_screen.gd"
## Character codex: pick a party member on the left, see the figure in the middle (with a motion
## preview when the character has motion frames), and read the profile, starting relic and own cards
## on the right.
signal cards_requested(owner: String)
const Assets = preload("res://scripts/character_assets.gd")
const Data = preload("res://scripts/game_data.gd")
const CodexData = preload("res://scripts/codex_data.gd")
const Visual = preload("res://scripts/character_visual.gd")
const MOTION_LABELS := {"idle": "대기", "walk": "걷기", "attack": "공격", "skill": "기술", "hurt": "피격", "death": "사망"}
const BIOS := {
	"mira": "성당 구호원에서 약을 만들던 연금술사. 기억은 희미하지만, 미라는 자신의 이름을 잊지 않았다. 오래된 가면 안쪽에도 같은 이름이 남아 있다. 다만 그 글씨는 자신의 필체와 다르다.",
	"severin": "수백 장의 판결문에 도장을 찍은 이단심문관. 적에게 죄목을 쌓고 마지막 판결로 끝낸다.",
	"calamo": "뼈 피리로 쥐 떼를 부르는 피리꾼. 쥐가 대신 맞고 쥐가 문다.",
	"esca": "화덕 문을 등에 멘 과자집의 생존자. 불씨를 모아 화덕 문을 열어 태운다."}

var roster: Array = []
var selected_id := ""
var selector_panels := {}
var stage_panel: Panel
var sprite_preview: Control
var still_picture: TextureRect
var motion_buttons: Array[Button] = []
var motion_index := 0
var pause_button: Button
var playing := true
var name_label: Label
var class_label: Label
var theme_label: Label
var bio_label: Label
var stats_label: Label
var relic_icon: TextureRect
var relic_name: Label
var relic_effect: Label
var card_row: Control
var open_cards_button: Button

func build() -> void:
	roster = Data.read("characters")
	make_label(canvas, "캐릭터 도감", Rect2(0, 22, 1440, 56), 44, GOLD, true)
	var y := 112.0
	for ch in roster:
		_selector(ch, Vector2(40, y))
		y += 168.0
	var stage := make_panel(canvas, Rect2(350, 100, 600, 690), Color(0.06, 0.05, 0.09, 0.9), EDGE, 14)
	stage.name = "Stage"
	stage_panel = stage
	still_picture = make_texture(stage, "", Rect2(20, 16, 560, 560), TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	still_picture.name = "StillPicture"
	sprite_preview = Visual.new()
	sprite_preview.name = "SpritePreview"
	sprite_preview.position = Vector2(20, 16)
	sprite_preview.size = Vector2(560, 560)
	sprite_preview.loop_preview = true
	stage.add_child(sprite_preview)
	var x := 20.0
	for key in Assets.KEYS:
		var button := _stage_button(MOTION_LABELS[key], Rect2(x, 598, 70, 44))
		var index := motion_buttons.size()
		button.pressed.connect(play_motion.bind(index))
		motion_buttons.append(button)
		x += 76.0
	pause_button = _stage_button("멈춤", Rect2(x + 8, 598, 84, 44))
	pause_button.name = "PauseButton"
	pause_button.pressed.connect(toggle_playing)
	make_label(stage, "모션 미리보기", Rect2(20, 648, 560, 30), 18, MUTED)
	var info := make_panel(canvas, Rect2(980, 100, 420, 690), Color(0.09, 0.07, 0.12, 0.94), EDGE, 14)
	name_label = make_label(info, "", Rect2(20, 14, 380, 54), 42, GOLD, true, HORIZONTAL_ALIGNMENT_LEFT)
	class_label = make_label(info, "", Rect2(20, 68, 380, 30), 22, Color("bda0d0"), false, HORIZONTAL_ALIGNMENT_LEFT)
	theme_label = make_label(info, "", Rect2(20, 98, 380, 30), 18, MUTED, false, HORIZONTAL_ALIGNMENT_LEFT)
	bio_label = make_label(info, "", Rect2(20, 136, 380, 150), 20, PARCHMENT, false, HORIZONTAL_ALIGNMENT_LEFT)
	bio_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	stats_label = make_label(info, "", Rect2(20, 292, 380, 56), 20, GOLD, false, HORIZONTAL_ALIGNMENT_LEFT)
	make_label(info, "시작 유물", Rect2(20, 352, 380, 28), 20, GOLD, true, HORIZONTAL_ALIGNMENT_LEFT)
	var relic_frame := make_panel(info, Rect2(20, 384, 76, 76), Color("0b080f"), Color("5b4a3a"), 8)
	relic_icon = make_texture(relic_frame, "", Rect2(5, 5, 66, 66), TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	relic_name = make_label(info, "", Rect2(108, 380, 292, 30), 21, PARCHMENT, true, HORIZONTAL_ALIGNMENT_LEFT)
	relic_effect = make_label(info, "", Rect2(108, 410, 292, 58), 17, MUTED, false, HORIZONTAL_ALIGNMENT_LEFT)
	make_label(info, "전용 카드", Rect2(20, 474, 380, 28), 20, GOLD, true, HORIZONTAL_ALIGNMENT_LEFT)
	card_row = Control.new()
	card_row.position = Vector2(20, 506)
	info.add_child(card_row)
	open_cards_button = Button.new()
	open_cards_button.name = "OpenCards"
	open_cards_button.text = "전용 카드 보기  →"
	open_cards_button.position = Vector2(20, 646)
	open_cards_button.size = Vector2(380, 38)
	open_cards_button.add_theme_font_size_override("font_size", 21)
	open_cards_button.add_theme_font_override("font", UiFont.serif())
	open_cards_button.pressed.connect(func(): cards_requested.emit(selected_id))
	info.add_child(open_cards_button)
	if roster.is_empty(): return
	select(str(roster[0].id))

func _selector(ch: Dictionary, at: Vector2) -> void:
	var panel := make_panel(canvas, Rect2(at, Vector2(270, 150)), Color(0.09, 0.07, 0.12, 0.94), EDGE, 12)
	panel.name = "Select_" + str(ch.id)
	selector_panels[str(ch.id)] = panel
	var medallion := make_panel(panel, Rect2(12, 12, 126, 126), Color("0b080f"), Color("c9a86a"), 63)
	medallion.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	make_texture(medallion, "", Rect2(0, 0, 126, 126)).texture = Assets.picture(str(ch.id), "map_portrait")
	make_label(panel, str(ch.name), Rect2(146, 34, 116, 40), 28, PARCHMENT, true)
	make_label(panel, str(ch.get("class", "")), Rect2(146, 76, 116, 30), 19, MUTED)
	var hit := click_area(panel, Rect2(0, 0, 270, 150), 12)
	hit.name = "Pick_" + str(ch.id)
	hit.pressed.connect(select.bind(str(ch.id)))

func _stage_button(text: String, rect: Rect2) -> Button:
	var button := Button.new()
	button.text = text
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_font_override("font", UiFont.serif())
	button.add_theme_color_override("font_color", PARCHMENT)
	button.add_theme_color_override("font_disabled_color", Color("5b5560"))
	button.add_theme_stylebox_override("normal", box(Color("1b1522"), Color("5b4a3a"), 2, 8))
	button.add_theme_stylebox_override("hover", box(Color("2a2036"), GOLD, 2, 8))
	button.add_theme_stylebox_override("pressed", box(Color("3a2b4d"), GOLD, 2, 8))
	button.add_theme_stylebox_override("disabled", box(Color("120e18"), Color("2c2733"), 2, 8))
	stage_panel.add_child(button)
	return button

func select(id: String) -> void:
	selected_id = id
	var ch: Dictionary = {}
	for item in roster:
		if str(item.id) == id: ch = item
	for key in selector_panels:
		selector_panels[key].add_theme_stylebox_override("panel", box(Color(0.16, 0.11, 0.2, 0.98) if key == id else Color(0.09, 0.07, 0.12, 0.94), GOLD if key == id else EDGE, 2, 12))
	name_label.text = str(ch.name)
	class_label.text = str(ch.get("class", ""))
	theme_label.text = str(ch.get("theme", ""))
	bio_label.text = BIOS.get(id, str(ch.get("biography", ch.get("selection_bio", ""))))
	stats_label.text = "최대 체력  %d     시작 에너지  3\n시작 골드  120" % int(ch.get("max_hp", 0))
	var relic: Dictionary = Data.starting_relic(id)
	var relic_path := str(relic.get("art", ""))
	relic_icon.texture = load(relic_path) if not relic_path.is_empty() and ResourceLoader.exists(relic_path) else null
	relic_name.text = str(relic.get("name", "시작 유물 없음"))
	relic_effect.text = Data.relic_text(relic) if not relic.is_empty() else ""
	# motion preview exists only for characters with motion frames
	var animated := Assets.count(id, "idle") > 0
	sprite_preview.visible = animated
	still_picture.visible = not animated
	if animated:
		sprite_preview.setup(id)
		motion_index = 0
		playing = true
		sprite_preview.set_process(true)
		pause_button.text = "멈춤"
	else:
		sprite_preview.set_process(false)
		playing = false
		motion_index = 0
		still_picture.texture = Assets.picture(id, "selection")
	for button in motion_buttons: button.disabled = not animated
	pause_button.disabled = not animated
	_fill_cards(id)

func play_motion(index: int) -> void:
	if not sprite_preview.visible: return
	motion_index = clampi(index, 0, Assets.KEYS.size() - 1)
	sprite_preview.play(Assets.KEYS[motion_index])

func toggle_playing() -> void:
	playing = not playing
	sprite_preview.set_process(playing)
	pause_button.text = "멈춤" if playing else "재생"

func _fill_cards(id: String) -> void:
	for child in card_row.get_children():
		card_row.remove_child(child)
		child.queue_free()
	var x := 0.0
	var shown := 0
	for row in CodexData.cards(card_character):
		if str(row.owner) != id: continue
		if shown >= 4: break
		var card := card_view(row.record, id, row.state)
		card.scale = Vector2.ONE * 0.4
		card.position = Vector2(x, 0)
		card_row.add_child(card)
		x += 92.0
		shown += 1
	open_cards_button.disabled = shown == 0

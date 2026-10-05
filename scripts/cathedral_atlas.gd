extends Control
signal closed
signal observed(id: String)
var progress := 0
var flags: Dictionary = {}
var caption: Label
const PLACES = [
	["gate", "문지기실", Vector2(.35,.84), 0, "낡은 등불 아래에서 에델이 길을 지킨다. 남쪽 계단은 마을로 이어진다."],
	["reception", "진료 접수실", Vector2(.37,.43), 1, "긴 의자들이 입구를 향해 놓여 있다. 접수 창구의 종은 줄이 끊어진 채 남아 있다."],
	["ward", "빈 병동", Vector2(.26,.23), 3, "침상 여섯 개. 빈 이불 위에도 회진의 흔적이 남아 있다."],
	["medicine", "약품 회랑", Vector2(.60,.44), 5, "가운데 타일만 수레바퀴 너비로 닳았다. 높은 창에서는 남쪽 마을이 보이지 않는다."],
	["waiting", "퇴원 대기실", Vector2(.59,.30), 8, "접수실과 달리 의자는 벽을 향한다. 문 옆 승인함에는 밖으로 가져갈 종이가 없다."],
	["warden", "수문장의 문", Vector2(.73,.15), 11, "병동에서 나오는 사람도 통과해야 하는 문이다. 출구 가까이에 인계 서류 보관대가 있다."],
	["landing", "지하 선착장", Vector2(.87,.70), 12, "돌계단이 운하 수면까지 내려간다. 다음 지역으로 이어지는 길은 여기서 시작된다."]
]

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color("100f13")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,20)
	add_child(margin)
	var root := VBoxContainer.new()
	margin.add_child(root)
	var bar := HBoxContainer.new()
	root.add_child(bar)
	var heading := Label.new()
	heading.text = "잿빛 성당 · 조사 지도"
	heading.add_theme_font_size_override("font_size",26)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(heading)
	var close := Button.new()
	close.text = "돌아가기 ×"
	close.pressed.connect(func(): closed.emit())
	bar.add_child(close)
	var aspect := AspectRatioContainer.new()
	aspect.ratio = 1.5
	aspect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(aspect)
	var canvas := Control.new()
	aspect.add_child(canvas)
	var image := TextureRect.new()
	image.texture = load("res://assets/map/cathedral_atlas_v1.png")
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_SCALE
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(image)
	for place in PLACES:
		var button := Button.new()
		var known: bool = progress >= place[3]
		button.text = place[1] if known else "미답 구역"
		button.disabled = not known
		button.tooltip_text = "아직 도착하지 않은 구역입니다." if not known else place[4]
		button.set_anchors_preset(Control.PRESET_TOP_LEFT)
		button.anchor_left = place[2].x
		button.anchor_right = place[2].x
		button.anchor_top = place[2].y
		button.anchor_bottom = place[2].y
		button.offset_left = -68
		button.offset_right = 68
		button.offset_top = -18
		button.offset_bottom = 18
		button.pressed.connect(_inspect.bind(place))
		canvas.add_child(button)
	caption = Label.new()
	caption.custom_minimum_size.y = 90
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.add_theme_font_size_override("font_size",18)
	caption.text = "도착한 구역을 눌러 살펴보세요. 전투 경로의 진행에 따라 조사할 수 있는 장소가 늘어납니다."
	root.add_child(caption)

func _inspect(place: Array):
	if progress < place[3]: return
	caption.text = place[1] + "\n" + place[4]
	if place[0] == "ward":
		caption.text += "\n덮개 하나에만 새 실이 섞여 있다. 빈 침대도 누군가 계속 수선하고 있다. 조사 기록에 남겼다."
		observed.emit("cathedral_mended_cover")
	if place[0] == "reception":
		caption.text += "\n완치 도장의 잉크가 모두 같은 방향으로 번졌다. 한꺼번에 찍은 것인지, 아직은 알 수 없다. 조사 기록에 남겼다."
		observed.emit("cathedral_stamps")

func _unhandled_key_input(event):
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		closed.emit()

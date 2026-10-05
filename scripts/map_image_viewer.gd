extends Control
var art: Texture2D
var zoom := 1.0
var scroll: ScrollContainer
var picture: TextureRect
var level: Label
func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color("090a0e")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var layout := VBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.offset_left = 18
	layout.offset_right = -18
	layout.offset_top = 14
	layout.offset_bottom = -14
	add_child(layout)
	var bar := HBoxContainer.new()
	layout.add_child(bar)
	for item in [["−",func(): change_zoom(zoom / 1.25)],["+",func(): change_zoom(zoom * 1.25)],["화면에 맞춤",func(): change_zoom(1.0)],["닫기 ×",func(): queue_free()]]:
		var button := Button.new()
		button.text = item[0]
		button.custom_minimum_size = Vector2(70,44)
		button.pressed.connect(item[1])
		bar.add_child(button)
	level = Label.new()
	bar.add_child(level)
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)
	picture = TextureRect.new()
	picture.texture = art
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	scroll.add_child(picture)
	scroll.resized.connect(_fit)
	_fit.call_deferred()

func change_zoom(value: float):
	zoom = clampf(value,1.0,4.0)
	_fit()

func _fit():
	var extent := scroll.size - Vector2(18,18)
	var ratio := minf(extent.x / art.get_width(), extent.y / art.get_height())
	picture.custom_minimum_size = art.get_size() * ratio * zoom
	level.text = "  %d%% · 확대 후 스크롤로 이동" % roundi(zoom*100)

func _unhandled_key_input(event):
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		queue_free()

extends Control
## The quiet screen after the last boss and the epilogue: a few lines about what the party leaves behind,
## then the ending's name and its closing sentence on black. No buttons and no hints; a click moves on.
signal finished
const UiFont = preload("res://scripts/ui_font.gd")
const FADE := 1.1
const HOLD := 2.4
const CLICK_COOLDOWN := 0.6
var canvas := Control.new()
var lines: Array[String] = []
var ending_name := ""
var closing := ""
var tint := Color("d9c3b0")
var line_labels: Array[Label] = []
var title_label: Label
var closing_label: Label
var step := -1
var step_started := 0.0
var step_tween: Tween
var done := false

func setup(name_value: String, closing_value: String, line_values: Array[String], tint_value: Color) -> void:
	ending_name = name_value
	closing = closing_value
	lines = line_values
	tint = tint_value

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := ColorRect.new()
	backdrop.color = Color.BLACK
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# the backdrop and canvas must let the click through to this control
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	add_child(canvas)
	canvas.size = Vector2(1440, 900)
	var top := 300.0
	for text in lines:
		var item := _label(text, Vector2(170, top), Vector2(1100, 90), 27, Color("cfc4b6"))
		item.modulate.a = 0.0
		item.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		line_labels.append(item)
		top += 110.0
	title_label = _label(ending_name, Vector2(120, 340), Vector2(1200, 90), 58, tint)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.modulate.a = 0.0
	closing_label = _label(closing, Vector2(170, 470), Vector2(1100, 160), 24, Color("8c8c8c"))
	closing_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	closing_label.modulate.a = 0.0
	resized.connect(fit)
	fit()
	_next_step()

func fit() -> void:
	var ratio := minf(size.x / 1440.0, size.y / 900.0)
	canvas.scale = Vector2.ONE * ratio
	canvas.position = (size - Vector2(1440, 900) * ratio) * 0.5

func _label(value: String, at: Vector2, dimensions: Vector2, font_size: int, color: Color) -> Label:
	var item := Label.new()
	# one sentence per line: the engine would otherwise cut a sentence in the middle of a word
	item.text = value.replace(". ", ".\n")
	item.position = at
	item.size = dimensions
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.add_theme_font_override("font", UiFont.serif(false))
	item.add_theme_font_size_override("font_size", font_size)
	item.add_theme_color_override("font_color", color)
	item.add_theme_constant_override("line_spacing", 8)
	canvas.add_child(item)
	return item

## Steps 0..n-1 show the lines one by one (earlier lines dim), step n clears them and shows the name and closing sentence.
func _next_step() -> void:
	if step_tween != null and step_tween.is_valid(): step_tween.kill()
	step += 1
	step_started = Time.get_ticks_msec() / 1000.0
	if step < line_labels.size():
		for i in range(step):
			create_tween().tween_property(line_labels[i], "modulate:a", 0.42, FADE)
		step_tween = create_tween()
		step_tween.tween_property(line_labels[step], "modulate:a", 1.0, FADE)
		step_tween.tween_interval(HOLD)
		step_tween.tween_callback(_next_step)
	elif step == line_labels.size():
		step_tween = create_tween()
		step_tween.set_parallel(true)
		for item in line_labels:
			step_tween.tween_property(item, "modulate:a", 0.0, FADE)
		step_tween.chain().tween_interval(0.4)
		step_tween.chain().tween_property(title_label, "modulate:a", 1.0, FADE * 1.5)
		step_tween.chain().tween_property(closing_label, "modulate:a", 1.0, FADE * 1.5)
		step_tween.chain().tween_interval(2.0)
		step_tween.chain().tween_callback(func(): step = line_labels.size() + 1)
	else:
		_finish()

func _finish() -> void:
	if done: return
	done = true
	finished.emit()

func _unhandled_key_input(input: InputEvent) -> void:
	_gui_input(input)

func _gui_input(input: InputEvent) -> void:
	var pressed: bool = (input is InputEventMouseButton and input.pressed and input.button_index == MOUSE_BUTTON_LEFT) or (input is InputEventKey and input.pressed and not input.echo)
	if not pressed or done: return
	# a click right after a step started is ignored so a quick double click cannot skip a whole line
	if Time.get_ticks_msec() / 1000.0 - step_started < CLICK_COOLDOWN: return
	if step <= line_labels.size() - 1:
		line_labels[step].modulate.a = 1.0
	if step == line_labels.size() and title_label.modulate.a < 1.0:
		title_label.modulate.a = 1.0
		closing_label.modulate.a = 1.0
		if step_tween != null and step_tween.is_valid(): step_tween.kill()
		step = line_labels.size() + 1
		step_started = Time.get_ticks_msec() / 1000.0
		return
	_next_step()

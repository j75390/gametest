extends Control
signal reward_chosen(index: int)
signal continue_requested
var canvas := Control.new()
var dialogue: Label
var actions := VBoxContainer.new()
var event: Dictionary
var offered_card: Dictionary
var hero_name := ""
var dialogue_index := 0
var art_frame: Control
var quote_bar: ColorRect
var progress: Label
var typing: Tween
const TEXT_TOP := 256.0
const ACTIONS_GAP := 36.0

func setup(record: Dictionary, card: Dictionary, character_name: String) -> void:
	event = record
	offered_card = card
	hero_name = character_name

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := ColorRect.new()
	backdrop.color = Color("100d15")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	add_child(canvas)
	canvas.size = Vector2(1440,900)
	art_frame = Control.new()
	art_frame.position = Vector2(36,32)
	art_frame.size = Vector2(550,836)
	art_frame.clip_contents = true
	canvas.add_child(art_frame)
	var art := TextureRect.new()
	art.texture = load(event.art) if not event.get("art", "").is_empty() else null
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.size = art_frame.size
	art.pivot_offset = art.size * 0.5
	art_frame.add_child(art)
	label_at(event.get("chapter", "ACT I · 잿빛 성당"),Vector2(632,66),Vector2(732,36),20,Color("ae8f62"))
	label_at(event.name,Vector2(632,116),Vector2(732,68),38,Color("ebd8b7"))
	var rule := ColorRect.new()
	rule.color = Color(0.68, 0.56, 0.38, 0.45)
	rule.position = Vector2(632,192)
	rule.size = Vector2(732,1)
	canvas.add_child(rule)
	label_at(event.get("speaker", "미라의 기록"),Vector2(632,204),Vector2(560,32),22,Color("bba0d1"))
	progress = label_at("",Vector2(1212,208),Vector2(152,28),18,Color("8f7a96"))
	progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	quote_bar = ColorRect.new()
	quote_bar.color = Color(0.73, 0.63, 0.82, 0.55)
	quote_bar.position = Vector2(632,TEXT_TOP + 4)
	quote_bar.size = Vector2(3,120)
	canvas.add_child(quote_bar)
	dialogue = label_at("",Vector2(656,TEXT_TOP),Vector2(708,188),25,Color("eee2d7"))
	dialogue.add_theme_constant_override("line_spacing",8)
	actions.position = Vector2(632,492)
	actions.size = Vector2(732,340)
	actions.add_theme_constant_override("separation",14)
	canvas.add_child(actions)
	if art.texture == null:
		art_frame.hide()
		for child in canvas.get_children():
			if child is Label:
				child.position.x = 120
				child.size.x = 1200
			elif child is ColorRect and child != backdrop:
				child.position.x = 120
				if child.size.y <= 1: child.size.x = 1200
		dialogue.position.x = 144
		dialogue.size.x = 1176
		progress.position.x = 1168
		actions.position.x = 120
		actions.size.x = 1200
		dialogue.add_theme_font_size_override("font_size", 24)
	canvas.modulate.a = 0.0
	create_tween().tween_property(canvas,"modulate:a",1.0,0.5)
	resized.connect(fit)
	fit()
	show_dialogue()

func fit() -> void:
	var ratio := minf(size.x / 1440.0,size.y / 900.0)
	canvas.scale = Vector2.ONE * ratio
	canvas.position = (size - Vector2(1440,900) * ratio) * 0.5

func label_at(value: String, at: Vector2, dimensions: Vector2, font_size: int, tint: Color) -> Label:
	var item := Label.new()
	item.text = value
	item.position = at
	item.size = dimensions
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.add_theme_font_size_override("font_size",font_size)
	item.add_theme_color_override("font_color",tint)
	canvas.add_child(item)
	return item

func clear_actions() -> void:
	for child in actions.get_children():
		actions.remove_child(child)
		child.queue_free()

func button(value: String, callback: Callable) -> Button:
	var item := Button.new()
	item.text = value
	item.custom_minimum_size = Vector2(actions.size.x,82)
	item.add_theme_font_size_override("font_size",21)
	item.alignment = HORIZONTAL_ALIGNMENT_LEFT
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var style := StyleBoxFlat.new()
	style.bg_color = Color("251c30")
	style.border_color = Color("8f7250")
	style.set_border_width_all(1)
	style.content_margin_left = 22
	var hover := style.duplicate()
	hover.bg_color = Color("413049")
	hover.border_color = Color("e2bb7e")
	item.add_theme_stylebox_override("normal",style)
	item.add_theme_stylebox_override("hover",hover)
	item.add_theme_stylebox_override("focus",hover)
	item.pressed.connect(callback)
	actions.add_child(item)
	return item

func _gui_input(input: InputEvent) -> void:
	if input is InputEventMouseButton and input.pressed and input.button_index == MOUSE_BUTTON_LEFT:
		finish_typing()

func finish_typing() -> void:
	if typing != null and typing.is_valid():
		typing.kill()
		dialogue.visible_ratio = 1.0
		actions.modulate.a = 1.0

## Puts a page of text on screen: the box fits the text, the choices sit right under it, and the words
## appear a few letters at a time before the choices fade in.
func present(text: String) -> void:
	dialogue.text = text
	var font := dialogue.get_theme_font("font")
	var font_size := dialogue.get_theme_font_size("font_size")
	var box := font.get_multiline_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,dialogue.size.x,font_size)
	var line_count := maxi(1,roundi(box.y / font.get_height(font_size)))
	var wanted := maxf(96.0,box.y + line_count * float(dialogue.get_theme_constant("line_spacing")) + 12.0)
	dialogue.size.y = wanted
	dialogue.size.y = wanted
	quote_bar.size.y = wanted - 8.0
	actions.position.y = TEXT_TOP + wanted + ACTIONS_GAP
	if progress != null:
		progress.text = "%d / %d" % [mini(dialogue_index + 1, event.dialogue.size()), event.dialogue.size()] if event.dialogue.size() > 1 and dialogue_index < event.dialogue.size() else ""
	if typing != null and typing.is_valid(): typing.kill()
	dialogue.visible_ratio = 0.0
	actions.modulate.a = 0.0
	typing = create_tween()
	typing.tween_property(dialogue,"visible_ratio",1.0,clampf(text.length() * 0.022,0.4,2.6))
	typing.tween_property(actions,"modulate:a",1.0,0.25)

func show_dialogue() -> void:
	present(str(event.dialogue[dialogue_index]).replace("{hero}",hero_name))
	clear_actions()
	if dialogue_index < event.dialogue.size() - 1:
		button("이야기를 듣는다  →",func():
			dialogue_index += 1
			show_dialogue()
		)
	else:
		for i in range(event.choices.size()):
			var choice: Dictionary = event.choices[i]
			var description: String = choice.description
			if choice.get("reward","") == "card":
				description = description.replace("{card}",str(offered_card.get("name","")))
			# the choice's real effects are always spelled out; a description that only restates them is replaced
			var effect_line := str(choice.get("effect_line", ""))
			var body := description
			var restates := description.length() < 30 and (description.contains("얻습니다") or description.contains("회복합니다") or description.contains("잃고") or description.contains("내고"))
			if not effect_line.is_empty(): body = "▶ " + effect_line if restates else description + "\n▶ " + effect_line
			var option := button(choice.name + "\n" + body,func(): reward_chosen.emit(i))
			if body.contains("\n▶"): option.custom_minimum_size.y = 92
			option.disabled = choice.get("disabled", false)
			option.tooltip_text = choice.get("disabled_reason", "")
			if choice.get("reward","") == "card":
				option.disabled = offered_card.is_empty()
				if not offered_card.is_empty(): option.tooltip_text = preload("res://scripts/game_data.gd").effect_text(offered_card)

func show_result(reply: String) -> void:
	present(reply)
	progress.text = ""
	clear_actions()
	button(event.get("continue_label", "성당으로 들어간다  →"),func(): continue_requested.emit())

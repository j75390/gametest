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
	var art := TextureRect.new()
	art.texture = load(event.art)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.position = Vector2(36,32)
	art.size = Vector2(550,836)
	canvas.add_child(art)
	label_at("ACT I · 잿빛 성당",Vector2(632,66),Vector2(732,36),20,Color("ae8f62"))
	label_at(event.name,Vector2(632,116),Vector2(732,68),38,Color("ebd8b7"))
	label_at(event.speaker,Vector2(632,204),Vector2(732,32),22,Color("bba0d1"))
	dialogue = label_at("",Vector2(632,256),Vector2(720,188),25,Color("eee2d7"))
	actions.position = Vector2(632,492)
	actions.size = Vector2(732,340)
	actions.add_theme_constant_override("separation",14)
	canvas.add_child(actions)
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
	item.custom_minimum_size = Vector2(732,82)
	item.add_theme_font_size_override("font_size",21)
	item.alignment = HORIZONTAL_ALIGNMENT_LEFT
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

func show_dialogue() -> void:
	dialogue.text = str(event.dialogue[dialogue_index]).replace("{hero}",hero_name)
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
			var option := button(choice.name + "\n" + description,func(): reward_chosen.emit(i))
			if choice.get("reward","") == "card":
				option.disabled = offered_card.is_empty()
				if not offered_card.is_empty(): option.tooltip_text = preload("res://scripts/game_data.gd").effect_text(offered_card)

func show_result(reply: String) -> void:
	dialogue.text = reply
	clear_actions()
	button("성당으로 들어간다  →",func(): continue_requested.emit())

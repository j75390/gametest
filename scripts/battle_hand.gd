extends Control
const Data = preload("res://scripts/game_data.gd")
signal card_requested(index: int)
var cards: Array = []
var views: Array[Control] = []
var selected := -1
var energy := 0
var locked := false
var target: Control
var aiming: Control
var pressing := false
var press_origin := Vector2.ZERO
var pointer := Vector2.ZERO

class AimOverlay extends Control:
	var hand
	func _draw():
		if not is_instance_valid(hand) or hand.selected < 0: return
		if not hand.needs_target(hand.selected): return
		var start: Vector2 = hand.views[hand.selected].get_global_rect().get_center()
		var end: Vector2 = hand.pointer
		var valid: bool = hand.target.get_global_rect().has_point(end)
		var color := Color("e8c171") if valid else Color("b078d5")
		var points := PackedVector2Array()
		var bend := Vector2(start.x, minf(start.y, end.y) - 90)
		for i in range(25):
			var t := i / 24.0
			points.append(start.lerp(bend, t).lerp(bend.lerp(end, t), t))
		draw_polyline(points, Color("24112e"), 10, true)
		draw_polyline(points, color, 5, true)
		var direction := (end - points[23]).normalized()
		draw_colored_polygon(PackedVector2Array([end, end - direction.rotated(0.5) * 24, end - direction.rotated(-0.5) * 24]), color)
		if valid:
			var rect: Rect2 = hand.target.get_global_rect().grow(5)
			for corner in [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]:
				var dx := 1 if corner.x == rect.position.x else -1
				var dy := 1 if corner.y == rect.position.y else -1
				draw_line(corner, corner + Vector2(24 * dx, 0), color, 3, true)
				draw_line(corner, corner + Vector2(0, 24 * dy), color, 3, true)

func setup(values: Array, available: int, busy: bool, enemy: Control) -> void:
	cards = values
	energy = available
	locked = busy
	target = enemy
	custom_minimum_size.y = 245
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in range(cards.size()):
		var c: Dictionary = cards[i]
		var panel := PanelContainer.new()
		panel.name = "Card%d" % i
		var style := StyleBoxFlat.new()
		style.bg_color = Color("211329")
		style.border_color = Color("bc9859")
		style.set_border_width_all(2)
		style.set_corner_radius_all(10)
		style.content_margin_left = 8
		style.content_margin_right = 8
		style.content_margin_top = 7
		style.content_margin_bottom = 8
		panel.add_theme_stylebox_override("panel", style)
		panel.tooltip_text = "%s · 비용 %d\n%s\n%s" % [c.name, c.cost, c.type, Data.effect_text(c)]
		add_child(panel)
		views.append(panel)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 3)
		panel.add_child(column)
		var heading := Label.new()
		heading.text = "%d  ·  %s" % [c.cost, c.name]
		heading.add_theme_font_size_override("font_size", 17)
		heading.add_theme_color_override("font_color", Color("ead9b2"))
		column.add_child(heading)
		var art := TextureRect.new()
		art.texture = load(c.art)
		art.custom_minimum_size = Vector2(0, 91)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		column.add_child(art)
		var kind := Label.new()
		kind.text = "%s · %s" % [c.type, c.rarity]
		kind.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		kind.add_theme_font_size_override("font_size", 12)
		kind.modulate = Color("c6afd5")
		column.add_child(kind)
		var description := Label.new()
		description.text = Data.effect_text(c)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.add_theme_font_size_override("font_size", 13)
		column.add_child(description)
		_ignore_children(panel)
		panel.gui_input.connect(_card_input.bind(i))
		panel.minimum_size_changed.connect(_layout.call_deferred)
		panel.modulate = Color(0.48, 0.48, 0.48) if locked or c.cost > energy else Color.WHITE
	aiming = AimOverlay.new()
	aiming.hand = self
	aiming.mouse_filter = Control.MOUSE_FILTER_IGNORE
	aiming.z_index = 80
	get_tree().root.add_child(aiming)
	aiming.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(_layout)
	_layout()

func _ignore_children(node: Node):
	for child in node.get_children():
		if child is Control: child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ignore_children(child)

func needs_target(index: int) -> bool:
	return str(cards[index].get("target", "")).contains("적")

func _exit_tree():
	if is_instance_valid(aiming): aiming.queue_free()

func _layout():
	if views.is_empty(): return
	var width := minf(192, maxf(145, (size.x - 70) / maxf(1, views.size())))
	var step := minf(width + 9, maxf(55, (size.x - width - 20) / maxf(1, views.size() - 1)))
	var left := (size.x - (views.size() - 1) * step - width) / 2
	for i in range(views.size()):
		views[i].size = Vector2(width, 220)
		views[i].position = Vector2(left + step * i, 22)
		views[i].pivot_offset = Vector2(width / 2, 220)

func _process(_delta):
	for i in range(views.size()):
		var focused: bool = selected == i or (selected < 0 and views[i].get_global_rect().has_point(pointer))
		views[i].scale = Vector2.ONE * (1.08 if focused else 1.0)
		views[i].z_index = 10 if focused else i
	if is_instance_valid(aiming): aiming.queue_redraw()

func _card_input(event: InputEvent, index: int):
	if locked or cards[index].cost > energy: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		selected = index
		pressing = true
		press_origin = pointer
		accept_event()

func cancel():
	selected = -1
	pressing = false

func commit():
	var index := selected
	cancel()
	if index >= 0 and not locked:
		locked = true
		card_requested.emit(index)

func _input(event: InputEvent):
	if event is InputEventMouse: pointer = event.position
	if selected < 0 or locked: return
	if (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE) or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT):
		cancel()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var point := pointer
		if event.pressed and not pressing and needs_target(selected) and target.get_global_rect().has_point(point):
			get_viewport().set_input_as_handled()
			commit()
		elif not event.pressed and pressing:
			pressing = false
			if needs_target(selected):
				if target.get_global_rect().has_point(point): commit()
				elif point.distance_to(press_origin) > 12: cancel()
			elif point.distance_to(press_origin) < 12 or point.y < global_position.y:
				commit()
			else: cancel()

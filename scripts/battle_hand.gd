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
var hovered := -1
var homes: Array[Vector2] = []
var angles: Array[float] = []

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
	custom_minimum_size.y = 365
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in range(cards.size()):
		var panel = preload("res://scripts/battle_card.gd").new()
		panel.name = "Card%d" % i
		panel.setup(cards[i])
		add_child(panel)
		views.append(panel)
		panel.modulate = Color(0.48, 0.48, 0.48) if locked or cards[i].cost > energy else Color.WHITE
	aiming = AimOverlay.new()
	aiming.hand = self
	aiming.mouse_filter = Control.MOUSE_FILTER_IGNORE
	aiming.z_index = 80
	get_tree().root.add_child(aiming)
	aiming.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(_layout)
	_layout()
func needs_target(index: int) -> bool:
	return str(cards[index].get("target", "")).contains("적")

func _exit_tree():
	if is_instance_valid(aiming): aiming.queue_free()

func _layout():
	if views.is_empty(): return
	homes.clear()
	angles.clear()
	var step := minf(140, maxf(38, (size.x - 300) / maxf(1, views.size() - 1)))
	var left := (size.x - (views.size() - 1) * step - 220) / 2
	for i in range(views.size()):
		var spread := (i - (views.size() - 1) / 2.0) / maxf(1, (views.size() - 1) / 2.0)
		homes.append(Vector2(left + step * i, size.y - 355 + absf(spread) * 12))
		angles.append(deg_to_rad(spread * 8))
		views[i].pivot_offset = Vector2(110, 300)
		views[i].position = homes[i]
		views[i].rotation = angles[i]
		views[i].scale = Vector2.ONE * 0.88
		views[i].z_index = i

func _hit_index(point: Vector2) -> int:
	var order: Array[int] = []
	for i in range(views.size()): order.append(i)
	order.sort_custom(func(a, b): return views[a].z_index > views[b].z_index)
	for i in order:
		var local: Vector2 = views[i].get_global_transform().affine_inverse() * point
		if Rect2(Vector2.ZERO, views[i].size).has_point(local): return i
	return -1

func _process(delta):
	for i in range(views.size()):
		var focused: bool = selected == i or (selected < 0 and hovered == i)
		var weight := minf(delta * 20, 1)
		views[i].scale = views[i].scale.lerp(Vector2.ONE * (1.06 if focused else 0.88), weight)
		views[i].rotation = lerp_angle(views[i].rotation, 0.0 if focused else angles[i], weight)
		views[i].position = views[i].position.lerp(homes[i] + Vector2(0, -46 if focused else 0), weight)
		views[i].z_index = 30 if focused else i
		views[i].set_active(focused and not locked)
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
	if event is InputEventMouse:
		pointer = event.position
		if event is InputEventMouseMotion and selected < 0: hovered = _hit_index(pointer)
	if selected < 0 and not locked and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var index := _hit_index(pointer)
		if index >= 0:
			_card_input(event, index)
			return
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

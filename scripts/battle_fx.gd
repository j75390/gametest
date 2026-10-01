extends Control
## Short, reusable presentation sequences; combat mutation occurs only at impact.
signal phase_changed(phase: String)
var phase := "idle"
var rings: Array[Dictionary] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 50

func mark(value: String) -> void:
	phase = value
	phase_changed.emit(value)

func center(actor: Control) -> Vector2:
	return actor.get_global_rect().get_center() - global_position

func _process(delta: float) -> void:
	for ring in rings: ring.age += delta
	rings = rings.filter(func(r): return r.age < 0.5)
	queue_redraw()

func _draw() -> void:
	for ring in rings:
		var t: float = ring.age / 0.5
		var color: Color = ring.color
		color.a = 1.0 - t
		for i in range(6):
			var angle := i * TAU / 6 + 0.25
			var tip := Vector2.from_angle(angle) * (48 + 70 * t)
			var edge := Vector2.from_angle(angle + PI / 2) * (7 * (1 - t))
			draw_colored_polygon(PackedVector2Array([ring.point + edge, ring.point + tip, ring.point - edge]), color)
		if t < 0.2: draw_circle(ring.point, 14 * (1 - t / 0.2), Color(1, 0.92, 1, 0.8), true, -1, true)
		draw_arc(ring.point, 12 + 68 * t, 0, TAU, 48, color, 4 * (1 - t) + 1, true)
		for i in range(8):
			var direction := Vector2.from_angle(i * TAU / 8 + 0.2)
			draw_line(ring.point + direction * (10 + 35 * t), ring.point + direction * (35 + 75 * t), color, 3 * (1 - t) + 1, true)

func float_text(actor: Control, text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color("17101e"))
	label.add_theme_constant_override("outline_size", 7)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	label.position = center(actor) - Vector2(label.get_minimum_size().x / 2, 55)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 65, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.3).set_delay(0.4)
	tween.chain().tween_callback(label.queue_free)

func impact(actor: Control, color: Color, text: String, shake := true) -> void:
	rings.append({"point": center(actor), "color": color, "age": 0.0})
	if not text.is_empty(): float_text(actor, text, color)
	if not shake: return
	var home := actor.position
	var original := actor.modulate
	var tween := create_tween()
	actor.modulate = Color(1.0, 0.48, 0.65)
	for offset in [-8, 7, -5, 4, -2, 0]:
		tween.tween_property(actor, "position", home + Vector2(offset, 0), 0.045)
	tween.tween_property(actor, "modulate", original, 0.10)

func strike(attacker: Control, target: Control, ranged: bool, color: Color, apply: Callable) -> void:
	var home := attacker.position
	var old_scale := attacker.scale
	var old_z := attacker.z_index
	attacker.z_index = 10
	var direction := signf(target.global_position.x - attacker.global_position.x)
	mark("prepare")
	var windup := create_tween().set_parallel(true)
	windup.tween_property(attacker, "position:x", home.x - direction * 18, 0.16)
	windup.tween_property(attacker, "scale", old_scale * 0.96, 0.16)
	await windup.finished
	mark("travel")
	if ranged:
		var projectile := Line2D.new()
		projectile.width = 8
		projectile.default_color = color
		projectile.antialiased = true
		add_child(projectile)
		var start := center(attacker)
		var end := center(target)
		var travel := create_tween()
		travel.tween_method(func(t: float): projectile.points = PackedVector2Array([start.lerp(end, maxf(0, t - 0.18)), start.lerp(end, t)]), 0.0, 1.0, 0.18)
		await travel.finished
		projectile.queue_free()
	else:
		var travel := create_tween().set_parallel(true)
		var distance := center(target).x - center(attacker).x - direction * 110
		travel.tween_property(attacker, "position:x", home.x + distance, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		travel.tween_property(attacker, "scale", old_scale * 1.05, 0.16)
		await travel.finished
	apply.call()
	mark("impact")
	await get_tree().create_timer(0.08).timeout
	mark("return")
	var back := create_tween().set_parallel(true)
	back.tween_property(attacker, "position", home, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	back.tween_property(attacker, "scale", old_scale, 0.22)
	await back.finished
	attacker.z_index = old_z
	await get_tree().create_timer(0.18).timeout
	mark("idle")

func pulse(actor: Control, color: Color, apply: Callable) -> void:
	mark("prepare")
	await get_tree().create_timer(0.25).timeout
	apply.call()
	mark("impact")
	impact(actor, color, "", false)
	await get_tree().create_timer(0.55).timeout
	mark("idle")

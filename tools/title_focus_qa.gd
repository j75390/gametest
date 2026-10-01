extends SceneTree
var failures := 0
func _initialize() -> void:
	run.call_deferred()
func move_mouse(point: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point
	root.push_input(event, true)
	await process_frame
	await process_frame
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func run() -> void:
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var menu = main.title_menu
	for index in [3, 1, 4]:
		await move_mouse(menu.buttons[index].get_global_rect().get_center())
		check(menu.buttons[index].has_focus(), "Hover must select item")
		await move_mouse(menu.buttons[index].get_global_rect().get_center() + Vector2(250, 0))
		check(menu.buttons[index].has_focus(), "Leaving must retain selection")
		check(menu.highlights[index].visible and not menu.highlights[0].visible, "Highlight jumped to first item")
	var key := InputEventKey.new()
	key.keycode = KEY_UP
	key.pressed = true
	root.push_input(key, true)
	await process_frame
	key = InputEventKey.new()
	key.keycode = KEY_UP
	root.push_input(key, true)
	await process_frame
	check(menu.buttons[3].has_focus(), "Keyboard navigation failed")
	print("TITLE_FOCUS_QA mouse_exit=3 keyboard=1 failures=", failures)
	main.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)

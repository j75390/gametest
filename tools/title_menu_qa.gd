extends SceneTree
var failures: Array[String] = []
func _initialize() -> void:
	run.call_deferred()
func check(ok: bool, detail: String) -> void:
	if not ok:
		failures.append(detail)
		push_error(detail)
func click(button: Button) -> void:
	var point := button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion, true)
	await process_frame
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame
func run() -> void:
	root.size = Vector2i(1440, 900)
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	await process_frame
	check(main.title_menu.canvas.get_node("GameTitle").text == "잿빛 원정대", "Wrong title")
	for resolution in [Vector2i(1440,900), Vector2i(1280,720), Vector2i(1920,1080)]:
		root.size = resolution
		await process_frame
		await process_frame
		for button in main.title_menu.buttons:
			check(main.get_global_rect().encloses(button.get_global_rect()), "Menu clipped")
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/title-menu-%d.png" % resolution.x)
	root.size = Vector2i(1440,900)
	await process_frame
	await click(main.title_menu.buttons[2])
	check(main.has_node("Codex"), "Codex click failed")
	main.get_node("Codex").closed.emit()
	await process_frame
	await click(main.title_menu.buttons[1])
	check(main.title.text == "멀티 플레이" and main.shell.visible, "Multiplayer route failed")
	main.show_menu()
	await process_frame
	await click(main.title_menu.buttons[3])
	check(main.title.text == "설정", "Settings route failed")
	main.show_menu()
	await process_frame
	await click(main.title_menu.buttons[0])
	check(main.has_node("CharacterSelection"), "Single route failed")
	main.get_node("CharacterSelection").back_requested.emit()
	await process_frame
	check(is_instance_valid(main.title_menu), "Back to title failed")
	print("TITLE_MENU_QA resolutions=3 routes=4 failures=", failures.size())
	main.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

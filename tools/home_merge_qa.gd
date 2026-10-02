extends SceneTree
var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)
func _initialize() -> void:
	run.call_deferred()
func click(button: Button) -> void:
	var point := button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion)
	await process_frame
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event)
		await process_frame
func run() -> void:
	root.size = Vector2i(1440,900)
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	main.show_character_select()
	await process_frame
	var selection = main.get_node("CharacterSelection")
	for i in range(4):
		await click(selection.selectors[i])
		check(selection.selected_index == i, "Character click failed")
		check(selection.heading.text == main.characters[i].name, "Character data mismatch")
		check(selection.portrait.texture.get_image().detect_alpha() != Image.ALPHA_NONE, "Illustration lacks transparency")
		check(selection.asset_status.text.is_empty(), "Placeholder still displayed")
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/selection-merged-%s.png" % main.characters[i].id)
	selection.codex_requested.emit()
	await process_frame
	check(main.get_children().any(func(n): return n.get_script() == load("res://scripts/codex.gd")), "Codex did not open")
	for child in main.get_children():
		if child.get_script() == load("res://scripts/codex.gd"):
			child.closed.emit()
	await process_frame
	await click(selection.selectors[0])
	await click(selection.canvas.get_node("StartExpedition"))
	check(main.screen == "arrival", "Missing opening encounter")
	main.take_arrival_reward(0)
	main.finish_arrival()
	await process_frame
	await process_frame
	check(main.screen == "map", "Selection did not enter new map")
	check(main.hp == 72 and main.deck.size() == 10, "Run data changed")
	check(main.content.has_node("ExpeditionScroll/RouteMap"), "Remote map lost in merge")
	check(not main.has_node("CharacterSelection"), "Selection overlay leaked")
	print("HOME_MERGE_QA characters=4 failures=", failures.size())
	main.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

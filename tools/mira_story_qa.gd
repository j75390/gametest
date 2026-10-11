extends SceneTree
const Progress = preload("res://scripts/timeline.gd")

func _initialize(): run.call_deferred()

func click(button: Button) -> void:
	var point := button.get_global_rect().get_center()
	root.warp_mouse(point)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.global_position = point
		event.pressed = pressed
		root.push_input(event, true)
	await process_frame

func run() -> void:
	Progress.path = "user://mira_story_qa_%d.json" % Time.get_ticks_usec()
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	var flags := ["ward_plate", "ward_copy", "ward_left"]
	for dimensions in [Vector2i(1440,900), Vector2i(1280,720)]:
		root.size = dimensions
		for option in range(3):
			main.choose_character(main.characters[0])
			assert(main.story_flags.is_empty())
			assert("가면" in main.arrival_event.dialogue[0])
			main.take_arrival_reward(0)
			main.finish_arrival()
			var id: int = main.expedition.available()[0]
			main.expedition.nodes[id].type = "이벤트"
			main.enter_node(id)
			await process_frame
			assert(main.screen == "story_event" and main.story_event.id == "empty_ward")
			assert(main.arrival_view.actions.get_child_count() == 3)
			await create_timer(0.1).timeout
			assert(main.arrival_view.dialogue.position.y + main.arrival_view.dialogue.size.y < main.arrival_view.actions.position.y)
			if option == 0:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://docs/mira-ward-%d.png" % dimensions.x)
			await click(main.arrival_view.actions.get_child(option))
			assert(main.story_flags.has(flags[option]) and main.story_flags.size() == 3)
			main.take_story_choice((option + 1) % 3)
			assert(main.story_flags.size() == 3)
			assert(main.hp >= 72 and main.gold == 200 and main.deck.size() in [10, 11])  # the plate choice adds a side-effect card; the copy choice adds max HP
			# after a choice only the way back is offered; the story still reaches the investigation notes
			assert(main.arrival_view.actions.get_child_count() == 1)
			var notes: Dictionary = load("res://scripts/codex_data.gd").notes(main.story_flags)
			var found: Array = notes["이야기"].map(func(r): return str(r.id))
			assert(flags[option] in found)
			await click(main.arrival_view.actions.get_child(0))
			assert(main.screen == "map" and main.expedition.nodes[id].cleared)
			var next_id: int = main.expedition.available()[0]
			main.expedition.nodes[next_id].type = "이벤트"
			main.enter_node(next_id)
			assert(main.screen == "story_event" and (str(main.story_event.id).begins_with("common_act1_") or str(main.story_event.id) in ["mira_coat", "kalian_personal_1"]))
	main.choose_character(main.characters[1])
	assert(main.story_flags.is_empty())
	assert(not "가면" in main.arrival_event.dialogue[0])
	main.take_arrival_reward(0)
	main.finish_arrival()
	var id: int = main.expedition.available()[0]
	main.expedition.nodes[id].type = "이벤트"
	main.enter_node(id)
	assert(main.screen == "story_event" and (str(main.story_event.id).begins_with("common_act1_") or str(main.story_event.id) in ["mira_coat", "kalian_personal_1"]))
	main.queue_free()
	await process_frame
	for leftover in [Progress.path, Progress.path + ".bak", Progress.path + ".tmp"]:
		if FileAccess.file_exists(leftover): DirAccess.remove_absolute(leftover)
	print("MIRA_STORY_QA PASS: actual node entry, 3 exclusive choices, no duplicate, conditional codex, node resolved, reset, common events for other characters, 2 resolutions")
	quit()

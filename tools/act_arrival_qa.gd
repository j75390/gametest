extends SceneTree
func _initialize(): run.call_deferred()
func click(button: Button) -> void:
	var point := button.get_global_rect().get_center()
	root.warp_mouse(point)
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.global_position = point
		event.pressed = pressed
		root.push_input(event,true)
	await process_frame

func run() -> void:
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	for dimensions in [Vector2i(1440,900),Vector2i(1280,720)]:
		root.size = dimensions
		for reward in range(3):
			main.choose_character(main.characters[0])
			await process_frame
			assert(main.screen == "arrival")
			assert(main.deck.size() == 10 and main.gold == 120)
			var start_id = main.expedition.current_id
			main.finish_arrival()
			assert(main.screen == "arrival")
			main.show_map()
			assert(main.screen == "arrival")
			await process_frame
			await click(main.arrival_view.actions.get_child(0))
			assert(main.arrival_view.actions.get_child_count() == 3)
			await create_timer(0.15).timeout
			if reward == 0:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://docs/act-arrival-%d.png" % dimensions.x)
			var offered = main.arrival_card.id
			await click(main.arrival_view.actions.get_child(reward))
			assert(main.arrival_reward_taken)
			assert(main.gold == (200 if reward == 0 else 120))
			assert(main.max_hp == (78 if reward == 1 else 72))
			assert(main.hp == main.max_hp)
			assert(main.deck.size() == (11 if reward == 2 else 10))
			if reward == 2: assert(main.deck.back().id == offered)
			main.take_arrival_reward(reward)
			assert(main.gold <= 200 and main.max_hp <= 78 and main.deck.size() <= 11)
			assert(main.screen == "arrival")
			await click(main.arrival_view.actions.get_child(0))
			assert(main.screen == "map")
			assert(main.expedition.current_id == start_id)
			main.show_map()
			assert(main.screen == "map")
	main.show_event()
	assert(main.title.text == "뒤틀린 제단")
	main.choose_character(main.characters[0])
	assert(not main.arrival_reward_taken and main.gold == 120 and main.deck.size() == 10)
	main.queue_free()
	await process_frame
	print("ACT_ARRIVAL_QA PASS: two resolutions, dialogue, three rewards, once-only, map gate, reset, normal event")
	quit()

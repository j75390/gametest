extends SceneTree
func _initialize(): run.call_deferred()
func run():
	root.size = Vector2i(1440, 900)
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	main.choose_character(main.characters[0])
	main.take_arrival_reward(0)
	main.finish_arrival()
	main.show_story_event("common_act1_03")
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/story-event-text-preview.png")
	main.show_codex()
	var codex = main.get_node("Codex")
	codex._set_review_mode(true)
	codex._navigate("유물", "relic_ancient_001")
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/story-relic-text-preview.png")
	codex._navigate("지역", "nameless_archive")
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/story-region-text-preview.png")
	main.queue_free()
	await process_frame
	quit()

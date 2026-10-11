extends SceneTree
## Screenshots of two events with their new illustrations (docs/event-art-<id>-1440.png).
const D = preload("res://scripts/codex_discovery.gd")
func _initialize(): run.call_deferred()
func run():
	D.path = "user://event_art_shot_%d.json" % Time.get_ticks_usec()
	root.size = Vector2i(1440, 900)
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.choose_character(main.characters[0])
	main.take_arrival_reward(0)
	main.finish_arrival()
	for id in ["common_act1_08", "common_act1_15"]:
		main.show_story_event(id)
		await create_timer(0.5).timeout
		if main.content.has_method("finish_typing"): main.content.finish_typing()
		await create_timer(0.5).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/event-art-%s-1440.png" % id)
	print("EVENT_ART_SHOT done")
	quit(0)

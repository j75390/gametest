extends SceneTree
## Saves screenshots of the battle with a full potion belt and of the shop's potion shelf.
const D = preload("res://scripts/codex_discovery.gd")
func _initialize(): run.call_deferred()
func shot(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/%s.png" % name)
func run():
	D.path = "user://potion_shot_%d.json" % Time.get_ticks_usec()
	root.size = Vector2i(1440, 900)
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.choose_character(main.characters[0])
	main.take_arrival_reward(0)
	main.finish_arrival()
	main.start_battle("전투")
	main.potions = ["potion_text_02", "potion_text_05", "potion_text_04"]
	main.show_battle()
	await shot("potion-battle-1440")
	main._generate_map()
	main.expedition.current_id = 1
	main.show_shop()
	await shot("potion-shop-1440")
	print("POTION_SHOT_QA done")
	quit(0)

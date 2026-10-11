extends SceneTree
## Battle screenshots with the delivered monster art (docs/monster-art-<id>-1440.png).
const D = preload("res://scripts/codex_discovery.gd")
const Data = preload("res://scripts/game_data.gd")
func _initialize(): run.call_deferred()
func run():
	D.path = "user://monster_art_shot_%d.json" % Time.get_ticks_usec()
	root.size = Vector2i(1440, 900)
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.choose_character(main.characters[0])
	main.take_arrival_reward(0)
	main.finish_arrival()
	main.start_battle("전투")
	for id in ["waiting_patient", "ash_warden_boss", "shaft_keeper", "round_doll"]:
		main.enemy = Data.find_record("monsters", id)
		main.enemy_hp = int(main.enemy.hp)
		main.enemy_max_hp = main.enemy_hp
		main.show_battle()
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/monster-art-%s-1440.png" % id)
	print("MONSTER_ART_SHOT done")
	quit(0)

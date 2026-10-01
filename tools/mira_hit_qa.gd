extends SceneTree
var failures: Array[String] = []
func check(ok: bool, message: String):
	if not ok:
		failures.append(message)
		push_error(message)
func _initialize(): run.call_deferred()
func capture(file: String):
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/mira-hit-" + file + ".png")
func run():
	root.size = Vector2i(1440, 900)
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	main.choose_character(main.characters[0])
	main.start_battle("전투")
	main.enemy_hp = 100
	main.enemy_max_hp = 100
	main.hand = [main.card_db.common[0].duplicate(true)]
	main.energy = 3
	main.show_battle()
	await process_frame
	main.play_card(0)
	while not is_instance_valid(main.battle_fx): await process_frame
	check(main.enemy_hp == 100 and main.battle_busy, "Damage must wait for contact")
	var fx = main.battle_fx
	var hero = main.content.get_node("BattleStage/Hero")
	var home: Vector2 = hero.position
	main.end_turn()
	check(main.enemy_turn == 0, "Input locked during attack")
	while fx.phase != "impact": await process_frame
	check(main.enemy_hp == 94 and main.energy == 2, "One hit / one energy spend")
	check(hero.position.x > home.x + 100, "Attacker lunges toward target")
	await capture("impact")
	while main.battle_busy: await process_frame
	check(main.get_node_or_null("BattleFX") == null, "Effect layer cleaned up")
	check(main.content.get_node("BattleStage/Hero").scale == Vector2.ONE, "Actor scale restored")
	await capture("rest")
	main.block = 0
	main.end_turn()
	while not is_instance_valid(main.battle_fx): await process_frame
	check(main.hp == main.max_hp, "Enemy also waits for impact")
	fx = main.battle_fx
	while fx.phase != "impact": await process_frame
	check(main.hp < main.max_hp, "Enemy impact applies damage")
	await capture("hurt")
	while main.battle_busy: await process_frame
	main.enemy_hp = 1
	main.enemy_status.apply([{"id":"poison","amount":2}])
	var hp_before: int = main.hp
	var turn_before: int = main.enemy_turn
	await main.end_turn()
	check(main.screen == "reward" and main.hp == hp_before and main.enemy_turn == turn_before, "DOT kill skips enemy attack")
	main.start_battle("전투")
	main.hp = 1
	main.block = 0
	await main.end_turn()
	check(main.hp == 0 and not main.battle_busy and main.screen != "battle", "Lethal enemy hit completes death and unlocks")
	# New battle: resizing and repeated input must not duplicate hits or leave transforms behind.
	main.hp = main.max_hp
	main.start_battle("전투")
	main.enemy_hp = 200
	main.enemy_max_hp = 200
	main.hand = [main.card_db.common[0].duplicate(true)]
	main.energy = 3
	main.play_card(0)
	await create_timer(0.1).timeout
	root.size = Vector2i(1280, 720)
	main.play_card(0)
	main.end_turn()
	while main.battle_busy: await process_frame
	check(main.enemy_hp == 194 and main.energy == 2 and main.enemy_turn == 0, "Resize / repeated input applies once")
	check(main.content.get_node("BattleStage/Hero").scale == Vector2.ONE, "Resize restores pose")
	main.hand = [main.card_db.common[1].duplicate(true)]
	main.energy = 3
	await main.play_card(0)
	check(main.block == 5 and main.enemy_hp == 194, "Defense pulse does not hit enemy")
	main.block = 999
	var before_blocked_hp: int = main.hp
	await main.end_turn()
	check(main.hp == before_blocked_hp and main.block == 0, "Fully blocked hit and turn cleanup")
	root.size = Vector2i(1440, 900)
	print("MIRA_HIT_QA failures=%d" % failures.size())
	quit(0 if failures.is_empty() else 1)

extends SceneTree
## Every ACT II / ACT III monster is fought for several turns with random card play: its opener, phase moves, cleanse and side effects all resolve and the numbers stay sane.
const D = preload("res://scripts/codex_discovery.gd")
const T = preload("res://scripts/timeline.gd")
const Data = preload("res://scripts/game_data.gd")
var failures := 0
var rng := RandomNumberGenerator.new()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _initialize(): run.call_deferred()

func wait_idle(main, limit := 25.0) -> void:
	var waited := 0.0
	while main.battle_busy and waited < limit:
		await create_timer(0.1).timeout
		waited += 0.1

func run():
	var stamp: int = Time.get_ticks_usec()
	D.path = "user://actfight_dex_%d.json" % stamp
	T.path = "user://actfight_tl_%d.json" % stamp
	rng.seed = 20261012
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	Engine.time_scale = 12.0
	var fights := 0
	var phases_seen := 0
	for m in Data.read("monsters"):
		if int(m.act) < 2: continue
		main.choose_character(main.characters[0])
		main.take_arrival_reward(0)
		main.finish_arrival()
		main.current_act = int(m.act)
		main.start_battle("전투")
		main.enemy = Data.find_record("monsters", str(m.id))
		main.enemy_hp = int(main.enemy.hp)
		main.enemy_max_hp = main.enemy_hp
		main.enemy_block = 0
		main.enemy_turn = 0
		main.enemy_status.entries.clear()
		main.player_status.entries.clear()
		main.hp = main.max_hp
		main.show_battle()
		var turns := 0
		var seen_phase := false
		while main.screen == "battle" and turns < 9:
			turns += 1
			# halfway through, push a phase monster below its lines to see its later moves
			if turns == 4 and not m.get("phases", []).is_empty():
				main.enemy_hp = maxi(1, int(main.enemy_max_hp * 0.25))
				main.show_battle()
			var guard := 0
			while guard < 5 and main.screen == "battle" and not main.hand.is_empty():
				guard += 1
				var index := rng.randi_range(0, main.hand.size() - 1)
				if int(main.hand[index].cost) > main.energy: continue
				main.play_card(index)
				await wait_idle(main)
			if main.screen != "battle": break
			main.end_turn()
			await wait_idle(main)
			if main.screen == "game_over": break
			check(main.hp >= 0 and main.hp <= main.max_hp and main.block >= 0 and main.enemy_block >= 0 and main.enemy_hp >= 0 and main.enemy_hp <= main.enemy_max_hp, "%s turn %d: hp %d block %d enemy %d/%d" % [m.id, turns, main.hp, main.block, main.enemy_hp, main.enemy_max_hp])
			if main.screen == "battle" and not Data.find_record("monsters", str(m.id)).get("phases", []).is_empty():
				if preload("res://scripts/monster_actions.gd").phase_name(main.enemy, main.enemy_hp, main.enemy_max_hp) != "": seen_phase = true
		if seen_phase: phases_seen += 1
		fights += 1
	Engine.time_scale = 1.0
	check(phases_seen >= 4, "phase monsters reached a later phase (%d)" % phases_seen)
	print("ACT_FIGHTS_QA fights=%d phases=%d failures=%d" % [fights, phases_seen, failures])
	main.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)

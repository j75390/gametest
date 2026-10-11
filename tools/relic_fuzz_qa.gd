extends SceneTree
## Stress test: random relic loadouts play real battles (cards, end turn, rewards, rest, treasure) with
## animations sped up. Looks for script errors and impossible numbers (negative block, HP above max, ...).
const D = preload("res://scripts/codex_discovery.gd")
const T = preload("res://scripts/timeline.gd")
const Data = preload("res://scripts/game_data.gd")
var failures: Array[String] = []

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func _initialize(): run.call_deferred()

func sane(main, label: String) -> void:
	check(main.max_hp >= 1, "%s: max HP %d" % [label, main.max_hp])
	check(main.hp >= 0 and main.hp <= main.max_hp, "%s: HP %d/%d" % [label, main.hp, main.max_hp])
	check(main.block >= 0, "%s: block %d" % [label, main.block])
	check(main.energy >= 0, "%s: energy %d" % [label, main.energy])
	check(main.gold >= 0, "%s: gold %d" % [label, main.gold])
	check(main.hand.size() <= 15, "%s: hand %d" % [label, main.hand.size()])

func wait_idle(main, limit := 20.0) -> void:
	var waited := 0.0
	while main.battle_busy and waited < limit:
		await create_timer(0.1).timeout
		waited += 0.1

func run():
	var stamp: int = Time.get_ticks_usec()
	D.path = "user://fuzz_dex_%d.json" % stamp
	T.path = "user://fuzz_tl_%d.json" % stamp
	Engine.time_scale = 12.0
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var ids: Array = Data.read("relics").filter(func(r): return str(r.get("starter_character", "")).is_empty() and r.get("rarity", "") != "고대").map(func(r): return str(r.id))
	check(ids.size() >= 60, "Many live relics to draw from: %d" % ids.size())
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261009
	var battles := 0
	for round_index in 2:
		var character = main.characters[round_index % 2]
		main.choose_character(character)
		ids.shuffle()
		var loadout: Array = ids.slice(0, 12)
		for id in loadout: main.grant_relic(id)
		main.max_hp = maxi(main.max_hp, 40)
		main.hp = main.max_hp
		for kind in ["전투", "엘리트", "보스"]:
			main.start_battle(kind)
			sane(main, "start %s round %d" % [kind, round_index])
			var turns := 0
			while main.screen == "battle" and turns < 14:
				turns += 1
				var guard := 0
				while guard < 6 and main.screen == "battle" and not main.hand.is_empty():
					guard += 1
					var index := rng.randi_range(0, main.hand.size() - 1)
					if int(main.hand[index].cost) > main.energy: continue
					main.play_card(index)
					await wait_idle(main)
				sane(main, "after cards %s round %d turn %d" % [kind, round_index, turns])
				if main.screen != "battle": break
				main.end_turn()
				await wait_idle(main)
				if main.screen == "game_over": break
				sane(main, "after end turn %s round %d turn %d" % [kind, round_index, turns])
			battles += 1
			if main.screen == "game_over":
				break
			if main.screen == "reward":
				main.show_reward()
				await process_frame
			main.hp = main.max_hp
	# other room types with a heavy loadout
	main.choose_character(main.characters[0])
	for id in ids.slice(0, 25): main.grant_relic(id)
	main.show_rest()
	await process_frame
	main.show_treasure()
	await process_frame
	main.expedition.current_id = 1
	main._generate_map()
	main.show_shop()
	await process_frame
	sane(main, "rooms")
	Engine.time_scale = 1.0
	for file in [D.path, T.path, T.path + ".bak", T.path + ".tmp"]:
		if FileAccess.file_exists(file): DirAccess.remove_absolute(file)
	print("RELIC_FUZZ_QA battles=%d failures=%d" % [battles, failures.size()])
	quit(1 if failures.size() > 0 else 0)

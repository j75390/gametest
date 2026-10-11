extends SceneTree
## Monsters: data shape, every move type (block, heal, buff, multi-hit, debuffs), weakness and vulnerability,
## random picking, and a full fight against each monster with sane numbers all the way.
const D = preload("res://scripts/codex_discovery.gd")
const T = preload("res://scripts/timeline.gd")
const Data = preload("res://scripts/game_data.gd")
const Actions = preload("res://scripts/monster_actions.gd")
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _initialize(): run.call_deferred()

func force_enemy(main, id: String) -> void:
	main.enemy = Data.find_record("monsters", id)
	main.enemy_hp = int(main.enemy.hp)
	main.enemy_max_hp = main.enemy_hp
	main.enemy_block = 0
	main.enemy_turn = 0
	main.enemy_status.entries.clear()
	main.player_status.entries.clear()
	main.block = 0

func fresh(main, kind := "전투") -> void:
	main.choose_character(main.characters[0])
	main.take_arrival_reward(0)
	main.finish_arrival()
	main.start_battle(kind)

func wait_idle(main, limit := 25.0) -> void:
	var waited := 0.0
	while main.battle_busy and waited < limit:
		await create_timer(0.1).timeout
		waited += 0.1

func run():
	var stamp: int = Time.get_ticks_usec()
	D.path = "user://monster_dex_%d.json" % stamp
	T.path = "user://monster_tl_%d.json" % stamp
	# --- data ---
	var monsters: Array = Data.read("monsters")
	var by_rank := {}
	var signatures := {}
	for m in monsters:
		by_rank[m.type] = int(by_rank.get(m.type, 0)) + 1
		check(int(m.hp) > 0 and not m.pattern.is_empty() and ResourceLoader.exists(str(m.art)), "%s has HP, a pattern and a picture" % m.id)
		for action in m.pattern:
			check(str(action.get("name", "")) != "" and Actions.kind(action) != "unknown" or action.get("rest", false), "%s: %s does something" % [m.id, action.get("name", "?")])
			for item in action.get("buff", []) + action.get("apply_statuses", []):
				check(not Data.find_record("powers", str(item.id)).is_empty(), "%s uses a known status: %s" % [m.id, item.id])
		signatures[JSON.stringify(m.pattern)] = true
	check(monsters.size() >= 13 and int(by_rank.get("일반", 0)) >= 6 and int(by_rank.get("엘리트", 0)) >= 3 and int(by_rank.get("보스", 0)) >= 1, "Monster roster by rank: %s" % str(by_rank))
	check(signatures.size() == monsters.size(), "Every monster has its own pattern")
	var kinds := {}
	for m in monsters:
		for action in m.pattern: kinds[Actions.kind(action)] = true
	check(kinds.has("attack") and kinds.has("defend") and kinds.has("buff") and kinds.has("debuff"), "Roster uses attack, defend, buff and debuff moves: %s" % str(kinds.keys()))
	check(Actions.text({"damage": 4, "hits": 3}).begins_with("피해 4×3") and Actions.text({"rest": true}).contains("아무것도"), "Move text reads naturally")
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	fresh(main)
	var strike: Dictionary = main.card_db.common[0]
	# --- picking ---
	for kind in ["전투", "엘리트", "보스"]:
		var seen := {}
		var previous := ""
		var repeats := 0
		for i in 300:
			var picked: Dictionary = main.pick_enemy(kind)
			seen[picked.id] = true
			if picked.id == previous: repeats += 1
			previous = picked.id
		var pool: Array = monsters.filter(func(m): return m.type == {"전투": "일반", "엘리트": "엘리트", "보스": "보스"}[kind] and int(m.act) == main.current_act)
		check(seen.size() == pool.size(), "%s: every monster of the rank turns up (%d of %d)" % [kind, seen.size(), pool.size()])
		check(repeats == 0 or pool.size() == 1, "%s: never the same monster twice in a row (%d repeats)" % [kind, repeats])
	# --- block: the enemy's own, soaked by the player's attacks ---
	force_enemy(main, "lamp_pilgrim")
	var plan: Dictionary = main.enemy_prepare(main.enemy.pattern[0])
	check(main.enemy_block == 10 and plan.hits == 0, "Block move gives 10 block and no hit")
	var dealt: int = main._card_effect(strike.duplicate(true))
	check(dealt == 0 and main.enemy_hp == main.enemy.hp and main.enemy_block == 10 - 6, "A 6-damage attack is soaked by 10 block: dealt %d, block left %d" % [dealt, main.enemy_block])
	dealt = main._card_effect(strike.duplicate(true))
	check(dealt == 2 and main.enemy_block == 0, "The next attack breaks through: dealt %d" % dealt)
	main.enemy_hp = 20
	main.enemy_prepare(main.enemy.pattern[2])
	check(main.enemy_hp == 26 and main.enemy_block == 5, "Prayer heals 6 and blocks 5: hp %d" % main.enemy_hp)
	main.enemy_hp = main.enemy_max_hp - 2
	main.enemy_prepare({"heal": 9})
	check(main.enemy_hp == main.enemy_max_hp and main.enemy_block == 0, "Healing stops at max HP and block is cleared by a new move")
	# --- buffs and multi-hit ---
	force_enemy(main, "recovery_agent")
	var hits: Dictionary = main.enemy_prepare(main.enemy.pattern[0])
	check(hits.hits == 3 and hits.per_hit == 4, "Three hits of four: %s" % str(hits))
	main.enemy_prepare(main.enemy.pattern[1])
	check(main.enemy_status.amount("strength") == 2, "Strength +2 is kept")
	hits = main.enemy_prepare(main.enemy.pattern[0])
	check(hits.per_hit == 6, "Strength raises every hit: %d" % hits.per_hit)
	main.block = 7
	var first: int = main.enemy_hit_player(6)
	var second: int = main.enemy_hit_player(6)
	check(first == 0 and second == 5 and main.block == 0, "Block soaks across several hits: %d then %d" % [first, second])
	# --- weakness and vulnerability on the player ---
	force_enemy(main, "round_doll")
	main.player_status.apply([{"id": "weak", "amount": 1}])
	var normal_damage := 6
	check(main._card_effect(strike.duplicate(true)) == floori(normal_damage * 0.75), "Weak cuts the player's attack by a quarter")
	main.player_status.entries.clear()
	main.player_status.apply([{"id": "vulnerable", "amount": 1}])
	check(main.enemy_hit_value({"damage": 10}) == 15, "Vulnerable raises incoming hits by half")
	main.enemy_finish({"damage": 10})
	check(main.player_status.amount("vulnerable") == 0, "Vulnerable runs down after the enemy's move")
	var notes: Array = main.enemy_finish(main.enemy.pattern[0])
	check(main.player_status.amount("weak") == 1 and notes.size() == 1, "Doll's bandage weakens the player")
	main.player_status.apply([{"id": "vulnerable", "amount": 1}])
	main.enemy_finish(main.enemy.pattern[0])
	check(main.player_status.amount("vulnerable") == 0 and main.player_status.amount("weak") == 2, "A new debuff arrives after the old one ran down")
	# --- weakness runs down when the player ends a turn ---
	fresh(main)
	force_enemy(main, "convoy_armor")
	main.player_status.apply([{"id": "weak", "amount": 2}])
	main.show_battle()
	main.end_turn()
	await wait_idle(main)
	check(main.player_status.amount("weak") == 1, "Weak lasts the stated number of turns: %d" % main.player_status.amount("weak"))
	# --- the intent shows more than damage ---
	fresh(main)
	force_enemy(main, "seal_clerk")
	main.enemy_turn = 1
	main.show_battle()
	await process_frame
	var intent = main.content.get_node("Intent")
	check(intent.get_node("IntentValue").text == "5×2", "Multi-hit intent reads 5×2: %s" % intent.get_node("IntentValue").text)
	main.enemy_turn = 2
	main.show_battle()
	await process_frame
	intent = main.content.get_node("Intent")
	check(intent.get_node("IntentValue").text == "7" and intent.has_node("IntentExtra_buff"), "Attack-and-buff intent shows the damage and a buff icon")
	check(intent.tooltip_text.contains("힘 1"), "Intent tooltip spells out the buff: %s" % intent.tooltip_text)
	main.enemy_turn = 0
	main.show_battle()
	await process_frame
	check(main.content.get_node("Intent").has_node("IntentIcon") and not main.content.get_node("Intent").has_node("IntentValue"), "A pure debuff shows no damage number")
	# --- a whole fight against every monster, for two different heroes ---
	Engine.time_scale = 12.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261010
	var fights := 0
	for who in [0, 1]:
		var second_hero_seen := {}
		var later_act_seen := {}
		for m in monsters:
			# ACT II/III monsters are covered by act2_qa / act3_qa; here one per act and rank keeps the run short
			if int(m.act) >= 2:
				var key := "%d_%s" % [int(m.act), str(m.type)]
				if later_act_seen.has(key): continue
				later_act_seen[key] = true
			# the second hero fights one monster per rank, to keep the run short
			if who == 1:
				if second_hero_seen.has(m.type): continue
				second_hero_seen[m.type] = true
			main.choose_character(main.characters[who])
			main.take_arrival_reward(0)
			main.finish_arrival()
			main.start_battle("전투")
			force_enemy(main, str(m.id))
			main.enemy_status.apply(m.get("powers", []))
			main.hp = main.max_hp
			main.show_battle()
			var turns := 0
			while main.screen == "battle" and turns < 14:
				turns += 1
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
				check(main.hp >= 0 and main.hp <= main.max_hp and main.block >= 0 and main.enemy_block >= 0 and main.enemy_hp >= 0 and main.enemy_hp <= main.enemy_max_hp, "%s turn %d: hp %d block %d enemy %d/%d block %d" % [m.id, turns, main.hp, main.block, main.enemy_hp, main.enemy_max_hp, main.enemy_block])
			fights += 1
	Engine.time_scale = 1.0
	for file in [D.path, T.path, T.path + ".bak", T.path + ".tmp"]:
		if FileAccess.file_exists(file): DirAccess.remove_absolute(file)
	print("MONSTER_QA fights=%d failures=%d" % [fights, failures])
	quit(1 if failures > 0 else 0)

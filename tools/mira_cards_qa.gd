extends SceneTree
## Mira's card pool: data shape, every new card effect, enemy weak/vulnerable, exhaust and powers,
## random weighted rewards, and full fights with random hands.
const D = preload("res://scripts/codex_discovery.gd")
const T = preload("res://scripts/timeline.gd")
const Data = preload("res://scripts/game_data.gd")
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _initialize(): run.call_deferred()

func card(main, id: String, upgraded := false) -> Dictionary:
	for c in main.card_db.mira:
		if c.id == id:
			return Data.upgraded(c) if upgraded else c.duplicate(true)
	push_error("No such card: " + id)
	return {}

func fresh(main) -> void:
	main.choose_character(main.characters[0])
	main.take_arrival_reward(0)
	main.finish_arrival()
	main.start_battle("전투")
	main.enemy = Data.find_record("monsters", "ash_warden")
	main.enemy_hp = int(main.enemy.hp)
	main.enemy_max_hp = main.enemy_hp
	main.enemy_block = 0
	main.enemy_status.entries.clear()
	main.player_status.entries.clear()
	main.block = 0
	main.energy = 3
	main.potions.clear()
	main.hand.clear()
	main.hp = main.max_hp

func wait_idle(main, limit := 25.0) -> void:
	var waited := 0.0
	while main.battle_busy and waited < limit:
		await create_timer(0.1).timeout
		waited += 0.1

func run():
	var stamp: int = Time.get_ticks_usec()
	D.path = "user://mira_cards_dex_%d.json" % stamp
	T.path = "user://mira_cards_tl_%d.json" % stamp
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	fresh(main)
	# --- data ---
	var pool: Array = main.card_db.mira
	var by_rarity := {}
	var by_type := {}
	for c in pool:
		by_rarity[c.rarity] = int(by_rarity.get(c.rarity, 0)) + 1
		by_type[c.type] = int(by_type.get(c.type, 0)) + 1
		check(ResourceLoader.exists(str(c.art)) and not str(c.get("text", "")).is_empty() and c.text != "효과 없음", "%s has art and readable text: %s" % [c.id, c.get("text", "")])
		check(c.get("upgrade", {}).size() > 0, "%s has an upgrade" % c.id)
		if c.type == "파워":
			check(not Data.find_record("powers", str(c.power.id)).is_empty(), "%s uses a known power" % c.id)
	check(pool.size() >= 40 and int(by_rarity.get("일반", 0)) >= 15 and int(by_rarity.get("희귀", 0)) >= 9 and int(by_rarity.get("영웅", 0)) >= 1 and int(by_type.get("파워", 0)) >= 6, "Pool: %s %s" % [str(by_rarity), str(by_type)])
	# --- plain effects ---
	fresh(main)
	var enemy_hp: int = main.enemy_hp
	main._card_effect(card(main, "vial_throw"))
	check(main.enemy_hp == enemy_hp - 5 and main.enemy_status.amount("poison") == 2, "Vial: 5 damage + 2 poison")
	main._card_effect(card(main, "vial_throw", true))
	check(main.enemy_status.amount("poison") == 5, "Upgraded vial gives 3 poison")
	# poison multiply and burst
	main._card_effect(card(main, "concentrate"))
	check(main.enemy_status.amount("poison") == 10, "Concentrate doubles poison: %d" % main.enemy_status.amount("poison"))
	enemy_hp = main.enemy_hp
	var dealt: int = main._card_effect(card(main, "flowering_toxin"))
	check(main.enemy_hp == enemy_hp - 10 and dealt == 10 and main.enemy_status.amount("poison") == 10, "Flowering toxin deals the poison and keeps it: hp -%d" % (enemy_hp - main.enemy_hp))
	# burst ignores block
	main.enemy_block = 50
	enemy_hp = main.enemy_hp
	main._card_effect(card(main, "flowering_toxin"))
	check(main.enemy_hp == enemy_hp - 10 and main.enemy_block == 50, "Burst ignores enemy block")
	# venom
	fresh(main)
	main._card_effect(card(main, "lingering_flask"))
	check(main.venom_turns == 2 and main.block == 5, "Flask starts 2 venom turns and gives 5 block")
	main._card_effect(card(main, "lingering_flask"))
	check(main.venom_turns == 4, "Flask extends venom: %d" % main.venom_turns)
	# weak / vulnerable on the enemy
	fresh(main)
	main._card_effect(card(main, "fume_cloud"))
	check(main.enemy_status.amount("weak") == 2 and main.enemy_status.amount("vulnerable") == 2 and main.block == 6, "Fume cloud: weak 2, vulnerable 2, block 6")
	enemy_hp = main.enemy_hp
	main._card_effect(main.card_db.common[0].duplicate(true))
	check(main.enemy_hp == enemy_hp - 9, "Vulnerable enemy takes half again: strike 6 -> %d" % (enemy_hp - main.enemy_hp))
	var weak_hit: int = main.enemy_hit_value({"damage": 12})
	check(weak_hit == 9, "Weak enemy hits for three quarters: %d" % weak_hit)
	main.enemy_finish({"damage": 12})
	check(main.enemy_status.amount("weak") == 1 and main.enemy_status.amount("vulnerable") == 1, "Enemy debuffs run down after its move")
	# draw, energy, hp cost
	fresh(main)
	main.draw_pile = [main.card_db.common[0].duplicate(true), main.card_db.common[0].duplicate(true), main.card_db.common[0].duplicate(true)]
	main._card_effect(card(main, "antiseptic"))
	check(main.block == 6 and main.hand.size() == 1, "Antiseptic: block 6 and draw 1")
	main.hp = 50
	main._card_effect(card(main, "blood_for_medicine"))
	check(main.hp == 44 and main.energy == 5 and main.hand.size() == 2, "Blood for medicine: -6 HP, +2 energy, +1 card (hp %d energy %d)" % [main.hp, main.energy])
	main.hp = 3
	main.hand = [card(main, "pain_transfer")]
	main.energy = 3
	main.battle_busy = false
	var before_enemy: int = main.enemy_hp
	main.play_card(0)
	await process_frame
	check(main.hand.size() == 1 and main.enemy_hp == before_enemy and main.hp == 3, "A card costing more HP than you have cannot be played")
	main.hp = 10
	main.play_card(0)
	await wait_idle(main)
	check(main.hp == 6 and main.enemy_hp == before_enemy - 14, "Pain transfer: -4 HP, 14 damage (hp %d)" % main.hp)
	# potions: brew, drink, per potion
	fresh(main)
	main._card_effect(card(main, "distill"))
	check(main.potions.size() == 1, "Distill brews a potion")
	main.potions = ["potion_text_01", "potion_text_01", "potion_text_01"]
	main._card_effect(card(main, "distill"))
	check(main.potions.size() == 3, "No brewing on a full belt")
	enemy_hp = main.enemy_hp
	main._card_effect(card(main, "flask_barrage"))
	check(main.enemy_hp == enemy_hp - (6 + 15), "Flask barrage counts the belt: %d" % (enemy_hp - main.enemy_hp))
	main.potions = ["potion_text_06", "potion_text_01"]
	main.block = 0
	main._card_effect(card(main, "quick_mix"))
	check(main.potions == ["potion_text_01"] and main.block == 12, "Quick mix drinks the first potion")
	main.potions.clear()
	main._card_effect(card(main, "quick_mix"))
	check(main.potions.is_empty(), "Quick mix with an empty belt does nothing")
	# --- exhaust and powers through play_card ---
	fresh(main)
	main.hand = [card(main, "distill"), card(main, "corrosive_vapor")]
	main.play_card(0)
	await wait_idle(main)
	check(main.exhaust_pile.size() == 1 and main.discard_pile.is_empty(), "Exhausted card leaves the cycle")
	main.energy = 3
	main.play_card(0)
	await wait_idle(main)
	check(main.exhaust_pile.size() == 2 and main.player_status.amount("toxic_vapor") == 1, "A power is kept in play and removed from the deck cycle")
	main.hand = [card(main, "weakening_draught")]
	main.energy = 3
	main.play_card(0)
	await wait_idle(main)
	check(main.enemy_status.amount("poison") == 1, "Corrosive vapor adds 1 poison to a skill")
	# turn-start powers
	fresh(main)
	main.player_status.apply([{"id": "slow_steep", "amount": 1}, {"id": "brewing_bench", "amount": 1}])
	main._turn_start_powers()
	check(main.venom_turns == 1 and main.potions.size() == 1, "Turn-start powers: venom +1, one potion")
	main._turn_start_powers()
	check(main.venom_turns == 2 and main.potions.size() == 2, "...and again next turn")
	# --- wave 2: bonus conditions, counter, barrier, retain / ethereal, X cost, pain, conjure, transmute, echo, side effects ---
	fresh(main)
	enemy_hp = main.enemy_hp
	main._card_effect(card(main, "tainted_blade"))
	check(main.enemy_hp == enemy_hp - 6, "Tainted blade: no bonus on a clean enemy")
	main.enemy_status.set_amount("poison", 2)
	enemy_hp = main.enemy_hp
	main._card_effect(card(main, "tainted_blade"))
	check(main.enemy_hp == enemy_hp - 10, "Tainted blade: +4 on a poisoned enemy: %d" % (enemy_hp - main.enemy_hp))
	fresh(main)
	main._card_effect(card(main, "weak_point_injection"))
	check(main.enemy_status.amount("poison") == 0, "Injection without vulnerable: no poison")
	main.enemy_status.set_amount("vulnerable", 1)
	main._card_effect(card(main, "weak_point_injection"))
	check(main.enemy_status.amount("poison") == 5, "Injection on a vulnerable enemy: 5 poison: %d" % main.enemy_status.amount("poison"))
	# combo: counts cards played earlier this turn
	fresh(main)
	enemy_hp = main.enemy_hp
	main._card_effect(card(main, "chain_reaction"))
	check(enemy_hp - main.enemy_hp == 5, "Chain reaction alone: 5")
	main._card_effect(card(main, "chain_reaction"))
	check(enemy_hp - main.enemy_hp == 10, "Second card of the turn: still 5 (one earlier card)")
	enemy_hp = main.enemy_hp
	main._card_effect(card(main, "chain_reaction"))
	check(enemy_hp - main.enemy_hp == 13, "Third card: bonus +8 -> 13: %d" % (enemy_hp - main.enemy_hp))
	# counter hits back per enemy hit and ends with the enemy move
	fresh(main)
	main._card_effect(card(main, "thorn_salve"))
	check(main.block == 5 and main.player_status.amount("counter") == 3, "Thorn salve: block 5, counter 3")
	enemy_hp = main.enemy_hp
	main.enemy_hit_player(4)
	main.enemy_hit_player(4)
	check(main.enemy_hp == enemy_hp - 6, "Counter hits back on every hit: %d" % (enemy_hp - main.enemy_hp))
	main.enemy_finish({"damage": 4})
	check(main.player_status.amount("counter") == 0, "Counter ends with the enemy move")
	# barrier takes damage after block and persists
	fresh(main)
	main._card_effect(card(main, "glass_veil"))
	main.block = 3
	var lost: int = main.enemy_hit_player(6)
	check(lost == 0 and main.block == 0 and main.player_status.amount("barrier") == 5, "Barrier soaks after block: lost %d, barrier %d" % [lost, main.player_status.amount("barrier")])
	lost = main.enemy_hit_player(9)
	check(lost == 4 and main.player_status.amount("barrier") == 0, "Broken barrier lets the rest through: %d" % lost)
	# retain and ethereal through end_turn
	fresh(main)
	main.hand = [card(main, "warm_decoction"), card(main, "hasty_remedy"), main.card_db.common[0].duplicate(true)]
	main.draw_pile = []
	for i in 6: main.draw_pile.append(main.card_db.common[0].duplicate(true))
	main.end_turn()
	await wait_idle(main)
	var kept_ids: Array = main.hand.map(func(c): return c.id)
	check(kept_ids.has("warm_decoction") and not kept_ids.has("hasty_remedy"), "Retained card stays, ethereal is gone: %s" % str(kept_ids))
	check(main.exhaust_pile.any(func(c): return c.id == "hasty_remedy"), "Ethereal card was exhausted")
	check(main.hand.size() <= 10, "Hand never exceeds ten")
	# X cost: spends all energy
	fresh(main)
	main.hand = [card(main, "overdose")]
	main.energy = 3
	main.play_card(0)
	await wait_idle(main)
	check(main.energy == 0 and main.enemy_status.amount("poison") == 12, "Overdose spends 3 energy for 12 poison: poison %d" % main.enemy_status.amount("poison"))
	fresh(main)
	main.hand = [card(main, "overdose", true)]
	main.energy = 2
	main.play_card(0)
	await wait_idle(main)
	check(main.enemy_status.amount("poison") == 10, "Upgraded overdose: 2 energy x 5")
	# pain: damage from lost HP, ledger and mirror
	fresh(main)
	main.lose_hp(7)
	check(main.pain_battle == 7, "Lost HP is tracked: %d" % main.pain_battle)
	enemy_hp = main.enemy_hp
	main._card_effect(card(main, "accumulated_pain"))
	check(enemy_hp - main.enemy_hp == 11, "Accumulated pain: 4 + 7 = 11: %d" % (enemy_hp - main.enemy_hp))
	main.player_status.apply([{"id": "pain_ledger", "amount": 3}])
	enemy_hp = main.enemy_hp
	main.lose_hp(5)
	check(enemy_hp - main.enemy_hp == 3, "Pain ledger: 3 damage per loss")
	main.player_status.apply([{"id": "pain_mirror", "amount": 1}])
	enemy_hp = main.enemy_hp
	main.lose_hp(5)
	check(enemy_hp - main.enemy_hp == 3 + 5, "Pain mirror: the lost HP too: %d" % (enemy_hp - main.enemy_hp))
	# conjure, transmute, echo
	fresh(main)
	main.hand.clear()
	main._card_effect(card(main, "rapid_brew"))
	check(main.hand.size() == 1 and int(main.hand[0].cost) == 0 and main.hand[0].exhaust and main.hand[0].type == "스킬", "Rapid brew conjures a free exhausting skill")
	main.hand = [main.card_db.common[0].duplicate(true), main.card_db.common[0].duplicate(true)]
	main.draw_pile = [main.card_db.common[0].duplicate(true), main.card_db.common[0].duplicate(true)]
	main._card_effect(card(main, "masked_whisper"))
	var changed := 0
	for c in main.hand:
		if c.id != "strike": changed += 1
	check(changed == 1 and main.hand.size() == 3, "Masked whisper changes exactly one card and draws one: changed %d, hand %d" % [changed, main.hand.size()])
	fresh(main)
	main.hand = [card(main, "echo_dose")]
	main.last_played = {}
	main.play_card(0)
	await wait_idle(main)
	check(main.hand.is_empty(), "Echo with nothing played before does nothing")
	main.last_played = card(main, "glass_veil")
	main.hand = [card(main, "echo_dose")]
	main.energy = 3
	main.play_card(0)
	await wait_idle(main)
	check(main.hand.size() == 1 and main.hand[0].id == "glass_veil" and int(main.hand[0].cost) == 0 and main.hand[0].exhaust, "Echo copies the last card for free")
	# side effects: junk card, cannot be played, purged for energy, power adds one each turn
	fresh(main)
	main._card_effect(card(main, "bitter_dose"))
	check(main.discard_pile.filter(func(c): return c.id == "side_effect").size() == 1 and main.enemy_status.amount("poison") == 7, "Bitter dose: 7 poison and a side effect")
	main.hand = [main.SIDE_EFFECT_CARD.duplicate(true)]
	main.energy = 3
	main.play_card(0)
	check(main.hand.size() == 1 and main.energy == 3, "A side effect cannot be played")
	main.hand = [main.SIDE_EFFECT_CARD.duplicate(true), main.SIDE_EFFECT_CARD.duplicate(true), main.card_db.common[0].duplicate(true)]
	main.energy = 1
	main._card_effect(card(main, "purification"))
	check(main.energy == 3 and main.hand.size() == 1 and main.exhaust_pile.size() == 2, "Purification: two junk cards for two energy")
	fresh(main)
	main.player_status.apply([{"id": "ether_cycle", "amount": 1}])
	main.energy = 3
	main._turn_start_powers()
	check(main.energy == 4 and main.discard_pile.any(func(c): return c.id == "side_effect"), "Ether cycle: +1 energy and a side effect")
	# drink all
	fresh(main)
	main.potions = ["potion_text_06", "potion_text_06", "potion_text_01"]
	main.hp = 40
	main.block = 0
	enemy_hp = main.enemy_hp
	main._card_effect(card(main, "chemical_burst"))
	check(main.potions.is_empty() and main.block == 24 and main.hp == 48 and main.enemy_hp == enemy_hp - 8, "Chemical burst drinks all three potions: block %d hp %d" % [main.block, main.hp])
	# plague onset on top of concentrate
	fresh(main)
	main.enemy_status.set_amount("poison", 4)
	main._card_effect(card(main, "concentrate"))
	main._card_effect(card(main, "plague_onset"))
	check(main.enemy_status.amount("poison") == 24, "Poison x2 then x3: %d" % main.enemy_status.amount("poison"))
	# --- random weighted rewards ---
	fresh(main)
	var seen := {}
	var duplicates := 0
	for i in 400:
		var rolled: Array = main.roll_reward_cards()
		var ids := {}
		for c in rolled:
			seen[c.id] = true
			if ids.has(c.id): duplicates += 1
			ids[c.id] = true
		check(rolled.size() == 3, "Three cards are offered")
	check(seen.size() >= 18 and duplicates == 0, "Rewards vary and never repeat a card: %d different, %d duplicates" % [seen.size(), duplicates])
	var commons := 0
	var total := 0
	for i in 300:
		for c in main.roll_reward_cards():
			total += 1
			if c.rarity == "일반": commons += 1
	check(commons > total * 0.35 and commons < total * 0.8, "Commons dominate rewards: %d of %d" % [commons, total])
	# --- full fights with random hands of the new cards ---
	Engine.time_scale = 12.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261011
	var fights := 0
	for m in ["ash_warden", "round_doll", "convoy_captain", "ash_warden_boss"]:
		fresh(main)
		main.enemy = Data.find_record("monsters", m)
		main.enemy_hp = int(main.enemy.hp)
		main.enemy_max_hp = main.enemy_hp
		main.deck.clear()
		for c in main.card_db.mira:
			main.deck.append(c.duplicate(true))
			main.deck.append(main.card_db.common[0].duplicate(true))
		main.draw_pile = main.deck.duplicate(true)
		main.draw_pile.shuffle()
		main.discard_pile.clear()
		main.hand.clear()
		main._draw_cards(5)
		main.hp = main.max_hp
		main.show_battle()
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
			if main.screen != "battle": break
			main.end_turn()
			await wait_idle(main)
			if main.screen == "game_over": break
			check(main.hp >= 0 and main.hp <= main.max_hp and main.block >= 0 and main.enemy_hp >= 0 and main.potions.size() <= main.POTION_SLOTS, "%s turn %d: hp %d block %d enemy %d potions %d" % [m, turns, main.hp, main.block, main.enemy_hp, main.potions.size()])
		fights += 1
	Engine.time_scale = 1.0
	for file in [D.path, T.path, T.path + ".bak", T.path + ".tmp"]:
		if FileAccess.file_exists(file): DirAccess.remove_absolute(file)
	print("MIRA_CARDS_QA cards=%d fights=%d failures=%d" % [pool.size(), fights, failures])
	quit(1 if failures > 0 else 0)

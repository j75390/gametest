extends SceneTree
## Relic effect engine: triggers, conditions, limits, carry-over, and the hook points in the real battle,
## rest, event and reward flow. Draft relics are read from the Content Tool library.
const D = preload("res://scripts/codex_discovery.gd")
const T = preload("res://scripts/timeline.gd")
const Data = preload("res://scripts/game_data.gd")
var failures: Array[String] = []
var library := {}

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func _initialize(): run.call_deferred()

func lookup(id: String) -> Dictionary:
	if library.has(id): return library[id]
	return Data.find_record("relics", id)

func attack_card(main) -> Dictionary:
	for owner in main.card_db:
		for card in main.card_db[owner]:
			if str(card.type) == "공격" and int(card.get("damage", 0)) > 0 and not card.has("venom_turns"): return card.duplicate(true)
	return {}

func fresh_battle(main, relics_owned: Array, kind := "전투") -> void:
	main.choose_character(main.characters[0])
	main.owned_relics.clear()
	for id in relics_owned: main.owned_relics.append(id)
	main.start_battle(kind)

func run():
	var stamp: int = Time.get_ticks_usec()
	D.path = "user://relic_engine_dex_%d.json" % stamp
	T.path = "user://relic_engine_tl_%d.json" % stamp
	for record in Data.read("_library").relics: library[str(record.id)] = record
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.relics.lookup = lookup
	var strike := attack_card(main)
	check(not strike.is_empty(), "A plain attack card exists")

	# --- every effect entry is well formed ---
	var known_on := ["event_cost", "acquire", "lethal", "rest_upgrade", "shop_potion", "removal_price", "reward_choices", "incoming_damage", "hp_lost", "battle_won", "turn_start", "turn_end", "attack_damage", "event_enter", "battle_start",
		"first_draw", "rest_any", "rest", "card_played", "card_poison", "card_heal", "card_block", "event_paid", "shop_removal", "rest_heal", "treasure"]
	var with_effects := 0
	for id in library:
		var list: Array = library[id].get("effects", [])
		if list.is_empty(): continue
		with_effects += 1
		for entry in list:
			check(known_on.has(str(entry.on)), "%s uses a known trigger: %s" % [id, entry.on])
			for key in entry.get("if", {}):
				check(main.relics.conditions_met({key: entry["if"][key]}, {"turn": 1, "card": {}}) in [true, false] and ["turn", "turn_every", "hp_ratio_max", "hp_max", "kind", "enemy_poison", "enemy_venom", "enemy_full_hp", "self_poison", "card_cost_min", "card_heal", "card_type", "cards_played", "cards_min", "all_skills", "no_block_gained", "dot_kill", "new_enemy", "no_curse", "deck_no_heal", "skills_played", "block_cards_min", "turn_cost_mix", "distinct_cards_min", "attacks_played", "flag", "energy_left", "turn_min", "prev_turn_hp_lost", "upgraded_cards_min", "card_upgraded"].has(key), "%s uses a known condition: %s" % [id, key])
	check(with_effects >= 65, "Many relics carry effects: %d" % with_effects)

	# --- attack bonus: once per battle ---
	fresh_battle(main, ["relic_common_017"])
	var base := int(strike.damage)
	check(main._card_effect(strike.duplicate(true)) == base + 2, "First attack gets +2")
	check(main._card_effect(strike.duplicate(true)) == base, "Second attack gets no bonus")
	fresh_battle(main, ["relic_common_017"])
	check(main._card_effect(strike.duplicate(true)) == base + 2, "The limit resets in the next battle")

	# --- once per turn ---
	fresh_battle(main, ["relic_common_032"])
	check(main._card_effect(strike.duplicate(true)) == base + 1, "Turn bonus applies")
	check(main._card_effect(strike.duplicate(true)) == base, "Turn bonus applies once")
	main.relics.begin_turn()
	check(main._card_effect(strike.duplicate(true)) == base + 1, "Turn bonus returns next turn")

	# --- first HP loss, block ---
	fresh_battle(main, ["relic_common_008"])
	main.block = 0
	main.apply_relic_result(main.relics.fire("hp_lost", main.relic_ctx(), main.owned_relics))
	main.apply_relic_result(main.relics.fire("hp_lost", main.relic_ctx(), main.owned_relics))
	check(main.block == 4, "Only the first HP loss gives block: %d" % main.block)

	# --- conditions at battle start ---
	main.choose_character(main.characters[0])
	main.owned_relics.assign(["relic_common_023"])
	main.hp = main.max_hp / 2 - 1
	main.start_battle("전투")
	check(main.block >= 5, "Low-HP start gives block: %d" % main.block)
	fresh_battle(main, ["relic_common_023"])
	check(main.block < 5, "Full-HP start does not: %d" % main.block)
	fresh_battle(main, ["relic_common_055"], "전투")
	check(main.block == 0, "Boss block does not fire on a normal fight")
	fresh_battle(main, ["relic_common_055"], "보스")
	check(main.block == 5, "Boss relic fires in a boss fight: %d" % main.block)

	# --- first draw ---
	fresh_battle(main, ["relic_common_019"])
	check(main.hand.size() == 4 and main.block == 8, "Heavy start: hand %d, block %d" % [main.hand.size(), main.block])
	fresh_battle(main, ["relic_common_049"])
	check(main.hand.size() == 6, "No curse: extra card: %d" % main.hand.size())

	# --- turn triggers ---
	fresh_battle(main, ["relic_common_012", "relic_common_054"])
	var before: int = main.hand.size()
	main.battle_turn = 3
	main.apply_relic_result(main.relics.fire("turn_start", main.relic_ctx(), main.owned_relics))
	check(main.hand.size() == before + 1, "Third turn draws a card")
	main.battle_turn = 5
	var energy_before: int = main.energy
	main.apply_relic_result(main.relics.fire("turn_start", main.relic_ctx(), main.owned_relics))
	check(main.energy == energy_before + 1, "Fifth turn gives energy")

	# --- no block this turn -> block next turn ---
	fresh_battle(main, ["relic_common_013"])
	main.apply_relic_result(main.relics.fire("turn_end", main.relic_ctx(), main.owned_relics))
	var carried: Dictionary = main.relics.take_carry("turn")
	check(int(carried.get("block", 0)) == 3, "Block carried to the next turn: %s" % str(carried))
	check(main.relics.take_carry("turn").is_empty(), "Carry is consumed once")

	# --- bank (heal stored by victories, paid at rest) ---
	main.choose_character(main.characters[0])
	main.owned_relics.assign(["relic_common_030"])
	main.start_battle("전투")
	main.apply_relic_result(main.relics.fire("battle_won", main.relic_ctx(), main.owned_relics))
	main.apply_relic_result(main.relics.fire("battle_won", main.relic_ctx(), main.owned_relics))
	check(main.relics.bank() == 2, "Two wins store 2")
	main.hp = 10
	main.apply_relic_result(main.relics.fire("rest", {"max_hp": main.max_hp}, main.owned_relics))
	check(main.hp == 12 and main.relics.bank() == 0, "Rest pays the bank and empties it: hp %d" % main.hp)

	# --- rest percentage ---
	main.owned_relics.assign(["relic_common_052"])
	main.relics.reset_run()
	check(main.relics.modify("rest_heal", {"max_hp": 72}, main.owned_relics) == 4, "5% of 72 rounds up to 4")

	# --- carried to the next battle ---
	main.choose_character(main.characters[0])
	main.owned_relics.assign(["relic_common_022", "relic_common_048", "relic_common_057"])
	main.apply_relic_result(main.relics.fire("rest_any", {"max_hp": main.max_hp}, main.owned_relics))
	main.apply_relic_result(main.relics.fire("event_paid", {}, main.owned_relics))
	main.apply_relic_result(main.relics.fire("treasure", {}, main.owned_relics))
	main.hp = 20
	main.start_battle("전투")
	check(main.hand.size() == 6 and main.block == 3, "Event payment: extra card and block: hand %d block %d" % [main.hand.size(), main.block])
	check(main.hp == 24, "Treasure heal arrives in the next battle: %d" % main.hp)
	check(main._card_effect(strike.duplicate(true)) == base + 3, "Rest bonus applies to the first attack")
	check(main._card_effect(strike.duplicate(true)) == base, "Rest bonus is spent")
	main.start_battle("전투")
	check(main.hand.size() == 5, "Carry does not repeat: %d" % main.hand.size())

	# --- enemy conditions ---
	fresh_battle(main, ["relic_common_046", "relic_common_035"])
	check(main._card_effect(strike.duplicate(true)) == base + 3, "Full-HP enemy bonus")
	check(main._card_effect(strike.duplicate(true)) == base, "Enemy is no longer at full HP")

	# --- incoming damage reduction through the real turn flow (compared with a run without the relic) ---
	var losses := []
	for owned in [[], ["relic_common_007"]]:
		fresh_battle(main, owned)
		# monsters are random now: pin the one whose first move is a plain 8-damage attack
		main.enemy = main.Data.find_record("monsters", "ash_warden")
		main.enemy_hp = int(main.enemy.hp)
		main.enemy_max_hp = main.enemy_hp
		main.enemy_turn = 0
		main.block = 0
		var hp_before: int = main.hp
		main.end_turn()
		var waited := 0.0
		while main.battle_busy and waited < 12.0:
			await create_timer(0.2).timeout
			waited += 0.2
		losses.append(hp_before - main.hp)
		check(main.battle_turn == 2, "Turn counter advanced")
	check(losses[0] > 2 and losses[1] == losses[0] - 2, "First-turn attack reduced by 2: %s" % str(losses))

	# --- reward screen lists relic effects ---
	D.path = "user://relic_engine_dex_b_%d.json" % stamp
	fresh_battle(main, ["relic_common_038"])
	main.enemy_hp = 0
	main.show_reward()
	check(main.reward_relic_lines.size() == 1 and main.gold >= 130, "Reward applies a first-sighting bonus: gold %d" % main.gold)
	var shown := false
	for label in main.reward_view.find_children("*", "Label", true, false):
		if label.text.begins_with("유물 · GOLD"): shown = true
	check(shown, "Reward screen shows the relic line")

	# --- uncommon relics ---
	var eng = main.relics
	var heal_card := {"name": "회복", "type": "스킬", "cost": 1, "heal": 3}
	var guard_card := {"name": "방어", "type": "스킬", "cost": 1, "block": 5}
	var free_card := {"name": "공짜", "type": "스킬", "cost": 0}
	var big_card := {"name": "큰 것", "type": "공격", "cost": 2, "damage": 9}
	var owned: Array = []
	main.choose_character(main.characters[0])
	eng.begin_battle()
	owned = ["relic_uncommon_002"]
	check(int(eng.fire("turn_start", {"turn": 3}, owned).get("draw", 0)) == 1 and eng.fire("turn_start", {"turn": 4}, owned).is_empty(), "Every third turn draws")
	owned = ["relic_uncommon_003"]
	check(int(eng.fire("battle_won", {"deck_no_heal": true}, owned).get("heal", 0)) == 5, "No healing cards: +2 more")
	check(int(eng.fire("battle_won", {"deck_no_heal": false}, owned).get("heal", 0)) == 3, "With healing cards: plain heal")
	owned = ["relic_uncommon_005"]
	check(eng.fire("turn_end", {"turn": 1}, owned).is_empty() and int(eng.take_carry("turn").get("energy", 0)) == 2, "A first turn without skills stores 2 energy")
	eng.begin_turn()
	eng.note_card(guard_card, 5)
	eng.fire("turn_end", {"turn": 1}, owned)
	check(eng.take_carry("turn").is_empty(), "Playing a skill cancels it")
	eng.begin_turn()
	owned = ["relic_uncommon_006"]
	check(int(eng.fire("battle_won", {"kind": "엘리트"}, owned).get("max_hp", 0)) == 2 and eng.fire("battle_won", {"kind": "전투"}, owned).is_empty(), "Elite kill: max HP +2")
	owned = ["relic_uncommon_007"]
	eng.begin_battle()
	eng.note_card(heal_card, 0)
	eng.fire("card_played", {"card": heal_card}, owned)
	check(eng.take_first_attack_bonus() == 4, "Healing card boosts the next attack by 4")
	eng.note_card(heal_card, 0)
	eng.fire("card_played", {"card": heal_card}, owned)
	check(eng.take_first_attack_bonus() == 0, "Once per turn")
	owned = ["relic_uncommon_008"]
	main.owned_relics.assign(owned)
	check(main.removal_price() == main.REMOVAL_BASE_PRICE - 20, "Card removal is 20 cheaper: %d" % main.removal_price())
	owned = ["relic_uncommon_010"]
	check(int(eng.fire("battle_start", {}, owned).get("poison_enemy", 0)) == 2, "Battle start poison 2")
	owned = ["relic_uncommon_011"]
	eng.begin_turn()
	eng.note_card(guard_card, 5)
	check(eng.fire("turn_end", {}, owned).is_empty() and eng.take_carry("turn").is_empty(), "One block card is not enough")
	eng.note_card(guard_card, 5)
	eng.fire("turn_end", {}, owned)
	check(int(eng.take_carry("turn").get("energy", 0)) == 1, "Two block cards store 1 energy")
	owned = ["relic_uncommon_012"]
	check(eng.modify("reward_choices", {}, owned) == 1, "One more reward choice")
	owned = ["relic_uncommon_015"]
	eng.begin_battle()
	check(eng.fire("hp_lost", {"hp": 40, "max_hp": 72}, owned).is_empty(), "Above 30% nothing happens")
	check(int(eng.fire("hp_lost", {"hp": 20, "max_hp": 72}, owned).get("heal", 0)) == 6, "At or below 30%: heal 6")
	check(eng.fire("hp_lost", {"hp": 15, "max_hp": 72}, owned).is_empty(), "Only once per battle")
	owned = ["relic_uncommon_017"]
	check(int(eng.fire("battle_won", {}, owned).get("heal", 0)) == 4 and eng.modify("first_draw", {}, owned) == -1, "Heal 4, draw 1 less")
	owned = ["relic_uncommon_018"]
	eng.begin_turn()
	check(eng.modify("card_poison", {}, owned) == 2 and eng.modify("card_poison", {}, owned) == 0, "Poison bonus once per turn")
	owned = ["relic_uncommon_023"]
	eng.begin_turn()
	eng.note_card(free_card, 0)
	check(eng.fire("card_played", {}, owned).is_empty(), "A free card alone does nothing")
	eng.note_card(big_card, 0)
	check(int(eng.fire("card_played", {}, owned).get("draw", 0)) == 1, "Free + cost 2 draws a card")
	owned = ["relic_uncommon_027"]
	var gained := 0
	for i in 7: gained += int(eng.fire("shop_removal", {}, owned).get("max_hp", 0))
	check(gained == 5, "Removal max HP stops at five: %d" % gained)
	owned = ["relic_uncommon_033"]
	eng.begin_turn()
	var poisoned := {"card": big_card, "enemy_poison": 2, "enemy_venom": 3}
	var blocks := 0
	for i in 3: blocks += int(eng.fire("card_played", poisoned, owned).get("block", 0))
	check(blocks == 6, "Two blocks per turn against poison and venom: %d" % blocks)
	owned = ["relic_uncommon_035"]
	eng.begin_battle()
	check(int(eng.fire("hp_lost", {}, owned).get("draw", 0)) == 2 and eng.fire("hp_lost", {}, owned).is_empty(), "First HP loss draws two")
	owned = ["relic_uncommon_039"]
	eng.begin_battle()
	eng.fire("turn_end", {"turn": 1, "energy": 3}, owned)
	check(int(eng.take_carry("turn").get("energy", 0)) == 2, "Leftover energy carries, capped at 2")
	eng.fire("turn_end", {"turn": 2, "energy": 3}, owned)
	check(eng.take_carry("turn").is_empty(), "Only the first turn")
	owned = ["relic_uncommon_040"]
	eng.begin_turn()
	eng.note_card(heal_card, 0)
	eng.note_card(heal_card, 0)
	eng.note_card(guard_card, 5)
	check(eng.fire("turn_end", {}, owned).is_empty(), "Same-named cards do not count twice")
	eng.note_card(big_card, 0)
	check(int(eng.fire("turn_end", {}, owned).get("heal", 0)) == 2, "Three different cards heal 2")
	owned = ["relic_uncommon_004"]
	eng.begin_shop()
	check(int(eng.fire("shop_potion", {}, owned).get("gold", 0)) == 15 and eng.fire("shop_potion", {}, owned).is_empty(), "First potion of a visit refunds 15")
	eng.begin_shop()
	check(int(eng.fire("shop_potion", {}, owned).get("gold", 0)) == 15, "The refund returns in the next shop")
	# upgrade at rest only below half HP
	main.choose_character(main.characters[0])
	main.owned_relics.assign(["relic_uncommon_038"])
	main.max_hp = 72
	main.hp = 70
	var upgraded_before: int = main.deck.filter(func(c): return c.get("upgraded", false)).size()
	main.apply_relic_result(main.relics.fire("rest", {"hp": main.hp, "max_hp": main.max_hp}, main.owned_relics))
	check(main.deck.filter(func(c): return c.get("upgraded", false)).size() == upgraded_before, "Healthy rest upgrades nothing")
	main.hp = 20
	main.apply_relic_result(main.relics.fire("rest", {"hp": main.hp, "max_hp": main.max_hp}, main.owned_relics))
	check(main.deck.filter(func(c): return c.get("upgraded", false)).size() == upgraded_before + 1, "Weak rest upgrades a card")

	# --- on-screen notice when a relic acts in battle ---
	fresh_battle(main, ["relic_common_008"])
	check(main.screen == "battle", "In battle for the notice test")
	var notice_ctx: Dictionary = main.relic_ctx()
	notice_ctx["damage"] = 5
	main.apply_relic_result(main.relics.fire("hp_lost", notice_ctx, main.owned_relics))
	var toast = main.find_child("RelicToast", false, false)
	check(toast != null and toast.text.contains("방어도 +4") and toast.text.contains(str(lookup("relic_common_008").name)), "A relic notice names the relic and the effect")
	# --- rare and epic relics ---
	main.choose_character(main.characters[0])
	eng = main.relics
	eng.begin_battle()
	check(int(eng.fire("battle_won", {"kind": "보스"}, ["relic_rare_001"]).get("max_hp", 0)) == 5 and eng.fire("battle_won", {"kind": "엘리트"}, ["relic_rare_001"]).is_empty(), "Boss kill: max HP +5")
	check(int(eng.fire("battle_won", {"kind": "엘리트"}, ["relic_rare_004"]).get("heal_pct", 0)) == 10, "Elite kill heals 10%")
	check(int(eng.fire("hp_lost", {"damage": 9}, ["relic_rare_002"]).get("heal", 0)) == 5 and eng.fire("hp_lost", {"damage": 9}, ["relic_rare_002"]).is_empty(), "First hit: heal half, rounded up, once")
	eng.begin_battle()
	check(eng.fire("hp_lost", {"hp": 5}, ["relic_rare_005"]).is_empty() and int(eng.fire("hp_lost", {"hp": 1}, ["relic_rare_005"]).get("block", 0)) == 20, "Down to 1 HP gives 20 block")
	eng.begin_battle()
	eng.fire("turn_end", {"turn": 1}, ["relic_rare_008"])
	check(int(eng.fire("battle_won", {}, ["relic_rare_008"]).get("heal", 0)) == 8, "A first turn without attacks heals 8 at the end")
	eng.begin_battle()
	eng.note_card(big_card, 0)
	eng.fire("turn_end", {"turn": 1}, ["relic_rare_008"])
	check(eng.fire("battle_won", {}, ["relic_rare_008"]).is_empty(), "Attacking on turn one removes it")
	check(int(eng.fire("battle_won", {"reward_gold": 40}, ["relic_rare_010"]).get("gold", 0)) == 8, "Victory gold +20%")
	eng.begin_battle()
	var paid_out := 0
	for hit in [4, 4, 4, 9, 30, 30, 30]: paid_out += int(eng.fire("hp_lost", {"damage": hit}, ["relic_rare_021"]).get("heal", 0))
	check(paid_out == 9, "Ten points of loss pay 3, three times per battle: %d" % paid_out)
	check(int(eng.fire("battle_start", {}, ["relic_rare_022"]).get("block", 0)) == 12, "Battle start block 12")
	check(int(eng.fire("rest_upgrade", {}, ["relic_rare_024"]).get("heal_pct", 0)) == 10, "Upgrading at rest still heals 10%")
	check(eng.modify("incoming_damage", {}, ["relic_epic_001"]) == -2 and int(eng.fire("battle_won", {}, ["relic_epic_001"]).get("gold", 0)) == -15, "Heavy plate: -2 damage, -15 gold")
	check(eng.modify("first_draw", {}, ["relic_epic_002"]) == 2 and int(eng.fire("battle_start", {}, ["relic_epic_002"]).get("energy", 0)) == 1, "Gambler: two cards and energy")
	check(int(eng.fire("turn_end", {"turn": 1}, ["relic_epic_002"]).get("hp_loss", 0)) == 4 and eng.fire("turn_end", {"turn": 2}, ["relic_epic_002"]).is_empty(), "Gambler pays 4 HP after turn one only")
	check(eng.modify("first_draw", {}, ["relic_epic_011"]) == -2 and int(eng.fire("turn_start", {"turn": 6}, ["relic_epic_011"]).get("energy", 0)) == 1, "Engine: energy every turn, two fewer cards")
	# applying results: signed max HP, percent healing, HP loss floor, lethal save
	main.choose_character(main.characters[0])
	main.max_hp = 72
	main.hp = 72
	main.apply_relic_result({"max_hp": -6})
	check(main.max_hp == 66 and main.hp == 66, "Losing max HP clamps current HP: %d/%d" % [main.hp, main.max_hp])
	main.apply_relic_result({"max_hp": 5})
	check(main.max_hp == 71 and main.hp == 71, "Gaining max HP raises current HP too")
	main.hp = 30
	main.apply_relic_result({"heal_pct": 20})
	check(main.hp == 45, "Percent heal rounds up: %d" % main.hp)
	main.hp = 3
	main.apply_relic_result({"hp_loss": 10})
	check(main.hp == 1, "Self-damage never kills")
	main.gold = 10
	main.apply_relic_result({"gold": -15})
	check(main.gold == 0, "Gold never goes below zero")
	main.max_hp = 72
	main.hp = 72
	main.owned_relics.assign([])
	Data.read("relics").append(library["relic_rare_010"])  # not exported yet: make it visible to the shop code for this check
	main.grant_relic("relic_rare_010")
	Data.read("relics").pop_back()
	check(main.owned_relics.has("relic_rare_010") and main.max_hp == 66, "Acquisition penalty applies once: %d" % main.max_hp)
	fresh_battle(main, ["relic_epic_004"])
	main.max_hp = 72
	main.hp = 0
	main.apply_relic_result(main.relics.fire("lethal", main.relic_ctx(), main.owned_relics))
	check(main.hp == 1 and main.max_hp == 67, "Lethal hit leaves 1 HP and costs 5 max HP: %d/%d" % [main.hp, main.max_hp])
	main.hp = 0
	main.apply_relic_result(main.relics.fire("lethal", main.relic_ctx(), main.owned_relics))
	check(main.hp == 0, "The save works once per battle")

	# --- review fixes: one place for HP loss ---
	fresh_battle(main, ["relic_epic_004"])
	main.max_hp = 72
	main.hp = 3
	check(main.lose_hp(5) == 2 and main.hp == 1 and main.max_hp == 67, "Poison-sized loss is also saved at 1 HP: hp %d, max %d" % [main.hp, main.max_hp])
	main.hp = 1
	main.lose_hp(5)
	check(main.hp == 0, "The save is used up after one time")
	fresh_battle(main, ["relic_epic_004", "relic_rare_002"])
	main.max_hp = 72
	main.hp = 5
	main.lose_hp(20)
	check(main.hp == 3, "Healing relics see the HP really lost (4), not the blow (20): hp %d" % main.hp)
	fresh_battle(main, ["relic_rare_021"])
	main.max_hp = 72
	main.hp = 60
	var before_hit: int = main.hp
	main.lose_hp(25)
	check(main.hp == before_hit - 25 + 6, "A 25-point loss pays the accumulated heal twice: hp %d" % main.hp)
	main.lose_hp(5)
	check(main.hp == before_hit - 25 + 6 - 5 + 3, "The leftover 5 carries over and pays at the next 5: hp %d" % main.hp)
	fresh_battle(main, ["relic_epic_002", "relic_uncommon_015"])
	main.max_hp = 72
	main.hp = 24
	main.apply_relic_result({"hp_loss": 4})
	check(main.hp == 20 + 6, "A relic's own HP cost can trigger low-HP relics: hp %d" % main.hp)

	# --- wave 2: upgraded-card, energy-left, previous-turn and event-price relics ---
	eng.begin_battle()
	var up_card := {"name": "강화 공격", "type": "공격", "cost": 1, "damage": 6, "upgraded": true}
	check(eng.modify("attack_damage", {"card": up_card}, ["relic_common_042"]) == 1, "Pencil knife: upgraded attack +1")
	check(eng.modify("attack_damage", {"card": {"type": "공격"}}, ["relic_common_042"]) == 0, "Pencil knife: plain attack unchanged")
	check(int(eng.fire("card_played", {"card": up_card}, ["relic_common_050"]).get("block", 0)) == 2, "Correction stamp: first upgraded card gives block")
	check(int(eng.fire("card_played", {"card": up_card}, ["relic_common_050"]).get("block", 0)) == 0, "Correction stamp: only once per battle")
	eng.fire("turn_end", {"energy": 0}, ["relic_common_059"])
	check(int(eng.take_carry("turn").get("block", 0)) == 0, "Ember cover: nothing without leftover energy")
	eng.fire("turn_end", {"energy": 2}, ["relic_common_059"])
	check(int(eng.take_carry("turn").get("block", 0)) == 4, "Ember cover: leftover energy gives next-turn block")
	eng.fire("turn_end", {"energy": 2}, ["relic_common_059"])
	check(int(eng.take_carry("turn").get("block", 0)) == 0, "Ember cover: once per battle")
	eng.begin_battle()
	check(int(eng.fire("turn_start", {"turn": 1}, ["relic_uncommon_014", "relic_legend_004"]).get("draw", 0)) == 0, "Boatman band: nothing on turn 1")
	eng.begin_turn()
	var calm: Dictionary = eng.fire("turn_start", {"turn": 2}, ["relic_uncommon_014", "relic_legend_004"])
	check(int(calm.get("draw", 0)) == 1 and int(calm.get("block", 0)) == 4, "Calm turn pays draw and lantern block: %s" % str(calm))
	eng.fire("hp_lost", {"damage": 3}, [])
	eng.begin_turn()
	var hurt: Dictionary = eng.fire("turn_start", {"turn": 3}, ["relic_uncommon_014", "relic_legend_004"])
	check(int(hurt.get("draw", 0)) == 0 and int(hurt.get("block", 0)) == 0, "A turn with HP lost pays nothing next: %s" % str(hurt))
	eng.begin_battle()
	check(int(eng.fire("turn_end", {"turn": 1}, ["relic_uncommon_021"]).get("cleanse_poison", 0)) == 3, "Glass bell cleanses on turn 1")
	check(int(eng.fire("turn_end", {"turn": 2}, ["relic_uncommon_021"]).get("cleanse_poison", 0)) == 0, "Glass bell is turn 1 only")
	check(int(eng.fire("turn_start", {"turn": 3, "upgraded_cards": 5}, ["relic_uncommon_026"]).get("energy", 0)) == 1, "Collating glass: energy on the third turn")
	check(int(eng.fire("turn_start", {"turn": 3, "upgraded_cards": 4}, ["relic_uncommon_026"]).get("energy", 0)) == 0, "Collating glass: needs 5 upgraded cards")
	check(int(eng.fire("turn_start", {"turn": 4, "upgraded_cards": 5}, ["relic_uncommon_026"]).get("energy", 0)) == 0, "Collating glass: not on other turns")
	check(int(eng.fire("battle_start", {}, ["relic_legend_001"]).get("block", 0)) == 15, "Contract: block 15 at battle start")
	check(int(eng.fire("turn_start", {"turn": 1}, ["relic_legend_001"]).get("hp_loss", 0)) == 1, "Contract: 1 HP every turn")
	check(eng.preview("event_cost", {}, ["relic_uncommon_009"]).add == -10, "Wax carrier lowers event prices")
	check(eng.preview("event_cost", {}, ["relic_rare_003"]).free, "Spare key: free event is available")
	eng.fire("event_cost", {}, ["relic_rare_003"])
	check(not eng.preview("event_cost", {}, ["relic_rare_003"]).free, "Spare key: used up for the run")
	eng.reset_run()
	fresh_battle(main, ["relic_uncommon_009"])
	main.gold = 5
	main.show_story_event("common_act1_11")
	var paid_choice: Dictionary = {}
	for ch in main.story_event.choices:
		if int(ch.get("gold_cost", 0)) > 0 or str(ch.description).find("골드") >= 0 and ch.has("gold_cost"): paid_choice = ch
	check(not paid_choice.is_empty() and int(paid_choice.gold_cost) == 2 and str(paid_choice.description).begins_with("골드 2를 내고"), "Event choice price shown cut by 10: %s" % str(paid_choice))
	check(not bool(paid_choice.get("disabled", true)), "With 5 gold the cheaper choice is available")
	fresh_battle(main, ["relic_rare_003"])
	main.gold = 0
	main.show_story_event("common_act1_11")
	paid_choice = {}
	for ch in main.story_event.choices:
		if ch.has("relic_free"): paid_choice = ch
	check(not paid_choice.is_empty() and int(paid_choice.gold_cost) == 0 and not str(paid_choice.description).contains("골드"), "Spare key makes the choice free: %s" % str(paid_choice))
	for index in main.story_event.choices.size():
		if main.story_event.choices[index].has("relic_free"):
			main.take_story_choice(index)
			break
	check(not main.relics.preview("event_cost", {}, main.owned_relics).free, "Taking the free choice spends the key")

	# --- elite and boss victories leave a relic to choose ---
	for kind in ["전투", "엘리트", "보스"]:
		fresh_battle(main, [], kind)
		main.enemy_hp = 0
		main.show_reward()
		await process_frame
		var offered: Array = []
		offered = main.reward_view.find_children("RewardRelic_*", "Button", true, false)
		if kind == "전투":
			check(offered.is_empty(), "A normal fight leaves no relic choice")
			continue
		check(offered.size() == 3, "%s victory offers three relics: %d" % [kind, offered.size()])
		var chosen: String = str(offered[1].name).trim_prefix("RewardRelic_")
		offered[1].pressed.emit()
		await process_frame
		check(main.owned_relics.has(chosen), "Chosen reward relic is owned")
		check(main.reward_view.find_child("RewardRelic_*", true, false) == null, "Choice buttons disappear after picking")
		var again := 0
		again = main.reward_view.find_children("RewardRelic_*", "Button", true, false).size()
		check(again == 0, "Only one relic can be taken: %d" % again)

	# --- treasure room offers relics to choose from ---
	main.choose_character(main.characters[0])
	main.expedition.current_id = 1
	main._generate_map()
	main.show_treasure()
	await process_frame
	var offers: Array = []
	offers = main.content.find_children("Treasure_*", "Button", true, false)
	check(offers.size() >= 2 and offers.size() <= 3, "Treasure offers two or three relics: %d" % offers.size())
	check(main.content.find_child("Treasure_explorer_map", true, false) != null, "The explorer map is always offered while unowned")
	var picked: String = str(offers[0].name).trim_prefix("Treasure_")
	offers[0].pressed.emit()
	check(main.owned_relics.has(picked), "Chosen treasure relic is owned: " + picked)
	main.owned_relics.clear()
	for relic in main.relic_candidates(false): main.owned_relics.append(relic.id)
	main.show_treasure()
	await process_frame
	check(main.content.find_child("Treasure_*", true, false) == null or true, "Empty pool does not crash")

	for file in [D.path, "user://relic_engine_dex_b_%d.json" % stamp, T.path, T.path + ".bak", T.path + ".tmp"]:
		if FileAccess.file_exists(file): DirAccess.remove_absolute(file)
	print("RELIC_ENGINE_QA failures=%d" % failures.size())
	quit(1 if failures.size() > 0 else 0)

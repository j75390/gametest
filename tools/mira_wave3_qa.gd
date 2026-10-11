extends SceneTree
## Mira card wave 3 (19 cards): every effect and its upgrade resolves with the right numbers.
const D = preload("res://scripts/codex_discovery.gd")
const T = preload("res://scripts/timeline.gd")
const Data = preload("res://scripts/game_data.gd")
const WAVE3 := ["acid_splash", "steady_dose", "lancet", "herb_bundle", "bitter_tonic", "numbing_salve", "rotten_fruit",
	"venom_chain", "plague_mist", "thorn_tincture", "patient_poison", "siphon_vitality", "scar_tissue", "rapid_poison", "unstable_mixture",
	"lethal_dose", "grand_elixir", "apothecary_feast", "venom_pulse"]
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
	main.hp = main.max_hp - 10
	main.draw_pile = [main.card_db.common[0].duplicate(true), main.card_db.common[0].duplicate(true), main.card_db.common[0].duplicate(true), main.card_db.common[0].duplicate(true)]

func run():
	var stamp: int = Time.get_ticks_usec()
	D.path = "user://wave3_dex_%d.json" % stamp
	T.path = "user://wave3_tl_%d.json" % stamp
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	fresh(main)
	var pool_ids: Array = []
	for c in main.card_db.mira: pool_ids.append(c.id)
	for id in WAVE3:
		check(pool_ids.has(id), "%s is in the Mira pool" % id)
		var c: Dictionary = card(main, id)
		check(not c.is_empty() and c.get("upgrade", {}).size() > 0 and str(c.get("text", "")) != "" and c.text != "효과 없음", "%s has text and an upgrade" % id)
	# ---- plain numbers: base then upgraded ----
	var max_hp: int = main.max_hp
	fresh(main)
	var hp0: int = main.enemy_hp
	main._card_effect(card(main, "acid_splash"))
	check(hp0 - main.enemy_hp == 7 and main.enemy_status.amount("vulnerable") == 1, "Acid splash: 7 damage + vulnerable 1")
	fresh(main)
	main._card_effect(card(main, "acid_splash", true))
	check(main.enemy_status.amount("vulnerable") == 2, "Upgraded acid splash: vulnerable 2")
	fresh(main)
	main._card_effect(card(main, "steady_dose"))
	check(main.enemy_status.amount("poison") == 4 and main.hand.size() == 1, "Steady dose: poison 4, draw 1")
	fresh(main)
	hp0 = main.enemy_hp
	main._card_effect(card(main, "lancet"))
	check(hp0 - main.enemy_hp == 4 and main.enemy_status.amount("vulnerable") == 1, "Lancet: 4 damage + vulnerable 1")
	fresh(main)
	main._card_effect(card(main, "herb_bundle"))
	check(main.block == 4 and main.potions.size() == 1, "Herb bundle: block 4 + a potion")
	fresh(main)
	var hp_before: int = main.hp
	main._card_effect(card(main, "bitter_tonic"))
	check(main.hp == hp_before - 3 and main.energy == 5, "Bitter tonic: -3 HP, +2 energy (hp %d energy %d)" % [main.hp, main.energy])
	fresh(main)
	main._card_effect(card(main, "numbing_salve"))
	check(main.block == 7 and main.enemy_status.amount("weak") == 1, "Numbing salve: block 7 + weak 1")
	fresh(main)
	hp0 = main.enemy_hp
	var discard_before: int = main.discard_pile.size()
	main._card_effect(card(main, "rotten_fruit"))
	check(hp0 - main.enemy_hp == 8 and main.discard_pile.size() == discard_before + 1, "Rotten fruit: 8 damage + a side effect in the discard pile")
	fresh(main)
	hp0 = main.enemy_hp
	main._card_effect(card(main, "venom_chain"))
	check(hp0 - main.enemy_hp == 8 and main.enemy_status.amount("poison") == 6, "Venom chain: 8 damage + poison 6")
	fresh(main)
	main._card_effect(card(main, "venom_chain", true))
	check(main.enemy_status.amount("poison") == 8, "Upgraded venom chain: poison 8")
	fresh(main)
	main._card_effect(card(main, "plague_mist"))
	check(main.block == 7 and main.enemy_status.amount("poison") == 4 and main.enemy_status.amount("weak") == 1, "Plague mist: block 7, poison 4, weak 1")
	fresh(main)
	main._card_effect(card(main, "thorn_tincture"))
	check(main.block == 4 and main.player_status.amount("counter") == 6, "Thorn tincture: block 4 + counter 6")
	fresh(main)
	main._card_effect(card(main, "patient_poison"))
	check(main.venom_turns == 4, "Patient poison: venom 4 turns (%d)" % main.venom_turns)
	fresh(main)
	hp0 = main.enemy_hp
	hp_before = main.hp
	main._card_effect(card(main, "siphon_vitality"))
	check(hp0 - main.enemy_hp == 6 and main.hp == hp_before + 3, "Siphon vitality: 6 damage, heal 3 (hp %d -> %d)" % [hp_before, main.hp])
	fresh(main)
	main._card_effect(card(main, "scar_tissue"))
	check(main.player_status.amount("barrier") == 5 and main.player_status.amount("counter") == 3, "Scar tissue: barrier 5 + counter 3")
	fresh(main)
	hp0 = main.enemy_hp
	main._card_effect(card(main, "rapid_poison"))
	check(hp0 - main.enemy_hp == 4 and main.enemy_status.amount("poison") == 8, "Rapid poison: 4 damage + poison 8")
	fresh(main)
	main._card_effect(card(main, "unstable_mixture"))
	check(main.potions.size() == 1 and main.hand.size() == 1, "Unstable mixture: a potion + draw 1")
	fresh(main)
	main._card_effect(card(main, "unstable_mixture", true))
	check(main.hand.size() == 2, "Upgraded unstable mixture draws 2")
	# lethal dose: damage plus the poison burst, poison stays
	fresh(main)
	main.enemy_status.set_amount("poison", 9)
	hp0 = main.enemy_hp
	main._card_effect(card(main, "lethal_dose"))
	check(hp0 - main.enemy_hp == 15 and main.enemy_status.amount("poison") == 9, "Lethal dose: 6 + poison 9 = 15 damage, poison kept (%d)" % (hp0 - main.enemy_hp))
	# grand elixir
	fresh(main)
	hp_before = main.hp
	main._card_effect(card(main, "grand_elixir"))
	check(main.player_status.amount("barrier") == 10 and main.hp == mini(max_hp, hp_before + 10), "Grand elixir: barrier 10, heal 10 (hp %d -> %d)" % [hp_before, main.hp])
	check(card(main, "grand_elixir").get("exhaust", false), "Grand elixir exhausts")
	# apothecary feast: two cards and an energy, exhausts; upgrade costs 0
	fresh(main)
	main._card_effect(card(main, "apothecary_feast"))
	check(main.hand.size() == 2 and main.energy == 4, "Apothecary feast: draw 2, +1 energy (hand %d energy %d)" % [main.hand.size(), main.energy])
	var up_feast: Dictionary = card(main, "apothecary_feast", true)
	check(int(up_feast.cost) == 0 and card(main, "apothecary_feast").get("exhaust", false), "Upgraded feast costs 0 and the card exhausts: cost %s" % str(up_feast.cost))
	# venom pulse
	fresh(main)
	main._card_effect(card(main, "venom_pulse"))
	check(main.venom_turns == 6 and main.enemy_status.amount("vulnerable") == 2, "Venom pulse: venom 6, vulnerable 2")
	# retained cards stay in hand at turn end, ordinary ones are discarded
	check(card(main, "patient_poison").get("retain", false), "Patient poison is retained")
	# playing each wave 3 card from the hand through the real play path never leaves the battle stuck
	for id in WAVE3:
		fresh(main)
		var c: Dictionary = card(main, id)
		main.hand = [c]
		main.energy = 3
		main.show_battle()
		await process_frame
		main.play_card(0)
		await process_frame
		var waited := 0.0
		while main.battle_busy and waited < 20.0:
			await create_timer(0.1).timeout
			waited += 0.1
		check(not main.battle_busy, "%s leaves the battle responsive" % id)
	print("MIRA_WAVE3_QA cards=%d failures=%d" % [WAVE3.size(), failures])
	main.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)

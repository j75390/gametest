extends SceneTree
## Potions: belt of three, drinking in battle (every effect type), shop and drop rules.
const D = preload("res://scripts/codex_discovery.gd")
const Data = preload("res://scripts/game_data.gd")
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _initialize(): run.call_deferred()

func begin(main, hero := 0) -> void:
	main.choose_character(main.characters[hero])
	main.take_arrival_reward(0)
	main.finish_arrival()
	main.start_battle("전투")
	main.enemy = Data.find_record("monsters", "ash_warden")
	main.enemy_hp = int(main.enemy.hp)
	main.enemy_max_hp = main.enemy_hp
	main.enemy_block = 0
	main.show_battle()

func run():
	D.path = "user://potion_dex_%d.json" % Time.get_ticks_usec()
	root.size = Vector2i(1440, 900)
	var pool: Array = Data.read("potions")
	check(pool.size() >= 7, "Potion roster: %d" % pool.size())
	for p in pool:
		check(not str(p.get("effect", "")).is_empty() and int(p.get("price", 0)) > 0, "%s has text and a price" % p.id)
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	for hero in [0, 1]:
		begin(main, hero)
		check(main.potions.is_empty(), "A new run starts with an empty belt")
		await process_frame
		# healing
		main.potions = ["potion_text_02"]
		main.hp = 10
		main.use_potion(0)
		check(main.hp == 30 and main.potions.is_empty(), "Healing potion heals 20 and leaves the belt: hp %d" % main.hp)
		main.hp = main.max_hp - 3
		main.potions = ["potion_text_02"]
		main.use_potion(0)
		check(main.hp == main.max_hp, "Healing stops at max HP")
		# block
		begin(main, hero)
		main.block = 0
		main.potions = ["potion_text_06"]
		main.use_potion(0)
		check(main.block == 12, "Ointment gives 12 block: %d" % main.block)
		# poison on the enemy
		main.potions = ["potion_text_04"]
		main.use_potion(0)
		check(main.enemy_status.amount("poison") == 6, "Green poison gives 6 poison")
		# energy and draw
		var hand_before: int = main.hand.size()
		var energy_before: int = main.energy
		main.potions = ["potion_text_05"]
		main.use_potion(0)
		check(main.energy == energy_before + 2 and main.hand.size() == hand_before + 1, "Violet draught: +2 energy, +1 card (%d, %d)" % [main.energy, main.hand.size()])
		# can't drink while busy, or outside battle, or an empty slot
		main.potions = ["potion_text_06"]
		main.battle_busy = true
		main.use_potion(0)
		check(main.potions.size() == 1, "No drinking while an action runs")
		main.battle_busy = false
		main.use_potion(2)
		main.use_potion(-1)
		check(main.potions.size() == 1, "Bad slots do nothing")
		# a damaging potion is soaked by enemy block and can win the fight
		var test_potion := {"id": "test_bomb", "name": "t", "effect": "t", "price": 1, "damage": 10}
		Data.cache["potions"].append(test_potion)
		main.enemy_block = 4
		var enemy_before: int = main.enemy_hp
		main.potions = ["test_bomb"]
		main.use_potion(0)
		check(main.enemy_hp == enemy_before - 6 and main.enemy_block == 0, "Damage potion is soaked by block first")
		main.enemy_hp = 5
		main.potions = ["test_bomb"]
		main.use_potion(0)
		check(main.screen == "reward", "A potion that kills the enemy ends the fight")
		Data.cache["potions"].erase(test_potion)
		# the belt is drawn in battle with one icon per potion
		begin(main, hero)
		main.potions = ["potion_text_01", "potion_text_06"]
		main.show_battle()
		await process_frame
		await process_frame
		var belt = main.content.find_child("PotionBelt", true, false) if main.content else null
		if belt == null: belt = main.find_child("PotionBelt", true, false)
		check(belt != null and belt.get_child_count() == 3, "Belt shows three slots")
		var icons := 0
		if belt != null:
			for slot in belt.get_children():
				if slot.get_node_or_null("Icon") != null: icons += 1
		check(icons == 2, "Two filled slots show icons: %d" % icons)
	# drops: never when the belt is full, never from a boss
	begin(main, 0)
	main.potions = ["potion_text_01", "potion_text_01", "potion_text_01"]
	var dropped := 0
	for i in 200:
		if main._roll_potion_drop() != "": dropped += 1
	check(dropped == 0, "A full belt never receives a drop")
	main.potions.clear()
	main.enemy = Data.find_record("monsters", "ash_warden_boss")
	for i in 200: dropped += 1 if main._roll_potion_drop() != "" else 0
	check(dropped == 0, "Bosses leave no potion")
	main.enemy = Data.find_record("monsters", "ash_warden_elite")
	var elite_drops := 0
	for i in 300:
		main.potions.clear()
		if main._roll_potion_drop() != "": elite_drops += 1
	check(elite_drops > 120 and elite_drops < 240, "Elites drop about 60%%: %d of 300" % elite_drops)
	main.enemy = Data.find_record("monsters", "ash_warden")
	var normal_drops := 0
	for i in 300:
		main.potions.clear()
		if main._roll_potion_drop() != "": normal_drops += 1
	check(normal_drops > 50 and normal_drops < 130, "Normal fights drop about 30%%: %d of 300" % normal_drops)
	print("POTION_QA failures=%d" % failures)
	quit(1 if failures > 0 else 0)

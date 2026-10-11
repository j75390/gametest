extends SceneTree
## Story-choice engine: character-only choices, any-of conditions, extra/exclusive flags, relic payment
## instead of gold, character-specific reply lines, follow-up events and delayed battle effects.
const D = preload("res://scripts/codex_discovery.gd")
const T = preload("res://scripts/timeline.gd")
const Rules = preload("res://scripts/story_rules.gd")
var failures: Array[String] = []

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func _initialize(): run.call_deferred()

func open_event(main, record: Dictionary) -> void:
	main.story_event = record.duplicate(true)
	main.screen = "story_event"
	main.story_choice_taken = false
	main.story_follow_up = ""
	main.story_event["dialogue"] = ["x"]
	main.story_event["choices"] = Rules.visible_choices(main.story_event.choices, str(main.selected_character.id))
	main.arrival_view = load("res://scripts/act_arrival.gd").new()
	main.arrival_view.setup(main.story_event, {}, main.selected_character.name)
	main.add_child(main.arrival_view)
	await process_frame

func close_event(main) -> void:
	main.arrival_view.queue_free()
	main.arrival_view = null

func run():
	var stamp: int = Time.get_ticks_usec()
	D.path = "user://engine_dex_%d.json" % stamp
	T.path = "user://engine_tl_%d.json" % stamp
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	main.choose_character(main.characters[0])
	var sera_id := "sera"
	# --- pure rules ---
	var choices := [
		{"name": "all"}, {"name": "sera only", "character_only": "sera"},
		{"name": "any", "condition_any_flags": ["a", "b"]}]
	check(Rules.visible_choices(choices, "mira").size() == 2, "Character-only choice hidden from others")
	check(Rules.visible_choices(choices, "sera").size() == 3, "Character-only choice shown to its owner")
	check(Rules.unavailable(choices[2], 50, 0, [], {}, []) != "", "Any-of needs one flag")
	check(Rules.unavailable(choices[2], 50, 0, [], {"b": true}, []) == "", "Any-of satisfied by one flag")
	var relic_db: Array = main.relic_db
	var common := ""
	for record in relic_db:
		if str(record.get("rarity", "")) == "일반" and str(record.get("starter_character", "")).is_empty():
			common = str(record.id)
			break
	var paid := {"gold_cost": 30, "alt_cost": {"relic_rarity": "일반", "count": 1}}
	check(Rules.unavailable(paid, 50, 0, [], {}, relic_db) != "", "No gold and no relic: unavailable")
	check(Rules.unavailable(paid, 50, 0, [common], {}, relic_db) == "", "A common relic can replace gold")
	check(Rules.unavailable(paid, 50, 30, [], {}, relic_db) == "", "Enough gold still works")
	# --- full choice flow ---
	var event := {
		"id": "engine_test", "name": "engine", "effect": "x",
		"choices": [
			{"name": "multi", "description": "", "flag": "main_flag", "extra_flags": ["second", "third"], "exclusive_flags": ["old"], "reply": "done",
				"reply_extra_by_character": {"mira": "mira line"}, "follow_up": "no_such_event", "pending_effect": "next_battle_first_turn_block_minus_3"},
			{"name": "pay", "description": "", "gold_cost": 30, "alt_cost": {"relic_rarity": "일반", "count": 1}, "flag": "paid", "reply": "paid"},
			{"name": "repair", "description": "", "flag": "went", "if_missing_repair": {"flag": "sluice_repaired", "pending_effect": "next_battle_first_turn_block_minus_3"}, "reply": "r"}]}
	main.story_flags["old"] = true
	await open_event(main, event)
	main.take_story_choice(0)
	check(main.story_flags.has("main_flag") and main.story_flags.has("second") and main.story_flags.has("third"), "Extra flags are saved")
	check(not main.story_flags.has("old"), "Exclusive flag is cleared")
	check(main.arrival_view.dialogue.text.contains("mira line") and main.arrival_view.dialogue.text.begins_with("done"), "Character reply line appended")
	check(main.pending_effects.has("next_battle_first_turn_block_minus_3"), "Pending effect stored")
	check(main.story_follow_up == "no_such_event", "Follow-up remembered")
	close_event(main)
	# a missing follow-up event must not break the continue button
	await open_event(main, event)
	main.story_follow_up = "no_such_event"
	check(Data_find_empty(), "Unknown event id is empty")
	close_event(main)
	# relic payment
	main.owned_relics.append(common)
	main.gold = 0
	main.pending_effects.clear()
	await open_event(main, event)
	main.take_story_choice(1)
	check(main.gold == 0 and not main.owned_relics.has(common) and main.story_flags.has("paid"), "Relic paid instead of gold")
	close_event(main)
	# gold is preferred when affordable
	main.owned_relics.append(common)
	main.gold = 100
	await open_event(main, event)
	main.take_story_choice(1)
	check(main.gold == 70 and main.owned_relics.has(common), "Gold is paid first when enough")
	close_event(main)
	# fallback repair
	await open_event(main, event)
	main.take_story_choice(2)
	check(main.story_flags.has("sluice_repaired") and main.pending_effects.size() == 1, "Missing repair becomes a penalty")
	close_event(main)
	# --- delayed battle effect ---
	main.start_battle("전투")
	check(main.block_penalty == 3 and main.pending_effects.is_empty(), "Penalty applies to the next battle and is consumed")
	var defend: Dictionary = {}
	for owner in main.card_db:
		for card in main.card_db[owner]:
			if defend.is_empty() and int(card.get("block", 0)) >= 5 and int(card.cost) <= 3: defend = card
	check(not defend.is_empty(), "Test card with block exists")
	main.hand.clear()
	main.hand.append(defend.duplicate(true))
	main.block = 0
	main.energy = 3
	main.battle_busy = false
	main.play_card(0)
	await create_timer(0.5).timeout
	check(main.block == int(defend.block) - 3 and main.block_penalty == 0, "First block gained is reduced by 3: %d" % main.block)
	main.start_battle("전투")
	check(main.block_penalty == 0, "Penalty does not carry into later battles")
	# --- each playable character meets its own ACT I scene, and only its own ---
	var own := {"mira": "mira_coat", "kalian": "kalian_personal_1", "sera": "sera_personal_1", "lucian": "lucian_personal_1"}
	for character in main.characters:
		var cid := str(character.id)
		main.choose_character(character)
		var found: Dictionary = main.event_candidates()
		var personal_ids: Array = found.personal.map(func(e): return str(e.id))
		if own.has(cid):
			check(personal_ids == [own[cid]], "%s meets only its own scene: %s" % [cid, str(personal_ids)])
			main.show_story_event(own[cid])
			check(main.story_event.choices.size() == 2 and main.story_event.id == own[cid], "Scene opens with its two choices: " + cid)
			main.take_story_choice(0)
			check(main.story_flags.has("chain_%s_trace" % cid), "Personal scene records its clue: " + cid)
			check(main.event_candidates().personal.is_empty(), "A seen scene is not offered again: " + cid)
			main.arrival_view.queue_free()
		check(found.common.size() == 28, "Twenty-eight shared scenes remain for %s: %d" % [cid, found.common.size()])

	for file in [D.path, T.path, T.path + ".bak", T.path + ".tmp"]:
		if FileAccess.file_exists(file): DirAccess.remove_absolute(file)
	print("STORY_ENGINE_QA failures=%d" % failures.size())
	quit(1 if failures.size() > 0 else 0)

func Data_find_empty() -> bool:
	return load("res://scripts/game_data.gd").find_record("events", "no_such_event").is_empty()

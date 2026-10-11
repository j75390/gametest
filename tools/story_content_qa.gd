extends SceneTree
const Data = preload("res://scripts/game_data.gd")
var failures: Array[String] = []
func check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)
func _initialize(): run.call_deferred()
func run():
	preload("res://scripts/codex_discovery.gd").path = "user://story_qa_discovery.json"
	root.size = Vector2i(1440, 900)
	var book: Dictionary = Data.read("_library")
	check(book.relics.size() == 154, "154 authored relics")
	check(book.powers.size() >= 303, "300 existing status manuscripts + weak, vulnerable, strength")
	check(book.events.filter(func(e): return e.category == "COMMON").size() == 108, "108 common events (100 authored + 8 added with the event effects)")
	var playable: Array = book.relics.filter(func(r): return r.get("implementation", "") == "playable")
	check(Data.read("relics").size() == playable.size(), "Only executable relics exported: %d of %d" % [Data.read("relics").size(), playable.size()])
	check(Data.read("powers").size() >= 7, "Only executable statuses enter combat (4 original + weak, vulnerable, strength)")
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	main.choose_character(main.characters[0])
	check(preload("res://scripts/codex_discovery.gd").has("카드", "strike"), "Starting card discovered")
	check(preload("res://scripts/codex_discovery.gd").has("유물", "mira_crescent"), "Starting relic discovered")
	main.take_arrival_reward(0)
	main.finish_arrival()
	await process_frame
	for dimensions in [Vector2i(1440, 900), Vector2i(1280, 720)]:
		root.size = dimensions
		for event in Data.read("events"):
			if event.get("pool", "") != "common": continue
			main.show_story_event(event.id)
			await process_frame
			await process_frame
			var view = main.arrival_view
			check(view.dialogue.position.y + view.dialogue.size.y < view.actions.position.y, "Dialogue fits " + event.id)
			for option in view.actions.get_children():
				check(option.get_global_rect().end.y <= view.get_viewport_rect().size.y + 1, "Choice fits viewport " + event.id)
		main.hp = 50
		main.gold = 0
		main.show_story_event("common_act1_03")
		await process_frame
		check(main.arrival_view.actions.get_child(0).disabled, "Cannot purchase without gold")
		main.take_story_choice(0)
		check(not main.story_choice_taken and main.hp == 50, "Rejected choice has no cost or flag")
		main.gold = 24
		main.take_story_choice(0)
		check(main.gold == 0 and main.owned_relics.has("relic_common_001"), "Event purchase atomic")
		main.take_story_choice(0)
		check(main.gold == 0 and main.owned_relics.count("relic_common_001") == 1, "Double choice rejected")
		main.show_story_event("common_act1_03")
		main.gold = 100
		main.take_story_choice(0)
		check(not main.story_choice_taken and main.gold == 100, "Owned relic never purchased twice")
		main.owned_relics.erase("relic_common_001")
		main.show_story_event("common_act1_04")
		main.hp = 4
		main.take_story_choice(0)
		check(not main.story_choice_taken and main.hp == 4, "HP cost cannot kill")
		main.take_story_choice(2)
		check(main.story_choice_taken and main.hp == 4, "Free exit available")
		check(not main.story_flags.has("ward_resolved"), "Ordinary event does not resolve personal ward")
		main.show_codex()
		await process_frame
		var codex = main.get_node("Codex")
		check(not codex.records["스토리"].any(func(r): return str(r.id).begins_with("ending_")), "Ending spoiler hidden by default")
		check(not codex.records["지역"].any(func(r): return r.id == "black_canal"), "Late regions hidden")
		check(not codex.records["이벤트"].any(func(r): return r.id == "act1_ledger"), "Unseen boss event cannot leak in normal archive")
		codex._set_review_mode(true)
		check(codex.records["지역"].any(func(r): return r.id == "dawnless_sanctum"), "Review reveals all five regions")
		check(codex.records["유물"].size() == 154, "Review shows every relic")
		codex._change_category("지역")
		codex._select(codex.records["지역"].filter(func(r): return r.id == "dawnless_sanctum")[0])
		await process_frame
		check(not codex.art_box.get_parent().visible, "Text manuscript has no empty art column")
		check(codex.records["스토리"].any(func(r): return r.id == "ending_long_night"), "Ending available for explicit review")
		codex._set_review_mode(false)
		check(not codex.records["지역"].any(func(r): return r.id == "black_canal"), "Turning review off restores gate")
		codex.closed.emit()
		await process_frame
	main.owned_relics.assign(["mira_crescent", "relic_common_001", "relic_common_002", "relic_common_003", "relic_common_004", "relic_common_005", "relic_common_006"])
	main.start_battle("전투")
	check(main.block == 5 and main.energy == 4 and main.enemy_status.amount("poison") == 1, "Start hooks: block, energy, poison")
	main.hp = 50
	main.gold = 0
	main.show_reward()
	check(main.hp == 52 and main.gold == int(main.enemy.gold) + 5, "Victory hooks")
	var first_gold: int = main.gold
	main.show_reward()
	check(main.hp == 52 and main.gold == first_gold, "Rendering reward cannot pay twice")
	main.show_rest()
	main.rest_view.rested.emit()
	check(main.hp == mini(main.max_hp, 52 + int(main.max_hp * 0.3) + 3), "Rest bonus")
	main.start_battle("보스")
	main.show_reward()
	main.advance_map()
	check(main.screen == "story_event" and main.story_event.id == "act1_ledger", "Boss has mandatory story aftermath")
	main.take_story_choice(0)
	check(main.story_flags.has("ward_ledger"), "Mandatory record unlock")
	main.show_codex()
	var codex = main.get_node("Codex")
	check(codex.records["지역"].any(func(r): return r.id == "black_canal"), "Ledger unlocks next region account")
	check(codex.records["스토리"].any(func(r): return r.id == "ward_transfer_ledger"), "Ledger readable in normal codex")
	main.queue_free()
	await process_frame
	print("STORY_CONTENT_QA failures=", failures.size())
	quit(0 if failures.is_empty() else 1)


extends SceneTree
## ACT II: map with fixed story rows, monster pools and patterns (opener, phases, cleanse, side effects), the ACT I -> II step, and every event choice resolving.
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

func begin(main) -> void:
	main.choose_character(main.characters[0])
	main.take_arrival_reward(0)
	main.finish_arrival()

func run():
	var stamp: int = Time.get_ticks_usec()
	D.path = "user://act2_dex_%d.json" % stamp
	T.path = "user://act2_tl_%d.json" % stamp
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	# ---------------- monsters and patterns
	var kinds := {"일반": 0, "엘리트": 0, "보스": 0}
	for m in Data.read("monsters"):
		if int(m.act) != 2: continue
		kinds[m.type] += 1
		check(int(m.hp) > 0 and ResourceLoader.exists(str(m.art)) and not m.pattern.is_empty(), "%s has HP, art and a pattern" % m.id)
		for a in m.pattern + m.get("opener", []):
			check(Actions.kind(a) != "unknown", "%s / %s does something" % [m.id, a.name])
	check(kinds["일반"] >= 5 and kinds["엘리트"] >= 2 and kinds["보스"] == 1, "ACT II roster: %s" % str(kinds))
	var boss: Dictionary = Data.find_record("monsters", "returning_captain")
	check(Actions.pick(boss, 0, 230, 230).name == "입항 보고", "boss opens with its scripted move")
	check(Actions.pick(boss, 1, 230, 230).name == "항로 고수", "then the base pattern")
	check(Actions.pick(boss, 1, 140, 230).name == "나침반 역회전", "below 66%% the first phase takes over (%s)" % Actions.pick(boss, 1, 140, 230).name)
	check(Actions.pick(boss, 1, 60, 230).name == "직인 내리찍기", "below 33%% the last phase takes over (%s)" % Actions.pick(boss, 1, 60, 230).name)
	check(Actions.phase_name(boss, 60, 230) == "마지막 도장", "phase name")
	# ---------------- ACT II map
	await begin(main)
	main.current_act = 2
	main._generate_map()
	var ex = main.expedition
	for row in [3, 8]:
		var members: Array = ex.nodes.filter(func(n): return n.row == row)
		check(not members.is_empty() and members.all(func(n): return n.type == "이벤트" and n.has("fixed_event")), "row %d is a fixed story event" % row)
	check(ex.nodes.filter(func(n): return n.row == 3)[0].fixed_event == "act2_cargo_scale", "row 3 is the cargo scale")
	check(ex.nodes.filter(func(n): return n.row == 8)[0].fixed_event == "act2_bypass_sluice", "row 8 is the sluice")
	check(ex.nodes.filter(func(n): return n.type == "엘리트").size() >= 1 and ex.nodes.back().type == "보스", "elite present, boss last")
	# enemies come from ACT II only
	for kind in ["전투", "엘리트", "보스"]:
		for i in 6:
			check(int(main.pick_enemy(kind).act) == 2, "%s pool is ACT II" % kind)
	# ---------------- the pattern actions act
	main.start_battle("전투")
	main.enemy = Data.find_record("monsters", "silt_mass")
	main.enemy_status.set_amount("poison", 7)
	main.enemy_prepare(main.enemy.pattern[0])
	check(main.enemy_status.amount("poison") == 3, "silt mass cleanses 4 poison (%d)" % main.enemy_status.amount("poison"))
	var before: int = main.discard_pile.size()
	main.enemy = Data.find_record("monsters", "dock_assessor")
	main.enemy_prepare(main.enemy.pattern[2])
	check(main.discard_pile.size() == before + 1 and main.discard_pile.back().id == "side_effect", "a fine adds a side effect card")
	# ---------------- ACT I -> ACT II
	await begin(main)
	main.expedition.completed = true
	main.show_map()
	await process_frame
	var go := false
	for b in main.find_children("*", "Button", true, false):
		if str(b.text).begins_with("ACT II"): go = true
	check(go, "the cleared ACT I map offers the way down")
	var hp_low: int = maxi(1, main.max_hp / 2)
	main.hp = hp_low
	main.begin_next_act()
	await process_frame
	check(main.current_act == 2 and main.screen == "story_event" and main.story_event.id == "act2_arrival", "ACT II opens with its arrival")
	check(main.hp == mini(main.max_hp, hp_low + ceili(main.max_hp * 0.3)), "30%% of max HP restored")
	check(main.run_log.act_reached == 2 and main.run_log.act_start == 2, "a fresh timeline log starts at ACT II")
	main.take_story_choice(0)
	main.arrival_view.continue_requested.emit()
	await process_frame
	check(main.screen == "map" and main.expedition.act == 2, "then the ACT II map")
	# fixed row 3 node opens the cargo scale
	main.expedition.current_id = main.expedition.nodes.filter(func(n): return n.row == 2)[0].id
	var node: Dictionary = main.expedition.nodes.filter(func(n): return n.row == 3)[0]
	main.expedition.nodes[main.expedition.current_id].next = [node.id]
	main.enter_node(node.id)
	await process_frame
	check(main.screen == "story_event" and main.story_event.id == "act2_cargo_scale", "row 3 opens the cargo scale")
	# ---------------- every ACT II event choice resolves
	var events: Array = Data.read("events").filter(func(e): return int(e.get("act", 0)) == 2)
	check(events.size() >= 19, "ACT II events registered (%d)" % events.size())
	for ev in events:
		var count: int = ev.choices.size()
		for i in count:
			await begin(main)
			main.current_act = 2
			main.gold = 200
			main.hp = main.max_hp - 15
			main.show_story_event(ev.id)
			await process_frame
			var hp0: int = main.hp
			var gold0: int = main.gold
			if i >= main.story_event.choices.size(): continue
			var available: bool = not main.story_event.choices[i].get("disabled", false)
			if not available: continue
			main.take_story_choice(i)
			check(main.story_choice_taken and main.hp > 0, "%s choice %d resolves" % [ev.id, i])
			var line: String = main.story_event.choices[i].get("effect_line", "")
			var choice: Dictionary = main.story_event.choices[i]
			if (choice.has("gold_gain") or choice.has("hp_cost") or choice.has("heal")) and not choice.has("outcomes"):
				check(line != "", "%s choice %d shows its effect" % [ev.id, i])
	# the boss intro starts the boss fight, the stamp follows the win
	await begin(main)
	main.current_act = 2
	main._generate_map()
	var last: Dictionary = main.expedition.nodes.back()
	main.expedition.current_id = main.expedition.nodes[last.id - 1].id
	main.expedition.nodes[main.expedition.current_id].next = [last.id]
	main.enter_node(last.id)
	await process_frame
	check(main.story_event.id == "act2_captain_intro", "the boss node opens the captain's report first")
	main.take_story_choice(0)
	main.arrival_view.continue_requested.emit()
	await process_frame
	check(main.screen == "battle" and main.enemy.id == "returning_captain", "then the fight itself")
	main.screen = "reward"
	main.advance_map()
	await process_frame
	check(main.story_event.id == "act2_stamp", "the win leads to the stamp")
	print("ACT2_QA failures=", failures)
	main.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)

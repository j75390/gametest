extends SceneTree
## ACT III (유리 온실): roster and phases, fixed rows, the step down from ACT II with flag-dependent lines, every event choice, boss intro and the formula scene.
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
	D.path = "user://act3_dex_%d.json" % stamp
	T.path = "user://act3_tl_%d.json" % stamp
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var kinds := {"일반": 0, "엘리트": 0, "보스": 0}
	for m in Data.read("monsters"):
		if int(m.act) != 3: continue
		kinds[m.type] += 1
		check(int(m.hp) > 0 and ResourceLoader.exists(str(m.art)) and not m.pattern.is_empty(), "%s has HP, art and a pattern" % m.id)
		for a in m.pattern + m.get("opener", []):
			check(Actions.kind(a) != "unknown", "%s / %s does something" % [m.id, a.name])
	check(kinds["일반"] >= 5 and kinds["엘리트"] >= 2 and kinds["보스"] == 1, "ACT III roster: %s" % str(kinds))
	var boss: Dictionary = Data.find_record("monsters", "grafted_director")
	check(Actions.pick(boss, 0, 275, 275).name == "회진 시작", "boss opener")
	check(Actions.pick(boss, 1, 160, 275).name == "접붙인 팔", "phase 1 at 66pct (%s)" % Actions.pick(boss, 1, 160, 275).name)
	check(Actions.pick(boss, 1, 80, 275).name == "모든 환자의 목소리", "phase 2 at 33pct")
	await begin(main)
	main.current_act = 3
	main._generate_map()
	for row in [3, 8]:
		var members: Array = main.expedition.nodes.filter(func(n): return n.row == row)
		check(members.all(func(n): return n.type == "이벤트" and n.has("fixed_event")), "row %d fixed" % row)
	check(main.expedition.nodes.filter(func(n): return n.row == 3)[0].fixed_event == "act3_tea", "row 3 is the tea")
	check(main.expedition.nodes.filter(func(n): return n.row == 8)[0].fixed_event == "act3_formula_room", "row 8 is the formula room")
	for kind in ["전투", "엘리트", "보스"]:
		for i in 6: check(int(main.pick_enemy(kind).act) == 3, "%s pool is ACT III" % kind)
	# ACT II -> III with earlier choices shaping the first page
	await begin(main)
	main.current_act = 2
	main._generate_map()
	main.expedition.completed = true
	main.story_flags["canal_full_stop"] = true
	main.story_flags["village_short_mill"] = true
	main.begin_next_act()
	await process_frame
	check(main.current_act == 3 and main.story_event.id == "act3_arrival", "ACT III opens with its arrival")
	var joined := " ".join(main.story_event.dialogue)
	check(joined.contains("명패에 이름을 적고") and joined.contains("물방앗간"), "earlier choices change the arrival text")
	check(main.run_log.act_start == 3, "timeline log starts at ACT III")
	var events: Array = Data.read("events").filter(func(e): return int(e.get("act", 0)) == 3)
	check(events.size() >= 19, "ACT III events registered (%d)" % events.size())
	for ev in events:
		for i in ev.choices.size():
			await begin(main)
			main.current_act = 3
			main.gold = 200
			main.hp = main.max_hp - 15
			main.story_flags["roen_delivery"] = true
			main.show_story_event(ev.id)
			await process_frame
			if i >= main.story_event.choices.size(): continue
			if main.story_event.choices[i].get("disabled", false): continue
			main.take_story_choice(i)
			check(main.story_choice_taken and main.hp > 0, "%s choice %d resolves" % [ev.id, i])
			if not main.story_pending_battle.is_empty(): check(["전투", "엘리트", "보스"].has(main.story_pending_battle), "%s battle kind is valid" % ev.id)
	# the memory potion's gamble stores its flag; the formula scene closes the act
	await begin(main)
	main.current_act = 3
	main.show_story_event("act3_formula_end")
	await process_frame
	main.take_story_choice(1)
	check(main.story_flags.has("formula_published") and main.story_flags.has("act3_cleared"), "the published formula is recorded")
	await begin(main)
	main.current_act = 3
	main._generate_map()
	var last: Dictionary = main.expedition.nodes.back()
	main.expedition.current_id = main.expedition.nodes[last.id - 1].id
	main.expedition.nodes[main.expedition.current_id].next = [last.id]
	main.enter_node(last.id)
	await process_frame
	check(main.story_event.id == "act3_director_intro", "the boss node opens the round first")
	main.take_story_choice(0)
	main.arrival_view.continue_requested.emit()
	await process_frame
	check(main.screen == "battle" and main.enemy.id == "grafted_director", "then the fight")
	main.screen = "reward"
	main.advance_map()
	await process_frame
	check(main.story_event.id == "act3_formula_end", "the win leads to the formula scene")
	print("ACT3_QA failures=", failures)
	main.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)

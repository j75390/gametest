extends SceneTree
## Event choices spell out their real effects, and the Mira ward / coat events carry costs and gains that match the text.
const D = preload("res://scripts/codex_discovery.gd")
const T = preload("res://scripts/timeline.gd")
const Rules = preload("res://scripts/story_rules.gd")
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _initialize(): run.call_deferred()

func buttons(node: Node, found: Array) -> Array:
	for child in node.get_children():
		if child is Button: found.append(child)
		buttons(child, found)
	return found

func start(main, id: String) -> void:
	main.choose_character(main.characters[0])
	main.take_arrival_reward(0)
	main.finish_arrival()
	main.hp = main.max_hp - 10
	main.gold = 100
	main.show_story_event(id)
	await process_frame
	await process_frame
	main.arrival_view.finish_typing()
	await create_timer(2.0).timeout

func run():
	var stamp: int = Time.get_ticks_usec()
	D.path = "user://evfx_dex_%d.json" % stamp
	T.path = "user://evfx_tl_%d.json" % stamp
	# pure summary text
	check(Rules.effect_summary({"hp_cost": 4, "max_hp_gain": 4}) == "HP 4 잃음 · 최대 HP +4", "cost then gain")
	check(Rules.effect_summary({"curse_add": 1, "card_upgrade": 1}) == "부작용 카드 1장 추가 · 무작위 카드 1장 강화", "curse and upgrade")
	check(Rules.effect_summary({"outcomes": [{"weight": 55, "gold_gain": 25}, {"weight": 45, "battle": "전투"}]}).contains("55% 골드 25 획득 / 45% 전투 발생"), "outcome odds shown")
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await start(main, "empty_ward")
	get_root().get_viewport().get_texture().get_image().save_png("res://docs/event-ward-1440.png")
	var texts: Array = []
	for b in buttons(main, []): texts.append(b.text)
	var shown := 0
	for t in texts: if t.contains("▶"): shown += 1
	check(shown >= 2, "ward choices show effect lines (%d)" % shown)
	var deck0: int = main.deck.size()
	var upgraded0 := 0
	for c in main.deck: if c.get("upgraded", false): upgraded0 += 1
	main.take_story_choice(0)
	var upgraded1 := 0
	for c in main.deck: if c.get("upgraded", false): upgraded1 += 1
	check(main.deck.size() == deck0 + 1 and main.deck.back().id == "side_effect", "plate: a side effect card joins the deck")
	check(upgraded1 == upgraded0 + 1, "plate: one card upgraded")
	await start(main, "empty_ward")
	var hp0: int = main.hp
	var max0: int = main.max_hp
	main.take_story_choice(1)
	check(main.max_hp == max0 + 4 and main.hp == hp0 - 4 + 4, "copy: -4 hp, +4 max (hp %d -> %d, max %d -> %d)" % [hp0, main.hp, max0, main.max_hp])
	await start(main, "common_act1_12")
	texts.clear()
	for b in buttons(main, []): texts.append(b.text)
	var gamble := false
	for t in texts: if t.contains("55%") and t.contains("전투"): gamble = true
	check(gamble, "gamble choice lists its odds")
	await process_frame
	get_root().get_viewport().get_texture().get_image().save_png("res://docs/event-effects-1440.png")
	print("EVENT_EFFECTS_QA failures=", failures)
	main.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)

extends SceneTree
var failures: Array[String] = []
func check(ok: bool, text: String):
	if not ok:
		failures.append(text)
		push_error(text)
func _initialize(): run.call_deferred()
func point_at(point: Vector2):
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	root.push_input(motion)
	await process_frame
func button(pressed: bool, point: Vector2, which := MOUSE_BUTTON_LEFT):
	await point_at(point)
	var event := InputEventMouseButton.new()
	event.position = point
	event.global_position = point
	event.button_index = which
	event.pressed = pressed
	root.push_input(event)
	await process_frame
func capture(file: String):
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/mira-hand-" + file + ".png")
func run():
	root.size = Vector2i(1440, 900)
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	main.choose_character(main.characters[0])
	main.start_battle("전투")
	main.enemy_hp = 100
	main.enemy_max_hp = 100
	main.hand = [main.card_db.common[0].duplicate(true), main.card_db.common[1].duplicate(true), main.card_db.mira[0].duplicate(true), main.card_db.mira[1].duplicate(true), main.card_db.mira[2].duplicate(true)]
	main.show_battle()
	await process_frame
	await process_frame
	var hand = main.content.get_node("Hand")
	check(main.content.get_node("BattleControls").get_global_rect().end.y <= 880, "Controls fit 1440x900")
	var first: Vector2 = hand.views[0].get_global_rect().get_center()
	var enemy: Vector2 = hand.target.get_global_rect().get_center()
	await button(true, first)
	check(hand.selected == 0, "Press selects card")
	await point_at(enemy)
	check(main.energy == 3 and main.enemy_hp == 100, "Aiming does not spend")
	await capture("aim")
	await button(false, enemy)
	while main.battle_busy: await process_frame
	await process_frame
	await process_frame
	check(main.enemy_hp == 94 and main.energy == 2 and main.hand.size() == 4, "Drag commits exactly once")
	hand = main.content.get_node("Hand")
	# Cancel targeted skill by releasing outside target.
	var skill: Vector2 = hand.views[1].get_global_rect().get_center()
	await button(true, skill)
	await button(false, Vector2(30, 260))
	check(hand.selected == -1 and main.energy == 2 and main.hand.size() == 4, "Outside drop cancels")
	await button(true, skill)
	await button(false, skill)
	check(hand.selected == 1, "Click retains target selection")
	await button(true, skill, MOUSE_BUTTON_RIGHT)
	check(hand.selected == -1, "Right click cancels")
	await button(false, skill, MOUSE_BUTTON_RIGHT)
	await button(true, skill)
	await button(false, skill)
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	root.push_input(escape)
	await process_frame
	check(hand.selected == -1 and main.energy == 2, "Escape cancels without spending")
	# Click card, then target commits a spell without dragging.
	await button(true, skill)
	await button(false, skill)
	await button(true, enemy)
	await button(false, enemy)
	while main.battle_busy: await process_frame
	await process_frame
	await process_frame
	check(main.venom_turns == 3 and main.energy == 1, "Click then target casts venom")
	hand = main.content.get_node("Hand")
	var self_card: Vector2 = hand.views[0].get_global_rect().get_center()
	var before_defense: int = main.block
	await button(true, self_card)
	await button(false, self_card)
	while main.battle_busy: await process_frame
	await process_frame
	await process_frame
	check(main.block == before_defense + 5 and main.energy == 0, "Self card adds defense without enemy")
	hand = main.content.get_node("Hand")
	var expensive: Vector2 = hand.views[0].get_global_rect().get_center()
	await button(true, expensive)
	await button(false, expensive)
	check(hand.selected == -1 and not main.battle_busy, "Insufficient energy blocks selection")
	await capture("rest")
	main.player_status.apply([{"id":"poison","amount":2},{"id":"venom","amount":3,"rate":0.08}])
	main.enemy_status.apply([{"id":"poison","amount":4},{"id":"venom","amount":2,"rate":0.08}])
	main.show_battle()
	await process_frame
	await process_frame
	var hero = main.content.get_node("BattleStage/Hero")
	check(hero.tooltip_text.contains("독 · 2중첩") and hero.tooltip_text.contains("맹독 · 3턴"), "Body tooltip aggregates statuses")
	var poison_icon = main.content.get_node("UnitStatuses/Player").find_child("poison", true, false)
	check(poison_icon.tooltip_text.begins_with("독 · 2중첩"), "Icon tooltip selects its own status")
	check(main.content.get_node("Intent").tooltip_text.contains("공격 피해"), "Intent tooltip describes attack")
	root.warp_mouse(hero.get_global_rect().get_center())
	await point_at(hero.get_global_rect().get_center())
	await create_timer(1.0).timeout
	await capture("tooltip")
	print("MIRA_HAND_QA failures=%d" % failures.size())
	quit(0 if failures.is_empty() else 1)

extends SceneTree
var failures := 0
func _initialize(): run.call_deferred()
func check(ok: bool, detail: String):
	if not ok:
		failures += 1
		push_error(detail)
func run():
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	main.choose_character(main.characters[0])
	main.start_battle("전투")
	main.hand = [main.card_db.common[0].duplicate(true), main.card_db.common[1].duplicate(true), main.card_db.mira[0].duplicate(true), main.card_db.mira[1].duplicate(true), main.card_db.mira[2].duplicate(true)]
	main.show_battle()
	await create_timer(0.3).timeout
	for dimensions in [Vector2i(1440,900), Vector2i(1280,720)]:
		root.size = dimensions
		await create_timer(0.3).timeout
		var hand = main.content.get_node("Hand")
		for card in hand.views:
			check(card.size == Vector2(220,330), "Card must stay portrait")
			check(card.get_node("Effect").size.x <= 159, "Effect overflow width")
			check(card.get_node("Effect").position.y + card.get_node("Effect").size.y <= 299, "Effect overflow height")
			check(not card.get_node("Energy").text.contains("."), "Energy must be integer")
		check(hand.angles[0] < 0 and hand.angles[4] > 0, "Fan rotations absent")
		check(hand.homes[1].x - hand.homes[0].x < 220 * 0.88, "Cards must overlap")
		var event := InputEventMouseMotion.new()
		event.position = hand.views[2].get_global_transform() * Vector2(70,160)
		root.push_input(event, true)
		await create_timer(0.3).timeout
		check(hand.hovered == 2 and hand.views[2].z_index == 30, "Hover must bring card forward")
		check(absf(hand.views[2].rotation) < 0.01, "Hover card must straighten")
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png("res://docs/card-hand-%d.png" % dimensions.x) == OK, "Capture failed")
	main.show_menu()
	await process_frame
	check(main.content.size_flags_vertical == Control.SIZE_FILL, "Battle layout not restored")
	print("CARD_SHAPE_QA resolutions=2 failures=", failures)
	main.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)

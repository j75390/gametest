extends SceneTree
var failures: Array[String] = []
func check(ok: bool, text: String):
	if not ok:
		failures.append(text)
		push_error(text)
func _initialize(): run.call_deferred()
func click(point: Vector2):
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event)
		await process_frame
func key(code: Key):
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	root.push_input(event)
	await process_frame
func capture(file: String):
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/pile-viewer-" + file + ".png")
func run():
	root.size = Vector2i(1440, 900)
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	main.choose_character(main.characters[0])
	main.take_arrival_reward(0)
	main.finish_arrival()
	main.start_battle("전투")
	await process_frame
	await process_frame
	var scene = main.content
	var hand = scene.get_node("Hand")
	var draw_count: int = main.draw_pile.size()
	var discard_count: int = main.discard_pile.size()
	check(scene.get_node("DrawPile").title.begins_with("뽑을 카드 더미"), "Draw pile tooltip title")
	check(scene.get_node("DrawPile").body.contains("5장"), "Draw pile tooltip explains drawing")
	var pile_center: Vector2 = scene.get_node("DrawPile").get_global_rect().get_center()
	root.warp_mouse(pile_center)
	var motion := InputEventMouseMotion.new()
	motion.position = pile_center
	motion.global_position = pile_center
	root.push_input(motion)
	await create_timer(1.2).timeout
	await capture("tooltip")
	# Draw pile via click on the icon.
	await click(scene.get_node("DrawPile").get_global_rect().get_center())
	await process_frame
	var viewer = scene.get_node_or_null("PileViewer")
	check(viewer != null, "Clicking the draw pile opens the viewer")
	check(hand.locked, "Hand is locked while the viewer is open")
	if viewer:
		check(viewer.get_node("Heading").text.contains(str(draw_count)), "Heading shows the draw pile size")
		var grid = viewer.get_node("Scroll").get_child(0)
		check(grid.get_child_count() == draw_count, "Viewer shows every draw pile card")
		await capture("draw")
		# Playing cards must not be possible behind the viewer.
		var energy_before: int = main.energy
		await click(hand.views[0].get_global_rect().get_center())
		check(main.energy == energy_before and hand.selected == -1, "Cards behind the viewer cannot be played")
		await click(viewer.get_node("Back").get_global_rect().get_center())
		await process_frame
	check(scene.get_node_or_null("PileViewer") == null, "Back button closes the viewer")
	check(not hand.locked, "Hand unlocks after closing")
	# Keyboard: S opens the discard pile, Escape closes it.
	await key(KEY_S)
	viewer = scene.get_node_or_null("PileViewer")
	check(viewer != null and viewer.get_node("Heading").text.contains("버린"), "S opens the discard pile")
	await key(KEY_ESCAPE)
	await process_frame
	check(scene.get_node_or_null("PileViewer") == null, "Escape closes the viewer")
	# Deck viewer with all cards, then A while it is open must not stack another viewer.
	await key(KEY_D)
	viewer = scene.get_node_or_null("PileViewer")
	check(viewer != null and viewer.get_node("Scroll").get_child(0).get_child_count() == main.deck.size(), "D opens the full deck")
	await key(KEY_A)
	check(scene.get_children().filter(func(n): return n.name.begins_with("PileViewer")).size() == 1, "Only one viewer at a time")
	await capture("deck")
	await key(KEY_ESCAPE)
	await process_frame
	check(draw_count + discard_count + main.hand.size() == main.deck.size(), "Pile sizes still add up to the deck")
	print("PILE_VIEWER_QA failures=%d" % failures.size())
	quit(0 if failures.is_empty() else 1)

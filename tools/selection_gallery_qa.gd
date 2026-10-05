extends SceneTree
func _initialize(): run.call_deferred()
func run():
	var data = preload("res://scripts/game_data.gd")
	for dimensions in [Vector2i(1440,900),Vector2i(1280,720)]:
		root.size = dimensions
		var view = load("res://scripts/character_select.gd").new()
		view.setup(data.read("characters"))
		root.add_child(view)
		await create_timer(0.3).timeout
		for i in range(view.roster.size()):
			view._select(i)
			assert(view.heading.text == view.roster[i].name)
		view._select(0)
		var choice = []
		view.character_chosen.connect(func(ch): choice.append(ch.id))
		view.canvas.get_node("StartExpedition").pressed.emit()
		assert(choice == ["mira"])
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/selection-gallery-%d.png" % dimensions.x)
		view.queue_free()
		await process_frame
	print("SELECTION_GALLERY_QA PASS")
	quit()

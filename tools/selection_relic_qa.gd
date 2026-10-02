extends SceneTree
func _initialize(): run.call_deferred()
func run():
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	main.show_character_select()
	await create_timer(0.3).timeout
	var view = main.get_node("CharacterSelection")
	assert(view.relic_art.texture != null)
	assert(view.relic_name.text.contains("빛바랜 초승달"))
	for dimensions in [Vector2i(1440,900), Vector2i(1280,720)]:
		root.size = dimensions
		await create_timer(0.3).timeout
		assert(view.relic_effect.position.y + view.relic_effect.size.y <= 674)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/selection-relic-%d.png" % dimensions.x)
	view._select(1)
	assert(view.relic_art.texture == null)
	view._select(0)
	view.character_chosen.emit(main.characters[0])
	await process_frame
	assert(main.owned_relics == ["mira_crescent"])
	main.start_battle("전투")
	assert(main.block == 3)
	main.choose_character(main.characters[0])
	assert(main.owned_relics.size() == 1)
	main.choose_character(main.characters[1])
	assert(main.owned_relics.is_empty())
	main.start_battle("전투")
	assert(main.block == 0)
	print("SELECTION_RELIC_QA PASS: two resolutions, selection, grant, effect, reset")
	main.queue_free()
	await process_frame
	quit()

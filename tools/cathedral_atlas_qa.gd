extends SceneTree
const D = preload("res://scripts/codex_discovery.gd")
func _initialize(): run.call_deferred()
func run():
	D.path = "user://atlas_qa_%d.json" % Time.get_ticks_usec()
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	main.choose_character(main.characters[0])
	main._generate_map()
	main.show_cathedral_atlas()
	var atlas = main.get_node("CathedralAtlas")
	atlas._inspect(atlas.PLACES[2])
	assert(not main.story_flags.has("cathedral_mended_cover"))
	atlas.progress = 5
	atlas._inspect(atlas.PLACES[2])
	atlas._inspect(atlas.PLACES[1])
	assert(main.story_flags.has("cathedral_mended_cover"))
	assert(main.story_flags.has("cathedral_stamps"))
	atlas.queue_free()
	await process_frame
	for resolution in [Vector2i(1440,900), Vector2i(1280,720)]:
		root.size = resolution
		main.story_flags["ward_ledger"] = true
		main.show_cathedral_atlas()
		atlas = main.get_node("CathedralAtlas")
		await create_timer(.3).timeout
		atlas._inspect(atlas.PLACES[2])
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/cathedral-atlas-%d.png" % resolution.x)
		atlas.queue_free()
		await process_frame
	var book = load("res://scripts/codex.gd").new()
	book.story_flags = main.story_flags.duplicate()
	root.add_child(book)
	assert(book.records["스토리"].any(func(r): return r.id == "cathedral_stamps"))
	assert(book.records["지역"].any(func(r): return r.id == "basin_atlas"))
	book.queue_free()
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(D.path)
	print("CATHEDRAL_ATLAS_QA PASS")
	quit()

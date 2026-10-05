extends SceneTree
const Data = preload("res://scripts/game_data.gd")
func _initialize(): run.call_deferred()
func run():
	root.size = Vector2i(1440,960)
	var bg := ColorRect.new()
	bg.color = Color("17131e")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var grid := GridContainer.new()
	grid.columns = 6
	grid.position = Vector2(20,20)
	grid.add_theme_constant_override("h_separation",12)
	grid.add_theme_constant_override("v_separation",20)
	root.add_child(grid)
	var jobs = JSON.parse_string(FileAccess.get_file_as_string("res://ai/icon_batch_20261006.json"))
	var library = Data.read("_library")
	for job in jobs:
		var source: Dictionary = {}
		for row in library[job.type]:
			if row.id == job.id: source = row
		assert(not source.is_empty())
		var art: String = source.get("image", source.get("icon", ""))
		assert(ResourceLoader.exists(art))
		var col := VBoxContainer.new()
		col.custom_minimum_size = Vector2(220,280)
		grid.add_child(col)
		var pic := TextureRect.new()
		pic.texture = load(art)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.custom_minimum_size = Vector2(220,220)
		col.add_child(pic)
		var label := Label.new()
		label.text = source.name
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size",19)
		col.add_child(label)
		var state := Label.new()
		state.text = "게임 적용" if source.get("implementation", "proposal") == "playable" else "효과 원고"
		state.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		state.modulate = Color("baaa87")
		col.add_child(state)
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/comfy-batch-18.png")
	assert(Data.read("potions").size() == 4)
	assert(Data.read("relics").size() == 9)
	assert(Data.read("powers").size() == 4)
	print("COMFY_BATCH_QA PASS: 18 textures, gameplay pools preserved")
	quit()

extends SceneTree
const Data = preload("res://scripts/game_data.gd")
const D = preload("res://scripts/codex_discovery.gd")
func _initialize(): run.call_deferred()
func run():
	D.path = "user://story_art_qa_%d.json" % Time.get_ticks_usec()
	var view = load("res://scripts/codex.gd").new()
	root.size = Vector2i(1440,900)
	root.add_child(view)
	assert(not view.records["스토리"].any(func(r): return r.id == "relic_returned_clasp"))
	assert(not Data.read("relics").any(func(r): return r.id == "relic_ancient_001"))
	for row in Data.read("narrative_records"):
		if not row.requires_flag.is_empty(): view.story_flags[row.requires_flag] = true
	view.story_flags["ward_plate"] = true
	view.story_flags["ward_copy"] = true
	view._load_records()
	view._catalog_records()
	var count := 0
	for pair in [["스토리", "ward_plate"], ["스토리", "ward_copy"], ["스토리", "mira_own_abbreviation"], ["지역", "region_canal_weight"], ["지역", "region_garden_cups"], ["스토리", "relic_plate_two_sides"], ["스토리", "relic_joint_signatures"], ["스토리", "relic_returned_clasp"]]:
		view._change_category(pair[0])
		for record in view.records[pair[0]]:
			if record.id != pair[1]: continue
			assert(ResourceLoader.exists(record.art))
			view._select(record)
			await create_timer(0.15).timeout
			assert(view.detail_box.get_node("StoryScene").get_child(0).texture != null)
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://docs/art-%s.png" % pair[1])
			count += 1
	assert(count == 8)
	view.queue_free()
	await process_frame
	DirAccess.remove_absolute(D.path)
	print("MIRA_STORY_ART_QA PASS: eight illustrated records, spoiler gates, draft relic exclusion")
	quit()

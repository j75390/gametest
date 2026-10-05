extends SceneTree
func _initialize(): run.call_deferred()
func run():
	for resolution in [Vector2i(1440,900), Vector2i(1280,720)]:
		root.size = resolution
		var view = load("res://scripts/codex.gd").new()
		root.add_child(view)
		view._change_category("스토리")
		assert(view.records["스토리"].size() == 2)
		for record in view.records["스토리"]:
			view._select(record)
			await create_timer(0.2).timeout
			assert(not view.art_box.get_parent().visible)
			var scene = view.detail_box.get_node("StoryScene")
			var prose = view.detail_box.get_node("StoryProse")
			assert(scene.size.x > 500)
			assert(scene.size.y >= 300)
			assert(prose.global_position.y >= scene.global_position.y + scene.size.y)
			assert(prose.size.x <= view.reader_scroll.size.x)
			assert(scene.get_child(0).texture != null)
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://docs/story-%s-%d.png" % [record.id,resolution.x])
		view.queue_free()
		await process_frame
	print("STORY_READER_QA PASS")
	quit()

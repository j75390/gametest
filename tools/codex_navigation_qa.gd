extends SceneTree
var failures := 0
func check(ok, message):
	if not ok:
		failures += 1
		push_error(message)
func _initialize(): run.call_deferred()
func settle():
	await create_timer(0.25).timeout
	await RenderingServer.frame_post_draw
func run():
	for resolution in [Vector2i(1440,900), Vector2i(1280,720)]:
		root.size = resolution
		var codex = load("res://scripts/codex.gd").new()
		root.add_child(codex)
		await settle()
		check(codex.filters.all(func(f): return not f.visible), "Character filters hidden")
		check(codex.detail_panel.get_global_rect().end.x <= root.get_visible_rect().size.x, "Detail fits width")
		root.get_texture().get_image().save_png("res://docs/codex-character-%d.png" % resolution.x)
		var story_count = codex.records["스토리"].size()
		codex._show_character_cards("mira")
		codex._show_character_cards("mira")
		check(codex.records["스토리"].size() == story_count, "No duplicate stories")
		await settle()
		check(codex.catalog_grid.get_child_count() > 0, "Card grid populated")
		root.get_texture().get_image().save_png("res://docs/codex-cards-%d.png" % resolution.x)
		codex.search.text = "NO_MATCH_9381"
		codex._rebuild_list()
		check(codex.active_record.is_empty(), "Empty search clears detail")
		codex._change_category("캐릭터")
		codex._open_review()
		await settle()
		check(codex.review_child.records["유물"].size() == 154, "Review relic count")
		codex.review_child._navigate("유물", "relic_ancient_001")
		await settle()
		root.get_texture().get_image().save_png("res://docs/codex-review-%d.png" % resolution.x)
		codex.review_child.closed.emit()
		await process_frame
		check(codex.category == "캐릭터" and not is_instance_valid(codex.review_child), "Review returns to unchanged reader")
		codex.queue_free()
		await process_frame
	print("CODEX_NAVIGATION_QA failures=", failures)
	quit(failures)

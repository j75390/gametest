extends SceneTree
const D = preload("res://scripts/codex_discovery.gd")
func _initialize(): run.call_deferred()
func run():
	D.path = "user://codex_qa_%d.json" % Time.get_ticks_usec()
	for resolution in [Vector2i(1440,900),Vector2i(1280,720)]:
		root.size = resolution
		var view = load("res://scripts/codex.gd").new()
		root.add_child(view)
		view._change_category("유물")
		assert(view.records["유물"].all(func(r): return r.undiscovered))
		assert(not view.detail_panel.visible)
		for button in view.list_buttons: assert(button.tooltip_text == "미발견\n아직 이 유물을 발견하지 못했습니다.")
		var secret = view.records["유물"][0]
		view.search.text = secret.name
		view._rebuild_list()
		assert(view.list_buttons.is_empty())
		view._change_category("포션")
		for button in view.list_buttons: assert(button.tooltip_text == "미발견\n아직 이 포션을 발견하지 못했습니다.")
		await create_timer(0.3).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/codex-hidden-%d.png" % resolution.x)
		view._change_category("몬스터")
		assert(view.detail_box.get_child(0).text == "미발견")
		view.queue_free()
		await process_frame
	D.record("유물", "mira_crescent")
	D.record("카드", "strike")
	assert(D.has("유물", "mira_crescent"))
	var view = load("res://scripts/codex.gd").new()
	root.add_child(view)
	view._change_category("유물")
	assert(view.records["유물"].any(func(r): return r.id == "mira_crescent" and not r.undiscovered))
	for record in view.records["유물"]: assert(not str(record.stats).contains("획득처"))
	view._change_category("카드")
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/codex-discovery-cards.png")
	view.queue_free()
	await process_frame
	DirAccess.remove_absolute(D.path)
	print("CODEX_DISCOVERY_QA PASS")
	quit()

extends SceneTree
const D = preload("res://scripts/codex_discovery.gd")
const Data = preload("res://scripts/game_data.gd")
const IDS = ["relic_common_001", "relic_common_002", "relic_common_003", "relic_common_004", "relic_common_005", "relic_common_006"]
func _initialize(): run.call_deferred()
func run():
	D.path = "user://relic_art_qa_%d.json" % Time.get_ticks_usec()
	root.size = Vector2i(1440,900)
	for row in Data.read("relics"):
		if row.id in IDS:
			assert(ResourceLoader.exists(row.art))
			assert(load(row.art) is Texture2D)
	var view = load("res://scripts/codex.gd").new()
	root.add_child(view)
	view._change_category("유물")
	for button in view.list_buttons:
		assert(button.tooltip_text == "미발견\n아직 이 유물을 발견하지 못했습니다.")
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/relic-art-hidden.png")
	view.queue_free()
	await process_frame
	for id in IDS: D.record("유물", id)
	view = load("res://scripts/codex.gd").new()
	root.add_child(view)
	view._change_category("유물")
	for row in view.records["유물"]:
		if row.id in IDS: assert(not row.undiscovered)
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/relic-art-visible.png")
	view.queue_free()
	await process_frame
	DirAccess.remove_absolute(D.path)
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	main.choose_character(main.characters[0])
	main.show_shop()
	await process_frame
	var icons := 0
	for slot in main.shop_view.shelf.get_children():
		if slot is Panel:
			for part in slot.get_children():
				if part is TextureRect and part.texture != null:
					icons += 1
	assert(icons >= 6)
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(D.path)
	print("RELIC_ART_QA PASS: six textures, hidden tooltip, discovery rendering, shop icons")
	quit()

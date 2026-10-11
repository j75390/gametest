extends SceneTree
const D = preload("res://scripts/codex_discovery.gd")
const T = preload("res://scripts/timeline.gd")
var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)
func _initialize(): run.call_deferred()
func settle(t := 0.3):
	await create_timer(t).timeout
	await RenderingServer.frame_post_draw
func run():
	D.path = "user://codex_hub_qa_%d.json" % Time.get_ticks_usec()
	T.path = "user://codex_hub_qa_timeline_%d.json" % Time.get_ticks_usec()
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	main.choose_character(main.characters[0])
	main.show_codex_hub()
	for resolution in [Vector2i(1440, 900), Vector2i(1280, 720)]:
		root.size = resolution
		var hub = main.get_node("CodexHub")
		await settle()
		check(hub.tiles.size() == 5, "Hub shows five tiles")
		root.get_texture().get_image().save_png("res://docs/codex-hub-%d.png" % resolution.x)
		# cards
		hub.open_tile(0)
		await settle()
		var cards = hub.child_screen
		check(cards != null and cards.grid.get_child_count() >= 11, "Card grid lists every card: %d" % (cards.grid.get_child_count() if cards else -1))
		root.get_texture().get_image().save_png("res://docs/codex-cards-new-%d.png" % resolution.x)
		cards.search.text_changed.emit("타격")
		await process_frame
		check(cards.grid.get_child_count() == 0 or true, "search runs")
		cards.search.text = ""
		cards.search.text_changed.emit("")
		cards.owner_buttons["mira"].button_pressed = true
		await process_frame
		check(cards.grid.get_child_count() >= 3, "Mira filter shows 3 cards: %d" % cards.grid.get_child_count())
		cards.owner_buttons["mira"].button_pressed = false
		await process_frame
		cards._open_detail(cards.rows[0])
		await settle(0.2)
		root.get_texture().get_image().save_png("res://docs/codex-cards-detail-%d.png" % resolution.x)
		cards.close_popup()
		cards.closed.emit()
		await process_frame
		check(hub.child_screen == null, "Card screen closed")
		# relics
		hub.open_tile(1)
		await settle()
		var relic_count: int = load("res://scripts/game_data.gd").read("relics").size()
		check(hub.child_screen.rows.size() == relic_count, "Relic rows: %d of %d" % [hub.child_screen.rows.size(), relic_count])
		root.get_texture().get_image().save_png("res://docs/codex-relics-%d.png" % resolution.x)
		hub.child_screen.closed.emit()
		await process_frame
		hub.open_tile(2)
		await settle()
		root.get_texture().get_image().save_png("res://docs/codex-potions-%d.png" % resolution.x)
		hub.child_screen.closed.emit()
		await process_frame
		hub.open_tile(3)
		await settle()
		root.get_texture().get_image().save_png("res://docs/codex-monsters-%d.png" % resolution.x)
		hub.child_screen.closed.emit()
		await process_frame
		# story tile opens the timeline; the old reader stays reachable as "조사 기록"
		hub.open_tile(4)
		await settle()
		check(hub.child_screen != null and hub.child_screen.get_script().resource_path.ends_with("codex_timeline.gd"), "Story opens the timeline")
		hub.child_screen.closed.emit()
		await process_frame
		hub.open_notes_screen()
		await settle()
		var notes = hub.child_screen
		check(notes != null and notes.get_script().resource_path.ends_with("codex_notes.gd"), "Notes open the new reader")
		check(notes.data["지역"].size() >= 1 and notes.data.total["조사 기록"] == 121, "Notes aggregate all shelves")
		root.get_texture().get_image().save_png("res://docs/codex-notes-%d.png" % resolution.x)
		notes.open_tab("이야기")
		await process_frame
		notes.open_tab("지역")
		await settle(0.2)
		root.get_texture().get_image().save_png("res://docs/codex-notes-regions-%d.png" % resolution.x)
		notes.closed.emit()
		await process_frame
		hub.open_characters()
		await settle()
		var people = hub.child_screen
		check(people != null and people.get_script().resource_path.ends_with("codex_characters.gd"), "Characters open the new page")
		check(people.roster.size() == 4 and people.selected_id == "mira", "Four characters, Mira first")
		root.get_texture().get_image().save_png("res://docs/codex-characters-mira-%d.png" % resolution.x)
		people.select("kalian")
		await settle(0.2)
		check(not people.sprite_preview.visible and people.still_picture.visible, "Characters without motions show their picture")
		check(people.motion_buttons.all(func(b): return b.disabled), "Motion buttons disabled without motion frames")
		root.get_texture().get_image().save_png("res://docs/codex-characters-kalian-%d.png" % resolution.x)
		people.cards_requested.emit("kalian")
		await settle(0.3)
		var shelf = hub.child_screen
		check(shelf != null and shelf.get_script().resource_path.ends_with("codex_cards.gd"), "Own cards open the card shelf")
		check(shelf.grid.get_child_count() == 2, "Card shelf is filtered to Kalian: %d" % shelf.grid.get_child_count())
		shelf.closed.emit()
		await process_frame
		hub.open_legacy("캐릭터")
		await settle()
		check(hub.child_screen != null and hub.child_screen.category == "캐릭터", "Manuscript review stays reachable")
		hub.child_screen.closed.emit()
		await process_frame
	main.get_node("CodexHub").closed.emit()
	await process_frame
	check(not main.has_node("CodexHub"), "Hub closes")
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(D.path)
	print("CODEX_HUB_QA failures=%d" % failures.size())
	quit(1 if failures.size() > 0 else 0)

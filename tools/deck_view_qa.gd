extends SceneTree
## The deck screen shows card pictures (stacked copies), filters by type and closes back to the map.
const D = preload("res://scripts/codex_discovery.gd")
const T = preload("res://scripts/timeline.gd")
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _initialize(): run.call_deferred()

func run() -> void:
	var stamp: int = Time.get_ticks_usec()
	D.path = "user://deckview_dex_%d.json" % stamp
	T.path = "user://deckview_tl_%d.json" % stamp
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.choose_character(main.characters[0])
	main.take_arrival_reward(0)
	main.finish_arrival()
	for card in main.card_db.get("mira", []).slice(0, 6): main.deck.append(card.duplicate(true))
	await process_frame
	check(main.screen == "map" and main.content.has_node("MapHeader"), "Map shows the new header")
	main.show_deck()
	await process_frame
	var view = main.get_node_or_null("DeckView")
	check(view != null, "Deck view opens")
	if view == null:
		quit(1)
		return
	check(main.screen == "map", "Deck is an overlay: the map screen stays underneath")
	var stacks: Array = view.stacks()
	check(stacks.size() < main.deck.size(), "Identical cards are stacked: %d stacks for %d cards" % [stacks.size(), main.deck.size()])
	var total := 0
	for stack in stacks: total += int(stack.count)
	check(total == main.deck.size(), "Every card is counted: %d of %d" % [total, main.deck.size()])
	check(view.grid.get_child_count() == stacks.size(), "One cell per stack")
	check(view.grid.get_children().all(func(c): return c.find_children("Illustration", "TextureRect", true, false).size() == 1), "Every cell is a card picture")
	view._set_filter("공격")
	await process_frame
	check(view.stacks().all(func(s): return s.card.type == "공격") and view.grid.get_child_count() == view.stacks().size(), "Filter keeps only attacks")
	main.show_deck()
	check(main.get_children().filter(func(c): return c.name == "DeckView").size() == 1, "Opening twice keeps one deck view")
	view._set_filter("전체")
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/deck-view.png")
	view.close_view()
	await process_frame
	await process_frame
	check(main.get_node_or_null("DeckView") == null, "Closing removes the deck view")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/map-header.png")
	for file in [D.path, T.path, T.path + ".bak", T.path + ".tmp"]:
		if FileAccess.file_exists(file): DirAccess.remove_absolute(file)
	print("DECK_VIEW_QA failures=", failures)
	quit(1 if failures > 0 else 0)

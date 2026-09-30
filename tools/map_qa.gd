extends SceneTree
const Graph = preload("res://scripts/expedition_map.gd")
var failures: Array[String] = []

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var fingerprints: Dictionary = {}
	for seed_value in range(200):
		var graph = Graph.new()
		graph.generate(seed_value)
		var signature = JSON.stringify(graph.nodes)
		fingerprints[signature] = true
		var same = Graph.new()
		same.generate(seed_value)
		check(signature == JSON.stringify(same.nodes), "Seed reproducibility")
		var reachable: Array = [0]
		for node in graph.nodes:
			check(reachable.has(node.id), "Orphan node")
			check(node.row == Graph.ROWS - 1 or not node.next.is_empty(), "Dead end")
			for target in node.next:
				check(graph.nodes[target].row == node.row + 1, "Invalid edge")
				for other in graph.nodes:
					if other.row == node.row and other.lane > node.lane:
						for other_target in other.next:
							check(graph.nodes[target].lane <= graph.nodes[other_target].lane, "Crossing edge")
				if not reachable.has(target):
					reachable.append(target)
		check(graph.visible().all(func(id): return graph.nodes[id].row <= 2), "Starting fog leaked")
		check(graph.visible(true).size() == graph.nodes.size(), "Relic reveal")
		while not graph.completed:
			var previously_seen: Array = graph.visible().duplicate()
			var options: Array = graph.available().duplicate()
			check(not options.is_empty(), "Route blocked")
			if options.is_empty():
				break
			var target: int = options[seed_value % options.size()]
			check(graph.enter(target), "Legal move rejected")
			check(graph.available().is_empty(), "Encounter permits double move")
			check(not graph.enter(target), "Encounter repeated")
			var shown = graph.visible()
			for id in previously_seen:
				check(shown.has(id), "Unchosen revealed branch disappeared")
			for id in graph.visited:
				check(shown.has(id), "Visited path lost")
			for id in shown:
				check(graph.visited.has(id) or graph.nodes[id].row <= graph.nodes[target].row + 2, "Future fog leaked")
			graph.resolve()
		check(graph.available().is_empty(), "Boss replay possible")
	check(fingerprints.size() == 200, "New seed failed to change route")
	print("MAP_GRAPH_QA seeds=200 failures=", failures.size())
	if DisplayServer.get_name() == "headless":
		quit(0 if failures.is_empty() else 1)
		return
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	main.choose_character(main.characters[0])
	await process_frame
	await process_frame
	var view = main.content.get_node("ExpeditionScroll/RouteMap")
	for kind in view.ICONS:
		var icon_path: String = "res://assets/map/icons/%s.png" % view.ICONS[kind]
		check(ResourceLoader.exists(icon_path), "Missing generated icon: " + kind)
		if ResourceLoader.exists(icon_path):
			var texture: Texture2D = load(icon_path)
			check(texture.get_image().detect_alpha() != Image.ALPHA_NONE, "Icon has no transparency: " + kind)
			check(texture.get_image().has_mipmaps(), "Icon missing mipmaps: " + kind)
	for node_button in view.buttons.values():
		check(node_button.icon.resource_path.ends_with(".png"), "Map still uses old line icon")
	check(view.buttons.size() == main.expedition.visible().size(), "Hidden hit targets exist")
	var map_scroll = main.content.get_node("ExpeditionScroll")
	var scroll_before: int = map_scroll.scroll_vertical
	var wheel := InputEventMouseButton.new()
	wheel.position = map_scroll.get_global_rect().get_center()
	wheel.global_position = wheel.position
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	root.push_input(wheel)
	var wheel_release = wheel.duplicate()
	wheel_release.pressed = false
	root.push_input(wheel_release)
	await process_frame
	check(map_scroll.scroll_vertical < scroll_before, "Map mouse wheel did not scroll")
	map_scroll.scroll_vertical = scroll_before
	await process_frame
	var id: int = main.expedition.available()[0]
	var original_seed: int = main.expedition.run_seed
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/map-fog.png")
	var click := InputEventMouseButton.new()
	click.position = view.buttons[id].get_global_rect().get_center()
	click.global_position = click.position
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	var move := InputEventMouseMotion.new()
	move.position = click.position
	move.global_position = click.position
	root.push_input(move)
	root.push_input(click)
	await process_frame
	var release = click.duplicate()
	release.pressed = false
	root.push_input(release)
	await process_frame
	check(main.expedition.current_id == id and main.screen == "battle", "Map button failed to enter battle")
	main.enter_node(main.expedition.nodes.size() - 1)
	check(main.expedition.current_id == id, "Nonadjacent move allowed")
	main.enemy_hp = 1
	main.hand = [main.card_db.common[0].duplicate(true)]
	await main.play_card(0)
	check(main.screen == "reward", "Battle reward missing")
	main.advance_map()
	await process_frame
	await process_frame
	check(main.expedition.run_seed == original_seed, "Map rerolled mid-run")
	check(main.expedition.nodes[id].cleared and main.expedition.visited.has(id), "Completion not recorded")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/map-progress.png")
	main.has_full_map = true
	main.show_map()
	await process_frame
	await process_frame
	view = main.content.get_node("ExpeditionScroll/RouteMap")
	check(view.buttons.size() == main.expedition.nodes.size(), "Full map controls missing")
	check(view.buttons.values().filter(func(b): return not b.disabled).size() == main.expedition.available().size(), "Relic unlocked unreachable nodes")
	main.content.get_node("ExpeditionScroll").scroll_vertical = 0
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/map-relic.png")
	print("MAP_UI_QA failures=", failures.size())
	main.queue_free()
	await process_frame
	await process_frame
	quit(0 if failures.is_empty() else 1)

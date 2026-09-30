extends SceneTree
## Render all generated location icons at their real node size for visual QA.
func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var graph = load("res://scripts/expedition_map.gd").new()
	graph.generate(930)
	var view = load("res://scripts/map_view.gd").new()
	for index in range(view.ICONS.size()):
		graph.nodes[index].type = view.ICONS.keys()[index]
	root.add_child(view)
	view.size = Vector2(1440, 1770)
	view.setup(graph, true)
	var preview := Control.new()
	root.add_child(preview)
	preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := ColorRect.new()
	backdrop.color = Color("19151d")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	preview.add_child(backdrop)
	var i := 0
	for kind in view.ICONS:
		var node_id := -1
		for node in graph.nodes:
			if node.type == kind:
				node_id = node.id
				break
		if node_id >= 0:
			var button = view.buttons[node_id].duplicate()
			preview.add_child(button)
			button.position = Vector2(150 + (i % 4) * 310, 180 + (i / 4) * 270)
			i += 1
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/map-icons-preview.png")
	preview.queue_free()
	view.queue_free()
	await process_frame
	quit()

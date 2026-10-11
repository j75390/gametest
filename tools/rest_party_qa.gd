extends SceneTree
## Campfire seating for 1..4 party members: everyone fits on the canvas, stays above the option panels and keeps clear of the fire.
const RestView = preload("res://scripts/rest_view.gd")
var failures: Array[String] = []

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	root.size = Vector2i(1440, 900)
	var lineup := ["mira", "kalian", "sera", "lucian"]
	for count in range(1, 5):
		var view := RestView.new()
		view.setup({"character": "mira", "party": lineup.slice(0, count), "rest_amount": 21, "hp": 42, "max_hp": 72}, [])
		root.add_child(view)
		await process_frame
		await process_frame
		await create_timer(0.3).timeout
		var heroes: Array = []
		for child in view.canvas.get_children():
			if str(child.name).begins_with("RestHero_"): heroes.append(child)
		check(heroes.size() == count, "%d seated expected, found %d" % [count, heroes.size()])
		for hero in heroes:
			var rect: Rect2 = Rect2(hero.position, hero.size)
			check(rect.position.x >= 0 and rect.end.x <= 1440, "%s sticks out sideways with %d" % [hero.name, count])
			check(rect.position.y >= 120, "%s reaches the title with %d" % [hero.name, count])
			check(rect.end.y <= 700, "%s covers the option panels with %d" % [hero.name, count])
		# the fire itself must not be hidden behind a seated hero
		var flame: Control = view.canvas.get_node("Flame")
		var flame_rect := Rect2(flame.position, flame.size).grow(-20)
		for hero in heroes:
			if hero.position.y + hero.size.y < 540: continue
			var body := Rect2(hero.position + hero.size * Vector2(0.2, 0.2), hero.size * Vector2(0.6, 0.7))
			check(not body.intersects(flame_rect), "%s overlaps the flames with %d" % [hero.name, count])
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/rest-party-%d-1440.png" % count)
		view.queue_free()
		await process_frame
	print("REST_PARTY_QA failures=", failures.size())
	quit(0 if failures.is_empty() else 1)

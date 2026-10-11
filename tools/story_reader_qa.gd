extends SceneTree
## Reading layout of the investigation notes: every story page shows its picture above a prose block
## that fits the reading column, at both window sizes.
const D = preload("res://scripts/codex_discovery.gd")
const T = preload("res://scripts/timeline.gd")
const Data = preload("res://scripts/game_data.gd")
var failures: Array[String] = []

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func _initialize(): run.call_deferred()

func prose_of(view, text: String) -> Label:
	for child in view.reader_box.get_children():
		if child is Label and child.text == text: return child
	return null

func run():
	var stamp: int = Time.get_ticks_usec()
	D.path = "user://story_reader_dex_%d.json" % stamp
	T.path = "user://story_reader_tl_%d.json" % stamp
	var flags := {}
	for key in ["story_records", "narrative_records", "lore", "regions"]:
		for item in Data.read(key):
			if str(item.get("requires_flag", "")) != "": flags[str(item.requires_flag)] = true
	for resolution in [Vector2i(1440, 900), Vector2i(1280, 720)]:
		root.size = resolution
		var view = load("res://scripts/codex_notes.gd").new()
		view.story_flags = flags
		root.add_child(view)
		await create_timer(0.3).timeout
		view.open_tab("이야기")
		var stories: Array = view.data["이야기"]
		check(stories.size() >= 5, "Story shelf lists the story records: %d" % stories.size())
		var listed := stories.map(func(r): return str(r.id))
		for expected in Data.read("story_records"):
			check(listed.has(str(expected.id)), "Story record listed: " + str(expected.id))
		var with_art := 0
		for record in stories:
			view.select_record(str(record.id))
			await create_timer(0.15).timeout
			var prose := prose_of(view, str(record.description))
			check(prose != null, "Prose shown for " + str(record.id))
			if prose == null: continue
			check(prose.size.x <= view.reader_scroll.size.x, "Prose fits the reading column: " + str(record.id))
			var holder: AspectRatioContainer = null
			for child in view.reader_box.get_children():
				if child is AspectRatioContainer: holder = child
			if str(record.art) != "":
				check(ResourceLoader.exists(str(record.art)), "Art path exists: " + str(record.art))
			if str(record.art) != "" and ResourceLoader.exists(str(record.art)):
				with_art += 1
				check(holder != null and holder.get_child(0).texture != null, "Picture shown for " + str(record.id))
				if holder != null:
					check(holder.size.y >= 300, "Picture is tall enough: " + str(record.id))
					check(prose.global_position.y >= holder.global_position.y + holder.size.y - 1, "Prose sits below the picture: " + str(record.id))
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://docs/story-%s-%d.png" % [record.id, resolution.x])
		check(with_art >= 2, "At least two illustrated stories")
		view.queue_free()
		await process_frame
	for file in [D.path, T.path, T.path + ".bak", T.path + ".tmp"]:
		if FileAccess.file_exists(file): DirAccess.remove_absolute(file)
	print("STORY_READER_QA failures=%d" % failures.size())
	quit(1 if failures.size() > 0 else 0)

extends SceneTree
const D = preload("res://scripts/codex_discovery.gd")
const T = preload("res://scripts/timeline.gd")
var failures: Array[String] = []

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func _initialize(): run.call_deferred()

func settle_time(t := 0.3):
	await create_timer(t).timeout
	await RenderingServer.frame_post_draw

func wins(list: Array) -> Array:
	return list.map(func(pair): return {"id": pair[0], "type": pair[1]})

func run():
	var stamp: int = Time.get_ticks_usec()
	D.path = "user://timeline_qa_dex_%d.json" % stamp
	T.path = "user://timeline_qa_%d.json" % stamp
	# --- fresh state -------------------------------------------------------
	var fresh: Dictionary = T.load_state()
	check(fresh.unlocked.has("H01") and fresh.points == 0, "Fresh state opens only the free entry")
	for id in ["H02", "W01", "M1", "K1", "S1", "L1", "T1"]:
		check(fresh.visible.has(id), "Visible at start: " + id)
	check(not fresh.visible.has("H05") and not fresh.visible.has("X1"), "Later entries stay hidden")
	check(T.entries().size() == 32, "32 entries")
	# --- run 1: mira clears with a full set of wins and flags -----------------------
	var run1 := T.new_run("mira")
	run1.wins = wins([["ash_warden", "일반"], ["ash_warden_elite", "엘리트"], ["ash_warden_boss", "보스"]])
	var result: Dictionary = T.settle(run1, "clear", ["ward_ledger", "carrier_hint", "ward_copy"], 0)
	check(result.points == 10 + 25 + 60 + 100, "First-time points: %s" % result.get("points"))
	for id in ["W01", "M1", "M2", "H02", "H03", "H05", "H06", "H07", "H09", "H10"]:
		check(result.opened.has(id), "Opened by run 1: " + id)
	for id in ["H04", "H08", "H11", "M3", "T1", "K1", "W02"]:
		check(not result.opened.has(id), "Not opened by run 1: " + id)
	var after: Dictionary = T.load_state()
	check(after.visible.has("H04") and after.visible.has("H11"), "Opened entries reveal what they expand")
	check(after.new_entries.size() == result.opened.size(), "Opened entries are flagged new")
	# --- the same run never settles twice -------------------------------------------
	check(T.settle(run1, "clear", [], 0).is_empty(), "Settled run is ignored")
	var run1_copy := run1.duplicate(true)
	run1_copy.settled = false
	check(T.settle(run1_copy, "clear", [], 0).is_empty(), "Same run id cannot settle again")
	check(T.load_state().points == 195, "Points unchanged by repeat settle")
	# --- run 2: repeats are worth little; death counts -------------------------------
	var run2 := T.new_run("kalian")
	run2.wins = wins([["ash_warden", "일반"], ["ash_warden", "일반"]])
	var second: Dictionary = T.settle(run2, "death", [], 0)
	check(second.points == 4, "Repeat wins give 2 each: %s" % second.get("points"))
	check(T.load_state().counters.deaths == 1, "Death counted")
	# --- repeat points are capped per run --------------------------------------------
	var run3 := T.new_run("sera")
	run3.wins = wins(range(30).map(func(i): return ["ash_warden_boss", "보스"]))
	var third: Dictionary = T.settle(run3, "abandon", [], 40)
	check(third.points == 40, "Repeat budget caps a run at 40: %s" % third.get("points"))
	# --- all characters + dex + first death chain open the story tail -------------
	var run4 := T.new_run("lucian")
	var fourth: Dictionary = T.settle(run4, "abandon", [], 40)
	for id in ["T1", "T2", "T3"]:
		check(T.unlocked().has(id), "Story entry opened: " + id)
	check(not T.unlocked().has("W02") and not T.unlocked().has("X1"), "ACT II and endings stay closed")
	check(T.unlocked().has("K1"), "Kalian entry opened by playing him")
	# --- gates -----------------------------------------------------------------------
	check(T.available({"id": "x"}), "Records without a gate are always available")
	check(T.available({"id": "x", "unlock_entry": "H01"}), "Open gate passes")
	check(not T.available({"id": "x", "unlock_entry": "H08"}), "Closed gate blocks")
	# --- damaged save falls back to the last good one -----------------------------------
	var good: int = T.load_state().points
	var broken := FileAccess.open(T.path, FileAccess.WRITE)
	broken.store_string("{not json")
	broken.close()
	var recovered: Dictionary = T.load_state()
	check(recovered.points > 0 and recovered.points <= good, "Damaged save recovers from backup")
	T.save_state(recovered)
	# --- a failed save leaves the run unsettled so it can be retried -----------------
	var real_path: String = T.path
	T.path = "user://no_such_folder_%d/progress.json" % stamp
	var lost := T.new_run("mira")
	lost.wins = wins([["ash_warden", "일반"]])
	check(T.settle(lost, "clear", [], 0).is_empty() and not lost.settled, "Failed save keeps the run unsettled")
	T.path = real_path
	check(not T.settle(lost, "clear", [], 0).is_empty() and lost.settled, "Unsettled run settles once saving works")
	# --- a recovery save must not overwrite a good backup with the damaged file ---------
	var stale := FileAccess.open(T.path, FileAccess.WRITE)
	stale.store_string("{broken")
	stale.close()
	var rec: Dictionary = T.load_state()
	T.save_state(rec)
	check(T.load_state().points >= 0 and not T.load_state().unlocked.is_empty(), "State survives a corrupt file")
	# --- a tampered file with wrong field types is coerced instead of crashing ---------
	var tampered := FileAccess.open(T.path, FileAccess.WRITE)
	tampered.store_string('{"schema": 1, "points": "many", "unlocked": 5, "flags_seen": [], "counters": {"deaths": 2}}')
	tampered.close()
	var coerced: Dictionary = T.load_state()
	check(coerced.points == 0 and coerced.unlocked is Array and coerced.flags_seen is Dictionary, "Wrong field types are reset")
	check(int(coerced.counters.deaths) == 2 and coerced.counters.has("wins"), "Valid counters are kept and missing ones filled")
	var healthy := T.new_run("mira")
	check(not T.settle(healthy, "death", [], 0).is_empty(), "A coerced state still settles runs")
	# whole numbers survive the JSON round trip as numbers
	check(T.load_state().points is int and T.load_state().points >= 0, "Points stay an integer after reload")
	# --- screens ---------------------------------------------------------------------
	T.path = "user://timeline_qa_screen_%d.json" % stamp
	var seed_run := T.new_run("mira")
	seed_run.wins = wins([["ash_warden", "일반"], ["ash_warden_elite", "엘리트"], ["ash_warden_boss", "보스"]])
	T.settle(seed_run, "clear", ["ward_ledger", "carrier_hint", "ward_copy"], 0)
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	main.choose_character(main.characters[0])
	var first_pass := true
	for resolution in [Vector2i(1440, 900), Vector2i(1280, 720)]:
		root.size = resolution
		main.show_codex_hub()
		var hub = main.get_node("CodexHub")
		await settle_time()
		check((hub.canvas.find_child("NewBadge", true, false) != null) == first_pass, "Hub badge only while records are unseen")
		root.get_texture().get_image().save_png("res://docs/timeline-hub-%d.png" % resolution.x)
		hub.open_tile(4)
		await settle_time()
		var screen = hub.child_screen
		check(screen != null and screen.cards.size() == 32, "Timeline lays out every entry")
		check((screen.new_ids.size() > 0) == first_pass, "Screen knows which entries are new (first view only)")
		root.get_texture().get_image().save_png("res://docs/timeline-%d.png" % resolution.x)
		screen._open_detail(T.entry("H09"))
		await settle_time(0.2)
		root.get_texture().get_image().save_png("res://docs/timeline-detail-open-%d.png" % resolution.x)
		screen.close_popup()
		screen._open_detail(T.entry("H04"))
		await settle_time(0.2)
		root.get_texture().get_image().save_png("res://docs/timeline-detail-locked-%d.png" % resolution.x)
		screen.close_popup()
		screen.closed.emit()
		await process_frame
		check(T.new_count() == 0, "New markers are cleared after viewing")
		hub.closed.emit()
		await process_frame
		first_pass = false
	# --- run flow: clearing/dying through the real game settles once -------------------
	main.choose_character(main.characters[0])
	check(not main.run_log.is_empty() and not main.run_log.settled, "A run log starts with the character")
	main.show_game_over()
	await process_frame
	check(main.run_log.settled and not main.last_settlement.is_empty(), "Game over settles the run")
	var before: int = T.load_state().points
	main.show_game_over()
	main.show_menu()
	check(T.load_state().points == before, "Menu after game over does not settle twice")
	main.queue_free()
	await process_frame
	for file in [D.path, T.path, T.path + ".bak", T.path + ".tmp"]:
		if FileAccess.file_exists(file): DirAccess.remove_absolute(file)
	print("TIMELINE_QA failures=%d" % failures.size())
	quit(1 if failures.size() > 0 else 0)

extends SceneTree
const Data = preload("res://scripts/game_data.gd")
const D = preload("res://scripts/codex_discovery.gd")
func _initialize(): run.call_deferred()
func run():
	D.path = "user://narrative_qa_%d.json" % Time.get_ticks_usec()
	var rows = Data.read("narrative_records")
	assert(rows.size() == 24)
	var ids := {}
	for row in rows:
		assert(not ids.has(row.id))
		ids[row.id] = true
		assert(not row.requires_flag.is_empty() or not row.requires_relic.is_empty())
	var view = load("res://scripts/codex.gd").new()
	root.add_child(view)
	for kind in ["스토리", "지역"]:
		assert(not view.records[kind].any(func(r): return ids.has(r.id)))
	view.story_flags["ward_resolved"] = true
	view._load_records()
	view._catalog_records()
	assert(view.records["스토리"].any(func(r): return r.id == "mira_clean_bandage"))
	assert(not view.records["스토리"].any(func(r): return r.id == "mira_letter_read"))
	D.record("유물", "mira_crescent")
	view._load_records()
	view._catalog_records()
	assert(view.records["스토리"].any(func(r): return r.id == "relic_crescent_wear"))
	for row in rows:
		if not row.requires_flag.is_empty(): view.story_flags[row.requires_flag] = true
	view._load_records()
	view._catalog_records()
	var found := 0
	for kind in ["스토리", "지역"]:
		for row in view.records[kind]:
			if ids.has(row.id): found += 1
	assert(found == 24)
	view.queue_free()
	await process_frame
	DirAccess.remove_absolute(D.path)
	print("MIRA_NARRATIVE_QA PASS: 24 records, gated disclosures")
	quit()

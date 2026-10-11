extends SceneTree
## Four draft potions (waiting for icons) are effect-ready: their runtime data drives the battle's potion engine correctly.
const D = preload("res://scripts/codex_discovery.gd")
const T = preload("res://scripts/timeline.gd")
const Data = preload("res://scripts/game_data.gd")
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _initialize(): run.call_deferred()

func draft(id: String) -> Dictionary:
	var raw = JSON.parse_string(FileAccess.get_file_as_string("res://tools/content_tool/data/content.json"))
	for p in raw.potions:
		if p.id == id:
			var record: Dictionary = p.runtime.duplicate(true)
			record["id"] = id
			record["name"] = p.name
			return record
	push_error("No such potion: " + id)
	return {}

func fresh(main) -> void:
	main.choose_character(main.characters[0])
	main.take_arrival_reward(0)
	main.finish_arrival()
	main.start_battle("전투")
	main.enemy = Data.find_record("monsters", "ash_warden")
	main.enemy_hp = int(main.enemy.hp)
	main.enemy_max_hp = main.enemy_hp
	main.enemy_block = 0
	main.enemy_status.entries.clear()
	main.player_status.entries.clear()
	main.block = 0
	main.energy = 3
	main.hand.clear()
	main.draw_pile = [main.card_db.common[0].duplicate(true), main.card_db.common[0].duplicate(true), main.card_db.common[0].duplicate(true), main.card_db.common[0].duplicate(true)]

func run():
	var stamp: int = Time.get_ticks_usec()
	D.path = "user://potion2_dex_%d.json" % stamp
	T.path = "user://potion2_tl_%d.json" % stamp
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	fresh(main)
	main._apply_potion(draft("potion_text_07"))
	check(main.energy == 4, "Embers distillate: +1 energy (%d)" % main.energy)
	fresh(main)
	main._apply_potion(draft("potion_text_09"))
	check(main.enemy_status.amount("weak") == 2, "Anaesthetic haze: weak 2")
	fresh(main)
	main._apply_potion(draft("potion_text_10"))
	check(main.enemy_status.amount("vulnerable") == 2, "Glass corrosive: vulnerable 2")
	fresh(main)
	main._apply_potion(draft("potion_text_12"))
	check(main.hand.size() == 2, "Dregs of thought: draw 2 (%d)" % main.hand.size())
	for id in ["potion_text_07", "potion_text_09", "potion_text_10", "potion_text_12"]:
		var rec: Dictionary = draft(id)
		check(int(rec.get("price", 0)) >= 30, "%s has a shop price" % id)
	print("POTION_WAVE2_QA failures=", failures)
	main.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)

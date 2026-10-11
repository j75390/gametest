extends SceneTree
## Attack cards in hand show the damage they would really deal: vulnerable on the enemy raises it, weak on the player lowers it.
const D = preload("res://scripts/codex_discovery.gd")
const T = preload("res://scripts/timeline.gd")
const Data = preload("res://scripts/game_data.gd")
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _initialize(): run.call_deferred()

func fresh(main) -> void:
	main.choose_character(main.characters[0])
	main.take_arrival_reward(0)
	main.finish_arrival()
	main.start_battle("전투")
	main.enemy = Data.find_record("monsters", "ash_warden")
	main.enemy_status.entries.clear()
	main.player_status.entries.clear()
	main.energy = 3

func run():
	var stamp: int = Time.get_ticks_usec()
	D.path = "user://dmgp_dex_%d.json" % stamp
	T.path = "user://dmgp_tl_%d.json" % stamp
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	fresh(main)
	var strike: Dictionary = {}
	for c in main.card_db.common + main.card_db.mira:
		if c.type == "공격" and int(c.get("damage", 0)) >= 6 and not c.get("x", false) and strike.is_empty(): strike = c.duplicate(true)
	var base := int(strike.damage)
	check(main.preview_damage(strike) == base, "no status: base damage %d" % base)
	main.enemy_status.set_amount("vulnerable", 2)
	check(main.preview_damage(strike) == floori(base * 1.5), "vulnerable: x1.5 (%d)" % main.preview_damage(strike))
	main.player_status.set_amount("weak", 1)
	check(main.preview_damage(strike) == floori(maxi(1, floori(base * 0.75)) * 1.5), "weak + vulnerable (%d)" % main.preview_damage(strike))
	var before: int = main.enemy_hp
	main.player_status.set_amount("weak", 0)
	var shown: int = main.preview_damage(strike)
	main.enemy_block = 0
	main._card_effect(strike)
	check(before - main.enemy_hp == shown, "preview equals the real hit (%d vs %d)" % [shown, before - main.enemy_hp])
	check(main.preview_damage({"type": "스킬", "damage": 0}) == 0, "non-damage card previews 0")
	# the hand shows it on the card
	fresh(main)
	main.enemy_status.set_amount("vulnerable", 2)
	main.hand = [strike.duplicate(true)]
	main.show_battle()
	await process_frame
	await process_frame
	var label: Label = main.battle_canvas.find_child("Effect", true, false)
	check(label != null and label.text.replace("\u2060", "").contains(str(floori(base * 1.5))), "card text shows the raised number: " + (label.text if label else "none"))
	main.battle_canvas.find_child("Hand", true, false).hovered = 0
	await create_timer(0.6).timeout
	root.get_viewport().get_texture().get_image().save_png("res://docs/damage-preview-1440.png")
	print("DAMAGE_PREVIEW_QA failures=", failures)
	main.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)

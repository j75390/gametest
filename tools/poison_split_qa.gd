extends SceneTree
const Data = preload("res://scripts/game_data.gd")
const Status = preload("res://scripts/unit_status.gd")
var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)
func _initialize():
	run.call_deferred()
func run():
	root.size = Vector2i(1440, 900)
	for maximum in [72, 100, 250]:
		var unit = Status.new()
		unit.apply([{"id":"poison","amount":5},{"id":"venom","amount":2,"rate":0.08}])
		check(unit.tick(maximum) == 5 + ceili(maximum * 0.08), "Independent flat/percent damage")
		check(unit.amount("poison") == 4 and unit.amount("venom") == 1, "Separate counters")
		unit.apply([{"id":"poison","amount":3}])
		check(unit.amount("poison") == 7 and unit.amount("venom") == 1, "Poison stacking preserved venom")
		unit.tick(maximum)
		check(unit.amount("venom") == 0 and unit.amount("poison") == 6, "Independent expiry")
		for i in range(6): unit.tick(maximum)
		check(unit.entries.is_empty(), "All statuses expire")
	var poison: Dictionary = {}
	var venom: Dictionary = {}
	for c in Data.cards().mira:
		if c.id == "poison_infusion": poison = c
		if c.id == "venom_hex": venom = c
	check(not poison.is_empty() and not venom.is_empty(), "Both cards in Mira reward/shop pool")
	check(Data.upgraded(poison).poison == 8, "Poison upgrade")
	check(venom.venom_turns == 3 and venom.venom_rate == 0.08, "Existing venom unchanged")
	check(Data.effect_text(poison).contains("독 5중첩"), "Shared card description")
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	main.choose_character(main.characters[0])
	main.start_battle("전투")
	main.enemy_max_hp = 100
	main.enemy_hp = 100
	main.hand = [poison.duplicate(true), venom.duplicate(true)]
	main.energy = 3
	main.show_battle()
	await main.play_card(0)
	await main.play_card(0)
	check(main.enemy_status.amount("poison") == 5 and main.venom_turns == 3, "Real cards apply both")
	main.player_status.apply([{"id":"poison","amount":3},{"id":"venom","amount":2,"rate":0.08}])
	main.block = 999
	main.show_battle()
	await process_frame
	await process_frame
	var icons = main.find_children("poison", "TextureRect", true, false)
	check(icons.size() == 2, "Poison icons on both HP bars")
	check(main.find_children("venom", "TextureRect", true, false).size() == 2, "Venom icons on both HP bars")
	for icon in icons:
		check(icon.tooltip_text.contains("독") and (icon.tooltip_text.contains("5") or icon.tooltip_text.contains("3")), "Poison tooltip")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/poison-venom-battle.png")
	var old_hp: int = main.hp
	await main.end_turn()
	check(main.enemy_hp == 87, "Enemy receives 5 flat plus 8 percent")
	check(main.hp == old_hp - 3 - ceili(main.max_hp * 0.08), "Player uses same DOT rules; block does not absorb DOT")
	main.start_battle("전투")
	check(main.player_status.entries.is_empty() and main.enemy_status.entries.is_empty(), "No status leaks into next battle")
	main.show_codex()
	await process_frame
	var codex = main.get_node("Codex")
	codex._change_category("파워")
	check(codex.records["파워"].any(func(r): return r.id == "poison" and r.name == "독"), "Codex poison record")
	check(codex.records["파워"].any(func(r): return r.id == "venom" and r.name == "맹독"), "Codex venom record")
	check(codex.art_box.has_node("FullArtwork"), "Codex status artwork loads")
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/poison-venom-codex.png")
	print("POISON_SPLIT_QA failures=%d" % failures.size())
	quit(0 if failures.is_empty() else 1)

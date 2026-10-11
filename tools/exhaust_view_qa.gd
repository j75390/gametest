extends SceneTree
## Exhaust pile: an icon with a count appears once a card is exhausted, opens a viewer with those cards, and X opens it too.
const D = preload("res://scripts/codex_discovery.gd")
const T = preload("res://scripts/timeline.gd")
const Data = preload("res://scripts/game_data.gd")
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _initialize(): run.call_deferred()

func card(main, id: String) -> Dictionary:
	for c in main.card_db.mira:
		if c.id == id: return c.duplicate(true)
	return {}

func run():
	var stamp: int = Time.get_ticks_usec()
	D.path = "user://exhaust_dex_%d.json" % stamp
	T.path = "user://exhaust_tl_%d.json" % stamp
	root.size = Vector2i(1440, 900)
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.choose_character(main.characters[0])
	main.take_arrival_reward(0)
	main.finish_arrival()
	main.start_battle("전투")
	main.enemy = Data.find_record("monsters", "ash_warden")
	main.enemy_hp = int(main.enemy.hp)
	main.enemy_max_hp = main.enemy_hp
	main.hand = [card(main, "grand_elixir"), card(main, "rapid_poison")]
	main.energy = 3
	main.show_battle()
	await process_frame
	check(main.content.get_node_or_null("ExhaustPile") == null, "No exhaust icon before anything is exhausted")
	main.play_card(1)
	await process_frame
	var waited := 0.0
	while main.battle_busy and waited < 20.0:
		await create_timer(0.1).timeout
		waited += 0.1
	check(main.content.get_node_or_null("ExhaustPile") == null, "A card that is not exhausted adds no icon")
	main.play_card(0)
	await process_frame
	waited = 0.0
	while main.battle_busy and waited < 20.0:
		await create_timer(0.1).timeout
		waited += 0.1
	check(main.exhaust_pile.size() == 1, "Grand elixir exhausted (%d)" % main.exhaust_pile.size())
	var scene = main.content
	var icon = scene.get_node_or_null("ExhaustPile")
	check(icon != null, "Exhaust icon appears after exhausting a card")
	if icon != null:
		var rect: Rect2 = icon.get_global_rect()
		check(rect.position.x >= 0 and rect.end.x <= 1440 and rect.end.y <= 900, "Exhaust icon stays on screen")
		var discard = scene.get_node("DiscardPile")
		check(not rect.intersects(discard.get_global_rect()), "Exhaust icon does not overlap the discard pile")
		var count = scene.get_node_or_null("ExhaustPileCount")
		check(count != null, "Exhaust icon shows a count badge")
	scene.open_pile("exhaust")
	await process_frame
	check(is_instance_valid(scene.viewer), "Exhaust viewer opens")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/exhaust-view-1440.png")
	print("EXHAUST_VIEW_QA failures=", failures)
	main.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)

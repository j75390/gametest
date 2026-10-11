extends SceneTree
## Screenshots: a hand of the new Mira cards in battle (docs/mira-cards-hand-1440.png) and the deck viewer with all of them.
const D = preload("res://scripts/codex_discovery.gd")
func _initialize(): run.call_deferred()
func shot(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/%s.png" % name)
func run():
	D.path = "user://mira_cards_shot_%d.json" % Time.get_ticks_usec()
	root.size = Vector2i(1440, 900)
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.choose_character(main.characters[0])
	main.take_arrival_reward(0)
	main.finish_arrival()
	main.start_battle("전투")
	for group in [["tainted_blade", "overdose", "echo_dose", "chain_reaction", "borrowed_pain"], ["rapid_brew", "ether_cycle", "purification", "masked_whisper", "weak_point_injection"]]:
		main.hand.clear()
		for id in group:
			for c in main.card_db.mira:
				if c.id == id: main.hand.append(c.duplicate(true))
		main.hand.append(main.SIDE_EFFECT_CARD.duplicate(true))
		main.potions = ["potion_text_04", "potion_text_06"]
		main.show_battle()
		await shot("mira-cards-hand-%d-1440" % (1 if group[0] == "tainted_blade" else 2))
	main.deck.clear()
	for c in main.card_db.mira: main.deck.append(c.duplicate(true))
	main.show_deck()
	await create_timer(0.6).timeout
	await shot("mira-cards-deck-1440")
	print("MIRA_CARDS_SHOT done")
	quit(0)

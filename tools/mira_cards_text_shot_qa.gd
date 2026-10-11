extends SceneTree
## Screenshot of the deck viewer with the longest card texts, to check they fit the card (docs/mira-cards-text-1440.png).
const D = preload("res://scripts/codex_discovery.gd")
func _initialize(): run.call_deferred()
func run():
	D.path = "user://mira_text_shot_%d.json" % Time.get_ticks_usec()
	root.size = Vector2i(1440, 900)
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.choose_character(main.characters[0])
	main.take_arrival_reward(0)
	main.finish_arrival()
	main.deck.clear()
	for id in ["rapid_brew", "echo_dose", "ether_cycle", "purification", "overdose", "borrowed_pain", "masked_whisper", "tainted_blade", "chain_reaction", "weak_point_injection", "thorn_salve", "bitter_dose", "chemical_burst", "accumulated_pain"]:
		for c in main.card_db.mira:
			if c.id == id: main.deck.append(c.duplicate(true))
	main.show_deck()
	await create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/mira-cards-text-1440.png")
	print("done")
	quit(0)

extends SceneTree
var failures := 0
func _initialize(): run.call_deferred()
func check(value: bool, detail: String):
	if not value:
		failures += 1
		push_error(detail)
func run():
	var data = load("res://scripts/game_data.gd")
	var original = data.cards()
	var mira = data.cards("mira")
	for i in range(2):
		check(mira.common[i].art.contains("/mira/"), "Mira basic art missing")
		check(ResourceLoader.exists(mira.common[i].art), "Variant file missing")
		check(mira.common[i].cost == original.common[i].cost, "Cost changed")
		check(data.effect_text(mira.common[i]) == data.effect_text(original.common[i]), "Effect changed")
		check(data.upgraded(mira.common[i]).art == mira.common[i].art, "Upgrade lost art")
		check(data.cards("kalian").common[i].art == original.common[i].art, "Other character polluted")
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	main.choose_character(main.characters[0])
	check(main.deck.size() == 10, "Starter deck count changed")
	for card in main.deck: check(card.art.contains("/mira/"), "Deck variant missing")
	main.take_arrival_reward(0)
	main.finish_arrival()
	main.start_battle("전투")
	main.hand = [main.card_db.common[0].duplicate(true), main.card_db.common[1].duplicate(true)]
	main.show_battle()
	for dimensions in [Vector2i(1440,900), Vector2i(1280,720)]:
		root.size = dimensions
		await create_timer(0.3).timeout
		for card in main.content.get_node("Hand").views:
			check(card.get_node("ArtWindow/Illustration").texture.resource_path.contains("/mira/"), "Battle wrong art")
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/mira-basic-cards-%d.png" % dimensions.x)
	main.show_deck()
	await process_frame
	main.choose_character(main.characters[1])
	check(main.card_db.common[0].art == original.common[0].art, "Switch failed to reset art")
	print("MIRA_BASIC_ART_QA failures=", failures)
	quit(0 if failures == 0 else 1)

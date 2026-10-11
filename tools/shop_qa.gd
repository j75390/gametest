extends SceneTree
const D = preload("res://scripts/codex_discovery.gd")
var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)
func _initialize(): run.call_deferred()
func run():
	D.path = "user://shop_qa_%d.json" % Time.get_ticks_usec()
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	main.choose_character(main.characters[0])
	main._generate_map()
	main.expedition.current_id = 1
	main.show_shop()
	await process_frame
	var stock: Dictionary = main.shop_stock[1]
	check(stock.cards.size() == 3 and stock.relics.size() == 3 and stock.potions.size() == 3, "Stock sizes 3/3/3")
	check(stock.cards.any(func(c): return c.sale), "One card on sale")
	var badge = main.find_child("SaleBadge", true, false)
	check(badge != null and badge.text.begins_with("-") and badge.text.ends_with("%"), "Sale shows a percentage badge")
	var bracketed := false
	for label in main.find_children("*", "Label", true, false):
		if label.text.contains("G  (") or label.text.contains("G ("): bracketed = true
	check(not bracketed, "Sale price is not printed as a bracketed number")
	# stock persists across re-entry
	var first_ids = stock.cards.map(func(c): return c.card.id + str(c.price))
	main.show_shop()
	await process_frame
	check(main.shop_stock[1].cards.map(func(c): return c.card.id + str(c.price)) == first_ids, "Stock persists on re-render")
	# card purchase
	main.gold = 1000
	var deck_before = main.deck.size()
	var price = int(stock.cards[0].price)
	main.shop_purchase("cards", 0)
	check(main.deck.size() == deck_before + 1 and main.gold == 1000 - price and stock.cards[0].sold, "Card purchase")
	main.shop_purchase("cards", 0)
	check(main.deck.size() == deck_before + 1 and main.gold == 1000 - price, "No double buy")
	# relic
	var gold_now = main.gold
	var rid = stock.relics[0].id
	main.shop_purchase("relics", 0)
	check(main.owned_relics.has(rid) and main.gold == gold_now - int(stock.relics[0].price), "Relic purchase")
	# a potion goes onto the belt; a full belt refuses another purchase
	gold_now = main.gold
	main.shop_purchase("potions", 0)
	check(main.potions.size() == 1 and main.potions[0] == stock.potions[0].id and stock.potions[0].sold and main.gold == gold_now - int(stock.potions[0].price), "Potion goes on the belt")
	main.potions = ["potion_text_01", "potion_text_01", "potion_text_01"]
	gold_now = main.gold
	main.shop_purchase("potions", 1)
	check(main.gold == gold_now and not stock.potions[1].sold and main.potions.size() == 3, "Full belt refuses a purchase")
	# not enough gold
	main.gold = 1
	main.shop_purchase("cards", 1)
	check(not stock.cards[1].sold and main.gold == 1, "Poor cannot buy")
	# removal escalates
	main.gold = 500
	var size_before = main.deck.size()
	main.shop_remove_card(0)
	check(main.deck.size() == size_before - 1 and main.gold == 500 - 75 and main.removal_price() == 125, "Removal 75 then 125")
	main.shop_remove_card(0)
	check(main.gold == 500 - 75 - 125, "Second removal charges 125")
	main.shop_remove_card(999)
	check(main.gold == 500 - 75 - 125, "Bad index ignored")
	# sold-out state survives leaving and re-entering the same shop
	main.show_shop()
	await process_frame
	check(main.shop_stock[1].cards[0].sold and main.shop_stock[1].relics[0].sold, "Sold flags persist on re-entry")
	var owned_before = main.owned_relics.size()
	main.shop_purchase("relics", 0)
	check(main.owned_relics.size() == owned_before, "No relic re-buy after re-entry")
	# picker opens and cancels
	main.shop_view.refresh(500, main.hp, main.max_hp, main.removal_price())
	await process_frame
	main.shop_view._open_picker()
	await process_frame
	check(is_instance_valid(main.shop_view.picker), "Picker opens")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/shop-picker-1440.png")
	main.shop_view._close_picker()
	await process_frame
	# render both resolutions with fresh stock
	main.removal_count = 0
	main.shop_stock.clear()
	main.gold = 200
	main.hp = 40
	for resolution in [Vector2i(1440, 900), Vector2i(1280, 720)]:
		root.size = resolution
		main.show_shop()
		await create_timer(.3).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/shop-%d.png" % resolution.x)
	# a new run wipes shop state
	main.choose_character(main.characters[0])
	check(main.shop_stock.is_empty() and main.removal_count == 0, "New run resets shop state")
	main.expedition.current_id = 1
	main.show_shop()
	await process_frame
	# leave returns to map
	main.shop_view.leave_requested.emit()
	await process_frame
	check(main.screen != "shop" and not is_instance_valid(main.shop_view), "Leaving closes shop")
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(D.path)
	print("SHOP_QA failures=%d" % failures.size())
	quit(1 if failures.size() > 0 else 0)

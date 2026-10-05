extends SceneTree
func _initialize(): run.call_deferred()
func run():
	root.size = Vector2i(1320, 450)
	root.content_scale_size = Vector2i(1320, 450)
	var backdrop := ColorRect.new()
	backdrop.color = Color("15131a")
	backdrop.size = Vector2(1320,450)
	root.add_child(backdrop)
	var pools = load("res://scripts/game_data.gd").cards("mira")
	var cards: Array = pools.common + pools.mira
	for i in range(cards.size()):
		var card = load("res://scripts/battle_card.gd").new()
		root.add_child(card)
		card.setup(cards[i])
		card.position = Vector2(15 + i * 260,35)
		card.scale = Vector2.ONE * 1.15
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/mira-card-art-review.png")
	quit()

extends SceneTree
## Rest stop and potion belt: screenshots plus the rest / upgrade / potion-click logic.
const D = preload("res://scripts/codex_discovery.gd")
var failures := 0
func _initialize(): run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", message)
func shot(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/%s.png" % name)
func run():
	D.path = "user://rest_shot_%d.json" % Time.get_ticks_usec()
	root.size = Vector2i(1440, 900)
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.choose_character(main.characters[0])
	main.take_arrival_reward(0)
	main.finish_arrival()
	main.start_battle("전투")
	main.potions = ["potion_text_02", "potion_text_05", "potion_text_04"]
	main.show_battle()
	await shot("potion-battle-v2-1440")
	var belt = main.content.get_node("PotionBelt")
	var icon = belt.get_node("PotionSlot_0/Icon")
	check(icon.get_global_rect().position.y < 76, "Potion belt sits inside the top bar")
	for relic_index in main.owned_relics.size():
		var slot: Control = main.content.get_node("Relic%d" % relic_index)
		check(not slot.get_global_rect().intersects(belt.get_global_rect()), "Relic %d does not cover the potions" % relic_index)
	var hp_before: int = main.hp
	main.hp = maxi(1, main.hp - 12)
	main.use_potion(0)
	await process_frame
	await process_frame
	check(main.potions.size() == 2, "Using a potion removes it from the belt")
	await shot("potion-used-1440")
	main.hp = hp_before
	main.enemy_hp = 0
	main.show_reward()
	await shot("reward-normal-1440")
	check(is_instance_valid(main.reward_view) and main.reward_view.find_children("RewardCard_*", "Control", true, false).size() == 3, "Reward shows three cards")
	main.start_battle("엘리트")
	main.enemy_hp = 0
	main.show_reward()
	await shot("reward-elite-1440")
	check(main.reward_view.find_children("RewardRelic_*", "Button", true, false).size() == 3, "Elite reward shows three relics")
	var cards_before: int = main.deck.size()
	main.reward_view.find_children("Pick", "Button", true, false)[0].pressed.emit()
	check(main.deck.size() == cards_before + 1 and main.screen == "map", "Picking a card adds it and returns to the map")
	main.screen = "encounter"
	main.hp = maxi(1, main.max_hp - 30)
	main.show_rest()
	await shot("rest-scene-1440")
	check(main.screen == "rest" and is_instance_valid(main.rest_view), "Rest screen opens as its own view")
	var view = main.rest_view
	view._open_picker()
	await shot("rest-upgrade-picker-1440")
	check(is_instance_valid(view.picker), "Upgrade picker opens")
	var index: int = view.upgradable[0]
	var name_before: String = main.deck[index].name
	view._pick_upgrade(index)
	await shot("rest-upgrade-done-1440")
	await create_timer(1.8).timeout
	check(main.deck[index].get("upgraded", false) and str(main.deck[index].name) == name_before + "+", "Upgrade applies after the flame")
	check(main.screen == "map", "Back on the map after upgrading: %s" % main.screen)
	var hp_now: int = main.hp
	main.show_rest()
	main.rest_view._choose_rest()
	await create_timer(1.6).timeout
	check(main.hp > hp_now and main.screen == "map", "Resting heals and returns to the map")
	print("REST_SHOT_QA failures=", failures)
	quit(1 if failures > 0 else 0)

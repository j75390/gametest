extends SceneTree
const Assets = preload("res://scripts/character_assets.gd")
const Visual = preload("res://scripts/character_visual.gd")
var failures: Array[String] = []

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func _initialize() -> void:
	run.call_deferred()

func click(button: Button) -> void:
	var point := button.get_global_rect().get_center()
	var move := InputEventMouseMotion.new()
	move.position = point
	root.push_input(move)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event)
		await process_frame

func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/mira-pixel-%s.png" % name)

func run() -> void:
	root.size = Vector2i(1440, 900)
	var unique: Dictionary = {}
	for motion in Assets.KEYS:
		check(Assets.count("mira", motion) >= 2, "Missing motion: " + motion)
		for i in range(Assets.count("mira", motion)):
			var texture := Assets.frame("mira", motion, i)
			check(texture != null and not texture is AtlasTexture, "Whole frame required: " + motion)
			check(texture.get_size() == Vector2(1254, 1254), "Inconsistent frame canvas")
			check(texture.get_image().detect_alpha() != Image.ALPHA_NONE, "Missing transparency")
			unique[texture.resource_path] = true
	check(unique.size() == 12, "Expected 12 independently generated poses")
	var actor := Visual.new()
	root.add_child(actor)
	actor.setup("mira")
	actor.set_process(false)
	for motion in Assets.KEYS:
		actor.play(motion)
		var before := actor.texture
		actor._process(Assets.duration("mira", motion, 0) + 0.01)
		check(actor.texture != before, "Animation failed to change pose: " + motion)
		actor.play(motion)
		actor._process(Assets.motion_duration("mira", motion) + 0.01)
		if motion == "death":
			check(actor.finished and actor.texture.resource_path.ends_with("death_rest.png"), "Death must hold final pose")
			actor._process(5.0)
			check(actor.motion == "death", "Dead character returned to idle")
		elif motion not in ["idle", "walk"]:
			check(actor.motion == "idle", "One-shot did not return to idle: " + motion)
		else:
			check(actor.motion == motion and actor.frame_index == 0, "Loop timing drift: " + motion)
	actor.queue_free()
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	main.show_codex()
	await process_frame
	await process_frame
	var codex = main.get_node("Codex")
	check(codex.selected_id == "mira", "Mira not selected")
	check(codex.sprite_preview.get_global_rect().end.y <= 884, "Motion preview clipped at 1440x900")
	for i in range(6):
		check(not codex.motion_buttons[i].disabled, "Motion button disabled")
		await click(codex.motion_buttons[i])
		check(codex.motion_index == i and codex.sprite_preview.motion == Assets.KEYS[i], "Motion button did not select pose")
		await create_timer(Assets.duration("mira", Assets.KEYS[i], 0) + 0.03).timeout
		await click(codex.pause_button)
		var frozen: Texture2D = codex.sprite_preview.texture
		await create_timer(0.2).timeout
		check(codex.sprite_preview.texture == frozen and not codex.playing, "Pause failed")
		if i == 0 or i == 3:
			await capture("codex-" + Assets.KEYS[i])
		await click(codex.pause_button)
		check(codex.playing, "Resume failed")
	# Independent frame previews must retain their layout in a smaller window.
	root.size = Vector2i(1280, 720)
	await process_frame
	await process_frame
	check(codex.sprite_preview.size.x >= 210, "Preview collapsed at smaller resolution")
	root.size = Vector2i(1440, 900)
	codex.closed.emit()
	await process_frame
	main.choose_character(main.characters[0])
	main.start_battle("전투")
	await process_frame
	await process_frame
	check(main.content.get_node("BattleStage/Hero").texture.resource_path.contains("pixel_sd_v1"), "Battle still uses old SD")
	await capture("battle-idle")
	for card_index in [0, 1]:
		main.hand = [main.card_db.common[card_index].duplicate(true)]
		main.energy = 3
		main.show_battle()
		await process_frame
		var old_hp: int = main.enemy_hp
		main.play_card(0)
		await process_frame
		await create_timer(0.35).timeout
		var hero = main.content.get_node("BattleStage/Hero")
		var expected := "attack" if card_index == 0 else "skill"
		check(hero.motion == expected, "Battle card motion mismatch: " + expected)
		check(main.battle_busy, "Card input unlocked during animation")
		if card_index == 0:
			check(main.enemy_hp < old_hp, "Attack damage lost")
		await capture("battle-" + expected)
		await create_timer(1.0).timeout
		check(not main.battle_busy, "Battle remained locked")
	main.block = 0
	main.enemy_turn = 0
	main.end_turn()
	await create_timer(0.36).timeout
	check(main.content.get_node("BattleStage/Hero").motion == "hurt", "Enemy hit did not play hurt")
	await create_timer(1.1).timeout
	main.hp = 1
	main.block = 0
	main.enemy_turn = 0
	main.end_turn()
	await create_timer(1.0).timeout
	check(main.hp == 0, "Lethal hit displayed negative HP")
	check(main.content.get_node("BattleStage/Hero").texture.resource_path.ends_with("death_rest.png"), "Lethal hit did not reach final death pose")
	await capture("battle-death")
	await create_timer(1.3).timeout
	check(main.title.text == "원정 실패", "Death did not finish battle")
	# Characters without a motion set still need visible battle art.
	for index in range(1, 4):
		main.choose_character(main.characters[index])
		main.start_battle("전투")
		await process_frame
		await process_frame
		var stage = main.content.get_node("BattleStage")
		check(stage.get_child(0) is TextureRect and stage.get_child(0).texture != null, "Other character battle art disappeared")
	print("MIRA_MOTION_QA frames=12 motions=6 battle=attack/skill/hurt/death failures=", failures.size())
	main.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

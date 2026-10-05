extends Control
## Fixed design coordinates scaled together: actors, targeting and UI share one space.
const DESIGN := Vector2(1440, 900)
var game

class GroundShadow extends Control:
	func _draw():
		for i in range(8, 0, -1):
			draw_set_transform(size / 2, 0, Vector2(1, 0.16))
			draw_circle(Vector2.ZERO, size.x * 0.5 * i / 8.0, Color(0.025, 0.016, 0.035, 0.07))

func _ready():
	get_viewport().size_changed.connect(_fit)
	_fit()

func _fit():
	if not is_inside_tree(): return
	var viewport := get_viewport_rect().size
	var factor := minf(viewport.x / DESIGN.x, viewport.y / DESIGN.y)
	size = DESIGN
	scale = Vector2.ONE * factor
	position = (viewport - DESIGN * factor) / 2

func place(node: Control, rect: Rect2, parent: Node = self):
	parent.add_child(node)
	node.position = rect.position
	node.size = rect.size
	return node

func label_named(id: String, text: String, rect: Rect2, font := 20, color := Color("eadbc4")) -> Label:
	var label := Label.new()
	label.name = id
	label.text = text
	label.add_theme_font_size_override("font_size", font)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_y", 2)
	place(label, rect)
	return label

func setup(owner_game):
	game = owner_game
	var background := TextureRect.new()
	background.name = "Environment"
	background.texture = load("res://assets/backgrounds/battle_cathedral_v1.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	place(background, Rect2(Vector2.ZERO, DESIGN))
	var hud := ColorRect.new()
	hud.color = Color(0.025, 0.018, 0.038, 0.86)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	place(hud, Rect2(0, 0, 1440, 70))
	label_named("PlayerSummary", "%s  HP %d/%d   방어 %d   에너지 %d/3" % [game.selected_character.name, game.hp, game.max_hp, game.block, game.energy], Rect2(40, 17, 850, 36), 22)
	label_named("Location", "잿빛 성당  /  전투", Rect2(1130, 18, 280, 32), 20, Color("c2adc9"))
	var stage := Control.new()
	stage.name = "BattleStage"
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	place(stage, Rect2(0, 70, 1440, 465))
	for x in [350, 1080]:
		var shadow := GroundShadow.new()
		shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		place(shadow, Rect2(x - 125, 424, 250, 26), stage)
	var hero = game.CharacterVisual.new()
	hero.name = "Hero"
	place(hero, Rect2(140, 80, 420, 380), stage)
	hero.setup(game.selected_character.id, game.battle_motion)
	var enemy = preload("res://scripts/battle_unit_view.gd").new()
	enemy.name = "Enemy"
	enemy.texture = load(game.enemy.art)
	enemy.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	enemy.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	place(enemy, Rect2(910, 80, 340, 380), stage)
	var statuses := Control.new()
	statuses.name = "UnitStatuses"
	statuses.mouse_filter = Control.MOUSE_FILTER_IGNORE
	place(statuses, Rect2(0, 535, 1440, 80))
	for entry in [["Player", 210, game.selected_character.name, game.hp, game.max_hp, game.player_status], ["Enemy", 940, game.enemy.name, game.enemy_hp, game.enemy_max_hp, game.enemy_status]]:
		var panel = game.StatusPanel.new()
		panel.name = entry[0]
		place(panel, Rect2(entry[1], 0, 280, 70), statuses)
		panel.setup(entry[2], entry[3], entry[4], entry[5])
	var action: Dictionary = game.enemy.pattern[game.enemy_turn % game.enemy.pattern.size()]
	var intent := label_named("Intent", "%s  ·  %d 피해" % [action.name, int(action.damage) + game.enemy_status.amount("empower")], Rect2(910, 101, 340, 40), 23, Color("ffd39b"))
	intent.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_named("EnemySummary", "", Rect2()).hide()
	var hand = game.BattleHand.new()
	hand.name = "Hand"
	place(hand, Rect2(230, 595, 980, 305))
	hand.setup(game.hand, game.energy, game.battle_busy, enemy)
	hand.custom_minimum_size.y = 0
	hand.size = Vector2(980, 305)
	hand.card_requested.connect(game.play_card)
	label_named("Energy", "%d / 3" % game.energy, Rect2(55, 693, 170, 70), 43, Color("d8b6ff"))
	label_named("EnergyCaption", "에너지", Rect2(64, 752, 150, 30), 19)
	label_named("Piles", "뽑을 카드  %d\n버린 카드  %d" % [game.draw_pile.size(), game.discard_pile.size()], Rect2(48, 812, 180, 64), 18)
	var controls := VBoxContainer.new()
	controls.name = "BattleControls"
	controls.add_theme_constant_override("separation", 12)
	place(controls, Rect2(1218, 738, 180, 126))
	for pair in [["덱 보기", game.show_deck], ["턴 종료", game.end_turn]]:
		var button := Button.new()
		button.text = pair[0]
		button.custom_minimum_size = Vector2(180, 54)
		button.add_theme_font_size_override("font_size", 23)
		button.disabled = game.battle_busy
		button.pressed.connect(pair[1])
		var box := StyleBoxFlat.new()
		box.bg_color = Color("241b30")
		box.border_color = Color("ad8953")
		box.set_border_width_all(2)
		box.set_corner_radius_all(9)
		button.add_theme_stylebox_override("normal", box)
		controls.add_child(button)

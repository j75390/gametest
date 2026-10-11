extends Control
## Fixed design coordinates scaled together: actors, targeting and UI share one space.
const DESIGN := Vector2(1440, 900)
## Fighters are drawn smaller than the old 420x380 boxes so a party of several players
## fits on the left and enemies on the right. Feet stay on one line (stage y=FEET_Y).
const UNIT_SCALE := 0.72
const FEET_Y := 460.0
const HERO_BOX := Vector2(420, 380)
const ENEMY_BOX := Vector2(340, 380)
const PileViewer = preload("res://scripts/pile_viewer.gd")
const TipIcon = preload("res://scripts/tip_icon.gd")
const UiFont = preload("res://scripts/ui_font.gd")
const MonsterActions = preload("res://scripts/monster_actions.gd")
var game
var viewer: Control

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
	# ACT II/III have their own battle backdrops once delivered (battle_canal_v1.png, battle_greenhouse_v1.png); until then the cathedral stands in
	var act_backdrop: String = {2: "res://assets/backgrounds/battle_canal_v1.png", 3: "res://assets/backgrounds/battle_greenhouse_v1.png", 4: "res://assets/backgrounds/battle_library_v1.png"}.get(int(game.current_act), "")
	background.texture = load(act_backdrop if not act_backdrop.is_empty() and ResourceLoader.exists(act_backdrop) else "res://assets/backgrounds/battle_cathedral_v1.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	place(background, Rect2(Vector2.ZERO, DESIGN))
	var hud := ColorRect.new()
	hud.color = Color(0.025, 0.018, 0.038, 0.86)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.color = Color(0.02, 0.014, 0.03, 0.97)
	place(hud, Rect2(0, 0, 1440, 76))
	# Old text HUD stays as hidden nodes: main.gd still updates them; the top bar below replaces it.
	label_named("PlayerSummary", "%s  HP %d/%d   방어 %d   에너지 %d/3" % [game.selected_character.name, game.hp, game.max_hp, game.block, game.energy], Rect2(40, 17, 850, 36), 22).hide()
	label_named("Location", "잿빛 성당  /  전투", Rect2(1130, 18, 280, 32), 20, Color("c2adc9")).hide()
	var stage := Control.new()
	stage.name = "BattleStage"
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	place(stage, Rect2(0, 110, 1440, 465))
	for x in [350, 1080]:
		var shadow := GroundShadow.new()
		shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		place(shadow, Rect2(x - 125 * UNIT_SCALE - 10, 428, 250 * UNIT_SCALE + 20, 22), stage)
	var hero = game.CharacterVisual.new()
	hero.name = "Hero"
	var hero_size := HERO_BOX * UNIT_SCALE
	var feet_pad := 0.0
	# pixel sprites share one wide transparent canvas with the feet a few rows above its bottom edge
	var profile: Dictionary = game.Assets.profile(str(game.selected_character.id))
	var shown_scale := float(profile.get("display_scale", 0.0))
	var first_frame: Texture2D = game.Assets.frame(str(game.selected_character.id), "idle", 0)
	if shown_scale > 0.0 and first_frame != null:
		hero_size = first_frame.get_size() * shown_scale
		feet_pad = float(profile.get("feet_offset", 0)) * shown_scale
	place(hero, Rect2(350 - hero_size.x / 2, FEET_Y + feet_pad - hero_size.y, hero_size.x, hero_size.y), stage)
	hero.setup(game.selected_character.id, game.battle_motion)
	var enemy = preload("res://scripts/battle_unit_view.gd").new()
	enemy.name = "Enemy"
	enemy.texture = load(game.enemy.art)
	if not str(game.enemy.get("tint", "")).is_empty(): enemy.modulate = Color(str(game.enemy.tint))
	enemy.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	enemy.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var enemy_size := ENEMY_BOX * UNIT_SCALE * float(game.enemy.get("scale", 1.0))
	place(enemy, Rect2(1080 - enemy_size.x / 2, FEET_Y - enemy_size.y, enemy_size.x, enemy_size.y), stage)
	var statuses := Control.new()
	statuses.name = "UnitStatuses"
	statuses.mouse_filter = Control.MOUSE_FILTER_IGNORE
	place(statuses, Rect2(0, 575, 1440, 80))
	# Bars are as wide as the fighter they sit under and centred on the same x as its shadow.
	var bar_width := int(300 * UNIT_SCALE)
	for entry in [["Player", 350, game.selected_character.name, game.hp, game.max_hp, game.player_status, game.block], ["Enemy", 1080, game.enemy.name + (" · " + MonsterActions.phase_name(game.enemy, game.enemy_hp, game.enemy_max_hp) if not MonsterActions.phase_name(game.enemy, game.enemy_hp, game.enemy_max_hp).is_empty() else ""), game.enemy_hp, game.enemy_max_hp, game.enemy_status, game.enemy_block]]:
		var panel = game.StatusPanel.new()
		panel.name = entry[0]
		place(panel, Rect2(entry[1] - bar_width / 2, 0, bar_width, 70), statuses)
		panel.setup(entry[2], entry[3], entry[4], entry[5], entry[6], bar_width)
	var action: Dictionary = game.enemy_action()
	_build_intent(action)
	label_named("EnemySummary", "", Rect2()).hide()
	var hand = game.BattleHand.new()
	hand.name = "Hand"
	place(hand, Rect2(230, 595, 980, 305))
	hand.damage_preview = game.preview_damage
	hand.setup(game.hand, game.energy, game.battle_busy, enemy)
	hand.custom_minimum_size.y = 0
	hand.size = Vector2(980, 305)
	hand.card_requested.connect(game.play_card)
	var orb := TipIcon.new()
	orb.name = "EnergyOrb"
	orb.texture = load("res://assets/ui/battle/energy_orb.png")
	orb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	orb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	orb.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	orb.mouse_filter = Control.MOUSE_FILTER_STOP
	orb.setup_tip("에너지", "카드를 사용하는 데 소모됩니다.")
	place(orb, Rect2(50, 630, 150, 150))
	var energy := label_named("Energy", "%d/3" % game.energy, Rect2(50, 630, 150, 150), 46, Color("fff3ff"))
	energy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	energy.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	energy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	energy.add_theme_font_override("font", UiFont.serif())
	energy.add_theme_color_override("font_outline_color", Color("1c0a2a"))
	energy.add_theme_constant_override("outline_size", 8)
	_pile("DrawPile", "pile_draw", Rect2(30, 800, 84, 84), game.draw_pile.size(), "뽑을 카드 더미 (A)", "매 턴 시작 시, 이곳에서 카드를 5장 뽑습니다.\n\n클릭하면 뽑을 카드 더미의 카드를 봅니다. (순서는 섞여 있습니다.)", "draw")
	_pile("DiscardPile", "pile_discard", Rect2(1326, 800, 84, 84), game.discard_pile.size(), "버린 카드 더미 (S)", "뽑을 카드 더미가 비어 있으면, 버린 카드 더미를 섞어 뽑을 카드 더미로 만듭니다.\n\n클릭하면 버린 카드 더미의 카드를 봅니다.", "discard")
	if not game.exhaust_pile.is_empty():
		_pile("ExhaustPile", "pile_exhaust" if ResourceLoader.exists("res://assets/ui/battle/pile_exhaust.png") else "pile_discard", Rect2(1230, 800, 84, 84), game.exhaust_pile.size(), "소모된 카드 (X)", "이번 전투에서 소모된 카드입니다. 전투가 끝나면 덱으로 돌아옵니다.

클릭하면 소모된 카드를 봅니다.", "exhaust")
		# until the dedicated icon is delivered, the discard art is tinted so the two piles read differently
		if not ResourceLoader.exists("res://assets/ui/battle/pile_exhaust.png"): get_node("ExhaustPile").modulate = Color(0.78, 0.6, 1.0)
	var controls := VBoxContainer.new()
	controls.name = "BattleControls"
	controls.add_theme_constant_override("separation", 8)
	place(controls, Rect2(1160, 640, 270, 142))
	for pair in [["덱 보기 (D)", open_pile.bind("deck")], ["턴 종료", game.end_turn]]:
		var button := Button.new()
		button.text = pair[0]
		button.add_theme_font_override("font", UiFont.serif())
		button.disabled = game.battle_busy
		button.pressed.connect(pair[1])
		if pair[0] == "턴 종료":
			button.name = "EndTurn"
			button.custom_minimum_size = Vector2(270, 90)
			button.add_theme_font_size_override("font_size", 31)
			button.add_theme_color_override("font_color", Color("f1deb0"))
			button.add_theme_color_override("font_hover_color", Color("fff3d0"))
			button.add_theme_color_override("font_pressed_color", Color("fff3d0"))
			button.add_theme_color_override("font_disabled_color", Color("77707e"))
			for slot in [["normal", "normal"], ["hover", "hover"], ["pressed", "hover"], ["disabled", "disabled"]]:
				var skin := StyleBoxTexture.new()
				skin.texture = load("res://assets/ui/battle/v2/end_turn_%s.png" % slot[1])
				button.add_theme_stylebox_override(slot[0], skin)
			button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		else:
			button.custom_minimum_size = Vector2(270, 44)
			button.add_theme_font_size_override("font_size", 21)
			var box := StyleBoxFlat.new()
			box.bg_color = Color("241b30")
			box.border_color = Color("ad8953")
			box.set_border_width_all(2)
			box.set_corner_radius_all(9)
			button.add_theme_stylebox_override("normal", box)
		controls.add_child(button)
	_build_top_bar()
	# potions sit in the top bar next to the place name, above the relic row, so nothing covers them
	var belt = game.PotionBelt.new()
	place(belt, Rect2(900, 10, 190, 58))
	belt.setup(game.potions, game.POTION_SLOTS, not game.battle_busy)
	belt.used.connect(game.use_potion)

func _ui_picture(id: String, file: String, rect: Rect2) -> TextureRect:
	var picture := TextureRect.new()
	picture.name = id
	picture.texture = load("res://assets/ui/%s.png" % file)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	place(picture, rect)
	return picture

func _top_text(id: String, text: String, rect: Rect2, color: Color, font := 28) -> Label:
	var label := label_named(id, text, rect, font, color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", UiFont.serif())
	label.add_theme_color_override("font_outline_color", Color("120a18"))
	label.add_theme_constant_override("outline_size", 6)
	return label

## Top bar: face, HP, gold, place, deck button and one slot per owned relic.
func _build_top_bar() -> void:
	_ui_picture("TopBarFrame", "topbar/topbar_frame", Rect2(0, 0, 1440, 76))
	var id: String = game.selected_character.id
	var portrait_path := "res://assets/characters/%s/portrait/%s_map_portrait_plague_v2.png" % [id, id]
	if not ResourceLoader.exists(portrait_path):
		portrait_path = "res://assets/characters/%s/portrait/%s_map_portrait.png" % [id, id]
	if ResourceLoader.exists(portrait_path):
		var face := TextureRect.new()
		face.name = "TopBarFace"
		var crop := AtlasTexture.new()
		crop.atlas = load(portrait_path)
		crop.region = Rect2(430, 280, 520, 520)
		face.texture = crop
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# UV spans the whole atlas image, so the circle is measured inside the cropped region.
		var circle := Shader.new()
		circle.code = "shader_type canvas_item;\nuniform vec4 region;\nvoid fragment() {\n\tvec4 c = texture(TEXTURE, UV);\n\tvec2 p = (UV - region.xy) / region.zw;\n\tCOLOR = vec4(c.rgb, c.a * step(distance(p, vec2(0.5)), 0.5));\n}\n"
		var material := ShaderMaterial.new()
		material.shader = circle
		var size: Vector2 = crop.atlas.get_size()
		material.set_shader_parameter("region", Vector4(crop.region.position.x / size.x, crop.region.position.y / size.y, crop.region.size.x / size.x, crop.region.size.y / size.y))
		face.material = material
		place(face, Rect2(20, 10, 68, 68))
	_ui_picture("TopBarRing", "topbar/portrait_ring", Rect2(10, 0, 88, 88))
	# Content row is centred on y=40 (between the frame's two gold lines at about 20 and 60).
	_ui_picture("TopBarHpIcon", "topbar/icon_hp", Rect2(118, 16, 48, 48))
	_top_text("TopBarHp", "%d/%d" % [game.hp, game.max_hp], Rect2(172, 12, 140, 56), Color("f0707e"), 32).horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_ui_picture("TopBarGoldIcon", "topbar/icon_gold", Rect2(330, 16, 48, 48))
	_top_text("TopBarGold", str(game.gold), Rect2(384, 12, 120, 56), Color("f2cf72"), 32).horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_ui_picture("TopBarFloorIcon", "topbar/icon_floor", Rect2(530, 16, 48, 48))
	_top_text("TopBarPlace", {1: "잿빛 성당", 2: "검은 운하", 3: "유리 온실", 4: "이름 없는 서고"}.get(int(game.current_act), "잿빛 성당"), Rect2(584, 12, 260, 56), Color("e7d8c0"), 28).horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var deck := TipIcon.new()
	deck.name = "TopBarDeck"
	deck.texture = load("res://assets/ui/topbar/icon_deck.png")
	deck.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	deck.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	deck.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	deck.mouse_filter = Control.MOUSE_FILTER_STOP
	deck.setup_tip("덱 (D)", "이번 원정에서 가진 모든 카드를 봅니다.")
	deck.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			open_pile("deck"))
	place(deck, Rect2(1290, 8, 62, 62))
	_badge("TopBarDeckCount", Rect2(1330, 40, 34, 34), game.deck.size())
	# many relics: tighten the spacing so the row never runs into the deck button
	var relic_pitch := minf(76.0, 1240.0 / maxf(1.0, float(game.owned_relics.size())))
	for i in range(game.owned_relics.size()):
		var record: Dictionary = game.Data.find_record("relics", str(game.owned_relics[i]))
		var slot := TipIcon.new()
		slot.name = "Relic%d" % i
		slot.texture = load("res://assets/ui/topbar/relic_slot.png")
		slot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		slot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		slot.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		slot.mouse_filter = Control.MOUSE_FILTER_STOP
		slot.setup_tip(str(record.get("name", game.owned_relics[i])), "%s · %s" % [record.get("rarity", ""), record.get("effect", "")] if not record.is_empty() else "")
		place(slot, Rect2(16 + i * relic_pitch, 82, 72, 72))
		var art_path: String = str(record.get("art", ""))
		if not art_path.is_empty() and ResourceLoader.exists(art_path):
			var art := TextureRect.new()
			art.name = "RelicArt"
			art.texture = load(art_path)
			art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			art.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot.add_child(art)
			art.position = Vector2(14, 14)
			art.size = Vector2(44, 44)

func _badge(id: String, rect: Rect2, count: int) -> Label:
	var badge := Label.new()
	badge.name = id
	badge.text = str(count)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 20)
	badge.add_theme_font_override("font", UiFont.serif())
	badge.add_theme_color_override("font_outline_color", Color.BLACK)
	badge.add_theme_constant_override("outline_size", 4)
	var box := StyleBoxFlat.new()
	box.bg_color = Color("7a1c2c")
	box.border_color = Color("e0c27a")
	box.set_border_width_all(2)
	box.set_corner_radius_all(17)
	badge.add_theme_stylebox_override("normal", box)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	place(badge, rect)
	return badge

func _build_intent(action: Dictionary) -> void:
	var kind := MonsterActions.kind(action)
	var bonus: int = game.enemy_status.amount("empower")
	var per_hit: int = game.enemy_hit_value(action, bonus)
	var intent := Control.new()
	intent.name = "Intent"
	# Stage top is y=110; the icon floats about 65px above the enemy's box.
	place(intent, Rect2(1010, 110 + FEET_Y - ENEMY_BOX.y * UNIT_SCALE * float(game.enemy.get("scale", 1.0)) - 65, 220, 70))
	intent.mouse_filter = Control.MOUSE_FILTER_STOP
	intent.tooltip_text = "%s\n%s" % [str(action.get("name", "")), MonsterActions.text(action, game.enemy_status.amount("strength") + bonus)]
	var icon := TextureRect.new()
	icon.name = "IntentIcon"
	icon.texture = load("res://assets/ui/battle/intent_%s.png" % kind)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intent.add_child(icon)
	icon.position = Vector2(8, 3)
	icon.size = Vector2(64, 64)
	var cursor := 76.0
	if kind == "attack":
		var hits := maxi(1, int(action.get("hits", 1)))
		var amount := Label.new()
		amount.name = "IntentValue"
		amount.text = "%d×%d" % [per_hit, hits] if hits > 1 else str(per_hit)
		amount.add_theme_font_size_override("font_size", 36)
		amount.add_theme_font_override("font", UiFont.serif())
		amount.add_theme_color_override("font_color", Color("ffd39b"))
		amount.add_theme_color_override("font_outline_color", Color.BLACK)
		amount.add_theme_constant_override("outline_size", 7)
		amount.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		amount.mouse_filter = Control.MOUSE_FILTER_IGNORE
		intent.add_child(amount)
		amount.position = Vector2(cursor, 6)
		amount.size = Vector2(88 if hits > 1 else 64, 58)
		cursor += amount.size.x
	for extra in MonsterActions.extras(action):
		var small := TextureRect.new()
		small.name = "IntentExtra_" + extra
		small.texture = load("res://assets/ui/battle/intent_%s.png" % extra)
		small.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		small.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		small.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		small.mouse_filter = Control.MOUSE_FILTER_IGNORE
		intent.add_child(small)
		small.position = Vector2(cursor, 20)
		small.size = Vector2(36, 36)
		cursor += 38.0

## Opens the card grid for "draw", "discard" or "deck". Ignored while an action is running.
func open_pile(kind: String) -> void:
	if is_instance_valid(viewer) or game.battle_busy: return
	var hand = get_node_or_null("Hand")
	viewer = PileViewer.new()
	place(viewer, Rect2(Vector2.ZERO, DESIGN))
	match kind:
		"draw":
			viewer.setup("뽑을 카드 더미 · %d장" % game.draw_pile.size(), game.draw_pile, "매 턴이 시작될 때마다 이곳에서 카드를 뽑습니다.\n(표시되는 카드들은 희귀도에 따라 정렬됩니다)", true)
		"exhaust":
			viewer.setup("소모된 카드 · %d장" % game.exhaust_pile.size(), game.exhaust_pile, "소모된 카드는 이번 전투 동안 다시 쓸 수 없습니다. 전투가 끝나면 덱으로 돌아옵니다.", false)
		"discard":
			viewer.setup("버린 카드 더미 · %d장" % game.discard_pile.size(), game.discard_pile, "뽑을 카드 더미에 카드가 없으면, 이곳의 카드를 섞어 다시 뽑을 카드 더미로 만듭니다.", false)
		_:
			viewer.setup("현재 덱 · %d장" % game.deck.size(), game.deck, "이번 원정에서 가진 모든 카드입니다.", false)
	if hand:
		hand.cancel()
		hand.locked = true
	viewer.closed.connect(func():
		viewer = null
		if is_instance_valid(hand): hand.locked = game.battle_busy)

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo): return
	if is_instance_valid(viewer): return
	match event.keycode:
		KEY_A: open_pile("draw")
		KEY_S: open_pile("discard")
		KEY_X: if not game.exhaust_pile.is_empty(): open_pile("exhaust")
		KEY_D: open_pile("deck")

func _pile(id: String, art: String, rect: Rect2, count: int, title: String, body: String, kind: String) -> void:
	var icon := TipIcon.new()
	icon.name = id
	icon.texture = load("res://assets/ui/battle/%s.png" % art)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	icon.mouse_filter = Control.MOUSE_FILTER_STOP
	icon.setup_tip(title, body)
	icon.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			open_pile(kind))
	place(icon, rect)
	_badge(id + "Count", Rect2(rect.end.x - 34, rect.end.y - 34, 34, 34), count)

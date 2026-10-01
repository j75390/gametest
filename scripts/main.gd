extends Control

const Data = preload("res://scripts/game_data.gd")
var enemy: Dictionary = {}
var enemy_turn := 0
const UnitStatus = preload("res://scripts/unit_status.gd")
const BattleHand = preload("res://scripts/battle_hand.gd")
const BattleFX = preload("res://scripts/battle_fx.gd")
var battle_fx
const StatusPanel = preload("res://scripts/status_panel.gd")
var player_status = UnitStatus.new()
var enemy_status = UnitStatus.new()
var bleed: int:
	get: return enemy_status.amount("bleed")
	set(value): enemy_status.set_amount("bleed", value)
var next_attack: int:
	get: return player_status.amount("empower")
	set(value): player_status.set_amount("empower", value)
var owned_relics: Array[String] = []
const Assets = preload("res://scripts/character_assets.gd")
const CharacterVisual = preload("res://scripts/character_visual.gd")
var battle_motion := "idle"
var battle_busy := false
var enemy_max_hp := 45
var venom_turns: int:
	get: return enemy_status.amount("venom")
	set(value): enemy_status.set_amount("venom", value)
var venom_rate: float:
	get: return float(enemy_status.entries.get("venom", {}).get("rate", 0.0))
	set(value):
		if enemy_status.entries.has("venom"):
			enemy_status.entries["venom"]["rate"] = value

var screen := "menu"
var selected_character := {}
var characters := []
var card_db := {}
var relic_db := []

var hp := 80
var max_hp := 80
var energy := 3
var block := 0
var enemy_hp := 45
var gold := 120
var deck:Array = []
var draw_pile:Array = []
var discard_pile:Array = []
var hand:Array = []
const ExpeditionMap = preload("res://scripts/expedition_map.gd")
const MapView = preload("res://scripts/map_view.gd")
var expedition = ExpeditionMap.new()
var has_full_map := false

var bg := ColorRect.new()
var title := Label.new()
var content: VBoxContainer
var footer := Label.new()
var shell: MarginContainer
var title_menu: Control

func _ready():
	_load_data()
	_build_shell()
	show_menu()

func _load_data():
	characters = Data.read("characters")
	card_db = Data.cards()
	relic_db = Data.read("relics")

func _read_json(path:String):
	var f = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return []
	return JSON.parse_string(f.get_as_text())

func _build_shell():
	bg.color = Color("#09070a")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var frame = MarginContainer.new()
	shell = frame
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.add_theme_constant_override("margin_left", 42)
	frame.add_theme_constant_override("margin_right", 42)
	frame.add_theme_constant_override("margin_top", 32)
	frame.add_theme_constant_override("margin_bottom", 28)
	add_child(frame)

	var root_v = VBoxContainer.new()
	root_v.add_theme_constant_override("separation", 18)
	frame.add_child(root_v)

	title.text = "잿빛 원정대"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 46)
	title.modulate = Color("#e7d5b6")
	root_v.add_child(title)

	var sep = HSeparator.new()
	root_v.add_child(sep)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_v.add_child(scroll)

	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 14)
	scroll.add_child(content)

	footer.text = "Godot 4.x • 덱빌딩 로그라이크 프로토타입"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.modulate = Color("#8d7d75")
	root_v.add_child(footer)

func clear_content():
	content.add_theme_constant_override("separation", 14)
	if is_instance_valid(title_menu):
		remove_child(title_menu)
		title_menu.queue_free()
		title_menu = null
	shell.show()
	for c in content.get_children():
		content.remove_child(c)
		c.queue_free()

func add_heading(text_value:String):
	var l = Label.new()
	l.text = text_value
	l.add_theme_font_size_override("font_size", 28)
	l.modulate = Color("#d8b47a")
	content.add_child(l)

func add_text(text_value:String):
	var l = Label.new()
	l.text = text_value
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", 18)
	l.modulate = Color("#d4c7c0")
	content.add_child(l)
	return l

func add_button(text_value:String, callable:Callable):
	var b = Button.new()
	b.text = text_value
	b.custom_minimum_size = Vector2(0, 48)
	b.add_theme_font_size_override("font_size", 20)
	b.pressed.connect(callable)
	content.add_child(b)
	return b

func show_menu():
	screen = "menu"
	clear_content()
	shell.hide()
	title_menu = load("res://scripts/title_menu.gd").new()
	title_menu.name = "TitleMenu"
	title_menu.chosen.connect(func(action):
		match action:
			"single": show_character_select()
			"multi": show_multiplayer()
			"codex": show_codex()
			"settings": show_settings()
			"quit": get_tree().quit()
	)
	add_child(title_menu)

func show_character_select():
	screen = "character_select"
	clear_content()
	var selection = load("res://scripts/character_select.gd").new()
	selection.name = "CharacterSelection"
	selection.setup(characters)
	selection.codex_requested.connect(show_codex)
	selection.character_chosen.connect(func(ch):
		remove_child(selection)
		selection.queue_free()
		choose_character(ch)
	)
	selection.back_requested.connect(func():
		remove_child(selection)
		selection.queue_free()
		show_menu()
	)
	add_child(selection)

func choose_character(ch):
	owned_relics.clear()
	selected_character = ch
	max_hp = int(ch.max_hp)
	hp = max_hp
	gold = 120
	deck.clear()
	for i in range(5):
		deck.append(card_db.common[0].duplicate(true))
	for i in range(5):
		deck.append(card_db.common[1].duplicate(true))
	_generate_map()
	show_map()

func _generate_map():
	expedition.generate(int(Time.get_unix_time_from_system() * 1000000) ^ randi())
	has_full_map = false

func show_map():
	screen = "map"
	clear_content()
	title.text = "원정 지도"
	add_text("%s · HP %d/%d · GOLD %d  |  ACT I · 잿빛 성당" % [selected_character.name, hp, max_hp, gold])
	if expedition.completed:
		add_heading("성당의 수문장을 쓰러뜨렸습니다")
		add_text("현재 구현된 원정을 마쳤습니다. 다음 ACT는 아직 준비 중입니다.")
		add_button("메인 메뉴", show_menu)
		return
	add_text("탐험가의 지도 · 현재 ACT 전체 공개" if has_full_map else "연결된 길을 선택하세요 · 앞으로 두 걸음까지 공개 · 금빛 길은 지나온 경로")
	var legend = HBoxContainer.new()
	legend.add_theme_constant_override("separation", 16)
	content.add_child(legend)
	for kind in ["전투", "엘리트", "상점", "이벤트", "휴식", "보물", "보스"]:
		var item = Button.new()
		item.text = kind
		item.icon = load("res://assets/map/icons/%s.png" % MapView.ICONS[kind])
		item.expand_icon = true
		item.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		item.add_theme_constant_override("icon_max_width", 32)
		item.custom_minimum_size = Vector2(100, 40)
		item.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item.focus_mode = Control.FOCUS_NONE
		legend.add_child(item)
	var scroll = ScrollContainer.new()
	scroll.name = "ExpeditionScroll"
	scroll.custom_minimum_size = Vector2(0, 470)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)
	var view = MapView.new()
	view.name = "RouteMap"
	scroll.add_child(view)
	view.setup(expedition, has_full_map, [{"player_id":"local", "character_id":selected_character.id, "node_id":expedition.current_id, "display_name":selected_character.name, "color":"e5bd72", "is_local":true}])
	view.node_selected.connect(enter_node)
	var toolbar = HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 12)
	content.add_child(toolbar)
	var actions = [func(): scroll.scroll_vertical = int(view.point(expedition.current_id).y - 360), show_deck, show_menu]
	var labels = ["현재 위치로", "덱 보기", "← 메인 메뉴"]
	for i in range(labels.size()):
		var button = Button.new()
		button.text = labels[i]
		button.custom_minimum_size.y = 44
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(actions[i])
		toolbar.add_child(button)
	await get_tree().process_frame
	if is_instance_valid(scroll):
		scroll.scroll_vertical = int(view.point(expedition.current_id).y - 360)

func enter_node(id:int):
	if screen != "map" or not expedition.enter(id):
		return
	screen = "encounter"
	var t = expedition.nodes[id].type
	if t in ["전투", "엘리트", "보스"]:
		start_battle(t)
	elif t == "상점":
		show_shop()
	elif t == "휴식":
		show_rest()
	elif t == "보물":
		show_treasure()
	else:
		show_event()

func advance_map():
	expedition.resolve()
	show_map()

func start_battle(kind:String):
	screen = "battle"
	player_status.entries.clear()
	enemy_status.entries.clear()
	enemy = Data.read("monsters")[0 if kind == "전투" else (1 if kind == "엘리트" else 2)]
	enemy_hp = int(enemy.hp)
	enemy_turn = 0
	bleed = 0
	next_attack = 0
	enemy_max_hp = enemy_hp
	venom_turns = 0
	venom_rate = 0.0
	battle_busy = false
	battle_motion = "idle"
	block = 0
	draw_pile = deck.duplicate(true)
	draw_pile.shuffle()
	discard_pile.clear()
	hand.clear()
	energy = 3
	_draw_cards(5)
	enemy_status.apply(enemy.get("powers", []))
	show_battle()

func _draw_cards(n:int):
	for i in range(n):
		if draw_pile.is_empty():
			draw_pile = discard_pile.duplicate(true)
			discard_pile.clear()
			draw_pile.shuffle()
		if draw_pile.is_empty():
			return
		hand.append(draw_pile.pop_back())

func show_battle():
	clear_content()
	title.text = "전투"
	add_text("%s  HP %d/%d   방어 %d   에너지 %d/3" % [selected_character.name, hp, max_hp, block, energy]).name = "PlayerSummary"
	var stage = HBoxContainer.new()
	stage.name = "BattleStage"
	stage.alignment = BoxContainer.ALIGNMENT_CENTER
	stage.add_theme_constant_override("separation", 100)
	content.add_child(stage)
	if Assets.count(selected_character.id, "idle") > 0:
		var actor = CharacterVisual.new()
		actor.name = "Hero"
		actor.custom_minimum_size = Vector2(340, 230)
		stage.add_child(actor)
		actor.setup(selected_character.id, battle_motion)
	else:
		add_picture(stage, Assets.picture(selected_character.id, "full"), Vector2(240, 230))
	add_picture(stage, load(enemy.art), Vector2(240, 230)).name = "Enemy"
	stage.get_node("Enemy").set_script(preload("res://scripts/battle_unit_view.gd"))
	var status_row := HBoxContainer.new()
	status_row.name = "UnitStatuses"
	status_row.alignment = BoxContainer.ALIGNMENT_CENTER
	status_row.add_theme_constant_override("separation", 120)
	content.add_child(status_row)
	var player_panel = StatusPanel.new()
	player_panel.name = "Player"
	status_row.add_child(player_panel)
	player_panel.setup(selected_character.name, hp, max_hp, player_status)
	var enemy_panel = StatusPanel.new()
	enemy_panel.name = "Enemy"
	status_row.add_child(enemy_panel)
	enemy_panel.setup(enemy.name, enemy_hp, enemy_max_hp, enemy_status)
	add_text("%s · 다음 행동: %s" % [enemy.name, enemy.pattern[enemy_turn % enemy.pattern.size()].name]).name = "Intent"
	add_text("적 HP: %d / %d   ·   독 %d중첩 · 맹독 %d턴" % [enemy_hp, enemy_max_hp, enemy_status.amount("poison"), venom_turns]).name = "EnemySummary"
	if selected_character.id == "mira":
		content.add_theme_constant_override("separation", 6)
		var hand_view = BattleHand.new()
		hand_view.name = "Hand"
		content.add_child(hand_view)
		hand_view.setup(hand, energy, battle_busy, stage.get_node("Enemy"))
		hand_view.card_requested.connect(play_card)
		var controls := HBoxContainer.new()
		controls.name = "BattleControls"
		content.add_child(controls)
		var hint := Label.new()
		hint.text = "카드 → 적 드래그 · 클릭 후 대상 선택 · 우클릭/ESC 취소"
		hint.add_theme_font_size_override("font_size", 14)
		hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		controls.add_child(hint)
		for pair in [["덱 보기", show_deck], ["턴 종료", end_turn]]:
			var button: Button = add_button(pair[0], pair[1])
			button.disabled = battle_busy
			button.custom_minimum_size.x = 140
			content.remove_child(button)
			controls.add_child(button)
	else:
		var cards_row = HBoxContainer.new()
		cards_row.name = "Hand"
		cards_row.add_theme_constant_override("separation", 12)
		content.add_child(cards_row)
		for i in range(hand.size()):
			var c = hand[i]
			var box = VBoxContainer.new()
			box.custom_minimum_size.x = 205
			box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cards_row.add_child(box)
			if c.has("art"):
				add_picture(box, load(c.art), Vector2(0, 115))
			var b = Button.new()
			b.text = "%s [%d]\n%s · %s\n%s" % [c.name, c.cost, c.rarity, c.type, Data.effect_text(c)]
			b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			b.custom_minimum_size = Vector2(205, 105)
			b.disabled = battle_busy or int(c.cost) > energy
			b.pressed.connect(func(index=i): play_card(index))
			box.add_child(b)
		add_button("턴 종료", end_turn).disabled = battle_busy
		add_button("덱 보기", show_deck).disabled = battle_busy

	_refresh_battle_tooltips()

func _refresh_battle_hp() -> void:
	_refresh_battle_tooltips()
	content.get_node("PlayerSummary").text = "%s  HP %d/%d   방어 %d   에너지 %d/3" % [selected_character.name, hp, max_hp, block, energy]
	content.get_node("EnemySummary").text = "적 HP: %d / %d   ·   독 %d중첩 · 맹독 %d턴" % [enemy_hp, enemy_max_hp, enemy_status.amount("poison"), venom_turns]
	for pair in [["Player", hp], ["Enemy", enemy_hp]]:
		var panel = content.get_node_or_null("UnitStatuses/" + pair[0])
		if panel: panel.get_child(0).value = maxi(0, pair[1])

func _refresh_battle_tooltips() -> void:
	var hero = content.get_node_or_null("BattleStage/Hero")
	if hero:
		hero.tooltip_text = "%s · %s\nHP %d/%d · 방어 %d\n%s\n\n%s" % [selected_character.name, selected_character.get("class", ""), hp, max_hp, block, selected_character.get("theme", ""), StatusPanel.describe_all(player_status, max_hp)]
	var target = content.get_node_or_null("BattleStage/Enemy")
	var intent = content.get_node_or_null("Intent")
	var action: Dictionary = enemy.pattern[enemy_turn % enemy.pattern.size()]
	var text := "%s\n공격 피해 %d" % [action.name, int(action.damage) + enemy_status.amount("empower")]
	for applied in action.get("apply_statuses", []):
		var id: String = applied if applied is String else str(applied.get("id", ""))
		var definition := Data.find_record("powers", id)
		text += "\n부여: %s" % definition.get("name", id)
		if applied is Dictionary: text += " %d" % applied.get("amount", 1)
	if intent:
		intent.mouse_filter = Control.MOUSE_FILTER_STOP
		intent.tooltip_text = text
	if target:
		target.tooltip_text = "%s · HP %d/%d\n%s\n\n다음 행동: %s\n\n%s" % [enemy.name, enemy_hp, enemy_max_hp, enemy.get("effect", ""), text, StatusPanel.describe_all(enemy_status, enemy_max_hp)]

func _begin_fx():
	var fx = BattleFX.new()
	fx.name = "BattleFX"
	add_child(fx)
	battle_fx = fx
	return fx

func _card_effect(c: Dictionary) -> int:
	if c.has("venom_turns"):
		venom_turns = int(c.venom_turns)
		venom_rate = float(c.venom_rate)
	var damage := int(c.get("damage", 0))
	if c.type == "공격":
		damage += player_status.consume_attack()
		if owned_relics.has("blood_contract"):
			damage = ceili(damage * Data.find_record("relics", "blood_contract").damage_multiplier)
	enemy_hp = maxi(0, enemy_hp - damage)
	bleed += int(c.get("bleed", 0))
	enemy_status.set_amount("poison", enemy_status.amount("poison") + int(c.get("poison", 0)))
	next_attack += int(c.get("next_attack", 0))
	block += int(c.get("block", 0))
	hp = mini(max_hp, hp + int(c.get("heal", 0)))
	_refresh_battle_hp()
	return damage

func play_card(index:int):
	if battle_busy or screen != "battle" or index < 0 or index >= hand.size():
		return
	var c: Dictionary = hand[index]
	if int(c.cost) > energy: return
	battle_busy = true
	battle_motion = "attack" if c.type == "공격" else "skill"
	energy -= int(c.cost)
	discard_pile.append(c)
	hand.remove_at(index)
	show_battle()
	if selected_character.id == "mira":
		await get_tree().process_frame
		var hero = content.get_node("BattleStage/Hero")
		var target = content.get_node("BattleStage/Enemy")
		var fx = _begin_fx()
		var offensive: bool = c.get("damage", 0) > 0 or c.get("poison", 0) > 0 or c.get("venom_turns", 0) > 0 or c.get("bleed", 0) > 0
		var color := Color("bd74ff") if not c.has("poison") else Color("70e85a")
		var apply := func():
			var damage := _card_effect(c)
			if offensive:
				fx.impact(target, color, str(-damage) if damage > 0 else ("독 +%d" % c.poison if c.has("poison") else "맹독 %d턴" % c.get("venom_turns", 0)), damage > 0)
			if c.get("block", 0) > 0: fx.float_text(hero, "방어 +%d" % c.block, Color("79cce7"))
			if c.get("heal", 0) > 0: fx.float_text(hero, "회복 +%d" % c.heal, Color("8cedb0"))
		if offensive:
			await fx.strike(hero, target, c.type != "공격", color, apply)
		else:
			await fx.pulse(hero, Color("79cce7"), apply)
		if enemy_hp <= 0:
			var fade = create_tween()
			fade.tween_property(target, "modulate:a", 0.0, 0.3)
			await fade.finished
		fx.queue_free()
	else:
		_card_effect(c)
		await get_tree().create_timer(maxf(0.8, Assets.motion_duration(selected_character.id, battle_motion) + 0.05)).timeout
	battle_busy = false
	battle_motion = "idle"
	if enemy_hp <= 0: show_reward()
	else: show_battle()

func _dot_phase(statuses, maximum: int, actor: Control, player: bool, fx) -> void:
	# Compute each tick once; display separate receipts for poison and venom.
	var receipts: Array = statuses.tick_details(maximum)
	for receipt in receipts:
		if player: hp = maxi(0, hp - receipt.damage)
		else: enemy_hp = maxi(0, enemy_hp - receipt.damage)
		_refresh_battle_hp()
		var color := Color("73e956") if receipt.id == "poison" else Color("c47bff")
		fx.impact(actor, color, "%s -%d" % [Data.find_record("powers", receipt.id).name, receipt.damage], false)
		await get_tree().create_timer(0.45).timeout

func end_turn():
	if battle_busy or screen != "battle": return
	battle_busy = true
	if selected_character.id == "mira":
		show_battle()
		await get_tree().process_frame
		var hero = content.get_node("BattleStage/Hero")
		var target = content.get_node("BattleStage/Enemy")
		var fx = _begin_fx()
		await _dot_phase(enemy_status, enemy_max_hp, target, false, fx)
		if enemy_hp > 0:
			var action: Dictionary = enemy.pattern[enemy_turn % enemy.pattern.size()]
			var incoming := int(action.damage) + enemy_status.consume_attack()
			await fx.strike(target, hero, false, Color("f4b58d"), func():
				var damage := maxi(0, incoming - block)
				hp = maxi(0, hp - damage)
				player_status.apply(action.get("apply_statuses", []))
				if damage > 0: hero.play("death" if hp <= 0 else "hurt")
				fx.impact(hero, Color("f4b58d"), str(-damage) if damage > 0 else "방어", damage > 0)
				_refresh_battle_hp()
			)
			enemy_turn += 1
			await _dot_phase(player_status, max_hp, hero, true, fx)
		if enemy_hp <= 0:
			var fade = create_tween()
			fade.tween_property(target, "modulate:a", 0.0, 0.3)
			await fade.finished
		if hp <= 0:
			if hero.motion != "death": hero.play("death")
			while not hero.finished: await get_tree().process_frame
			await get_tree().create_timer(0.1).timeout
		await fx.drain()
		fx.queue_free()
	else:
		enemy_hp = maxi(0, enemy_hp - enemy_status.tick(enemy_max_hp))
		if enemy_hp > 0:
			var action: Dictionary = enemy.pattern[enemy_turn % enemy.pattern.size()]
			var incoming = int(action.damage) + enemy_status.consume_attack()
			player_status.apply(action.get("apply_statuses", []))
			enemy_turn += 1
			var damage = max(0, incoming - block)
			hp = maxi(0, hp - damage - player_status.tick(max_hp))
			battle_motion = "death" if hp <= 0 else ("hurt" if damage > 0 else "idle")
			show_battle()
			await get_tree().create_timer(maxf(1.0, Assets.motion_duration(selected_character.id, battle_motion) + 0.1)).timeout
	battle_busy = false
	battle_motion = "idle"
	if enemy_hp <= 0:
		show_reward()
		return
	if hp <= 0:
		show_game_over()
		return
	for c in hand: discard_pile.append(c)
	hand.clear()
	block = 0
	energy = 3
	_draw_cards(5)
	show_battle()

func show_reward():
	screen = "reward"
	clear_content()
	title.text = "전투 보상"
	add_text("GOLD +%d" % enemy.gold)
	gold += int(enemy.gold)
	add_heading("전용 카드 보상 · 1장 선택 또는 스킵")
	var pool = card_db.get(selected_character.id, [])
	var choices = []
	for i in range(min(3, pool.size())):
		choices.append(pool[i].duplicate(true))
	for c in choices:
		if c.has("art"):
			add_picture(content, load(c.art), Vector2(0, 240))
		var b = Button.new()
		b.text = "%s  [%d]\n%s · %s\n%s" % [c.name, c.cost, c.rarity, c.type, Data.effect_text(c)]
		b.custom_minimum_size = Vector2(0, 92)
		b.pressed.connect(func(card=c): take_reward_card(card))
		content.add_child(b)
	add_button("보상 스킵", advance_map)

func take_reward_card(card):
	deck.append(card.duplicate(true))
	advance_map()

func show_shop():
	clear_content()
	title.text = "상점"
	add_text("판매 기능 없음 · 카드 / 유물 / 포션 / 카드 제거 서비스")
	add_text("GOLD: %d" % gold)
	add_heading("카드")
	var pool = card_db.get(selected_character.id, [])
	for c in pool:
		if c.has("art"):
			add_picture(content, load(c.art), Vector2(0, 220))
		var price = 60
		var b = Button.new()
		b.text = "%s  · %dG\n%s" % [c.name, price, Data.effect_text(c)]
		b.disabled = gold < price
		b.pressed.connect(func(card=c, p=price): buy_card(card, p))
		content.add_child(b)
	add_heading("포션 / 유물")
	for potion in Data.read("potions"):
		add_picture(content, load(potion.art), Vector2(0, 100))
		add_button(potion.name + " · 즉시 복용 · %dG · " % potion.price + Data.effect_text(potion), buy_potion.bind(potion)).disabled = gold < potion.price or hp >= max_hp
	for relic in relic_db:
		add_button(relic.name + " · 90G · " + relic.effect, buy_relic.bind(relic)).disabled = gold < 90 or owned_relics.has(relic.id)
	add_heading("서비스")
	var rm = Button.new()
	rm.text = "카드 제거 1회 · 75G"
	rm.disabled = gold < 75 or deck.size() <= 1
	rm.pressed.connect(remove_one_card)
	content.add_child(rm)
	add_button("상점 나가기", advance_map)

func buy_card(card, price:int):
	if gold >= price:
		gold -= price
		deck.append(card.duplicate(true))
	show_shop()

func remove_one_card():
	if gold >= 75 and deck.size() > 0:
		gold -= 75
		deck.pop_back()
	advance_map()

func show_rest():
	clear_content()
	title.text = "휴식"
	add_button("휴식: 최대 HP의 30% 회복", func():
		hp = min(max_hp, hp + int(max_hp * 0.3))
		advance_map()
	)
	for i in range(deck.size()):
		if not deck[i].get("upgraded", false):
			add_button("강화 · " + deck[i].name + " → " + Data.effect_text(Data.upgraded(deck[i])), upgrade_card.bind(i))

func show_treasure():
	clear_content()
	title.text = "보물"
	add_text(Data.find_record("relics", "explorer_map").effect)
	add_button("탐험가의 지도 획득", func():
		has_full_map = true
		if not owned_relics.has("explorer_map"):
			owned_relics.append("explorer_map")
		advance_map()
	)

func show_event():
	clear_content()
	var event = Data.read("events")[0]
	title.text = event.name
	add_picture(content, load(event.art), Vector2(0, 220))
	add_text(event.effect)
	var choice = event.choices[0]
	for i in range(deck.size()):
		if deck[i].type == "공격" and not deck[i].has("enchantment"):
			add_button(choice.name + " · " + deck[i].name, enchant_card.bind(i, choice)).disabled = hp <= choice.hp_cost
	add_button(event.choices[1].name, advance_map)

func enchant_card(index: int, choice: Dictionary):
	if hp <= choice.hp_cost or deck[index].has("enchantment"):
		return
	var enchantment = Data.find_record("enchantments", choice.enchantment)
	hp -= int(choice.hp_cost)
	deck[index].damage += int(enchantment.damage)
	if deck[index].upgrade.has("damage"):
		deck[index].upgrade.damage += int(enchantment.damage)
	deck[index]["enchantment"] = enchantment.id
	advance_map()

func upgrade_card(index: int):
	if not deck[index].get("upgraded", false):
		deck[index] = Data.upgraded(deck[index])
	advance_map()

func buy_potion(potion: Dictionary):
	if gold >= potion.price and hp < max_hp:
		gold -= int(potion.price)
		hp = mini(max_hp, hp + int(potion.heal))
	show_shop()

func buy_relic(relic: Dictionary):
	if gold >= 90 and not owned_relics.has(relic.id):
		gold -= 90
		owned_relics.append(relic.id)
		if relic.get("reveal_map", false):
			has_full_map = true
		if relic.has("hp_multiplier"):
			max_hp = maxi(1, floori(max_hp * relic.hp_multiplier))
			hp = mini(hp, max_hp)
	show_shop()

func show_deck():
	clear_content()
	title.text = "현재 덱"
	add_text("카드 수: %d" % deck.size())
	for c in deck:
		add_text("• %s [%s] 비용 %d — %s" % [c.name, c.rarity, c.cost, Data.effect_text(c)])
	add_button("← 돌아가기", func():
		if screen == "battle":
			show_battle()
		else:
			show_map()
	)

func show_codex():
	if has_node("Codex"):
		return
	var archive = load("res://scenes/Codex.tscn").instantiate()
	add_child(archive)
	archive.closed.connect(func():
		remove_child(archive)
		archive.queue_free()
	)

func show_settings():
	clear_content()
	title.text = "설정"
	add_text("BGM / 효과음 / 화면 / 텍스트 속도 설정 화면 골격")
	add_button("← 메인 메뉴", show_menu)

func show_multiplayer():
	clear_content()
	title.text = "멀티 플레이"
	add_text("친구 방 생성 / 코드 참가 / 준비 / 호스트 시작을 위한 화면 골격")
	add_button("← 메인 메뉴", show_menu)

func show_game_over():
	screen = "game_over"
	clear_content()
	title.text = "원정 실패"
	add_text("다시 원정할 수 있습니다.")
	add_button("메인 메뉴", show_menu)

func add_picture(parent: Node, tex: Texture2D, minimum: Vector2) -> TextureRect:
	var picture = TextureRect.new()
	picture.texture = tex
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.custom_minimum_size = minimum
	parent.add_child(picture)
	return picture

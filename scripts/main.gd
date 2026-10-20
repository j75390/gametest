extends Control
const Discovery = preload("res://scripts/codex_discovery.gd")

const Data = preload("res://scripts/game_data.gd")
const GameSettings = preload("res://scripts/game_settings.gd")
const FrameTint = preload("res://scripts/frame_tint.gd")
var enemy: Dictionary = {}
var enemy_turn := 0
## 1 = 잿빛 성당, 2 = 검은 운하. The map, monster pools and event pools follow it.
var current_act := 1
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
const MonsterActions = preload("res://scripts/monster_actions.gd")
const PotionBelt = preload("res://scripts/potion_belt.gd")
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

var screen := "menu":
	set(value):
		screen = value
		if music != null and value != "battle": music.for_screen(value)
		_apply_battle_speed()
## Fast fights: animations and waits run faster only while a battle is on screen (T cycles 1x -> 1.5x -> 2x, remembered between sessions).
const SPEED_STEPS := [1.0, 1.5, 2.0]
const SPEED_FILE := "user://battle_speed.json"
static var speed_file := SPEED_FILE
var battle_speed := 1.0
var _managed_scale := 1.0

func _apply_battle_speed() -> void:
	# a test (or anything else) that set Engine.time_scale itself is left alone
	if not is_equal_approx(Engine.time_scale, _managed_scale): return
	_managed_scale = battle_speed if screen == "battle" else 1.0
	Engine.time_scale = _managed_scale

func cycle_battle_speed() -> float:
	var index := SPEED_STEPS.find(battle_speed)
	battle_speed = SPEED_STEPS[(index + 1) % SPEED_STEPS.size()]
	var file := FileAccess.open(speed_file, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"battle_speed": battle_speed}))
		file.close()
	_apply_battle_speed()
	show_relic_toast("전투 속도 x%s" % str(battle_speed), 150.0)
	return battle_speed

func _load_battle_speed() -> void:
	if not FileAccess.file_exists(speed_file): return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(speed_file))
	if parsed is Dictionary and SPEED_STEPS.has(float(parsed.get("battle_speed", 1.0))): battle_speed = float(parsed.battle_speed)
var music
var sfx
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
## Potions carried between fights (ids), at most POTION_SLOTS; drunk from the belt in battle.
const POTION_SLOTS := 3
var potions: Array = []
var exhaust_pile: Array = []
var pain_battle := 0
var cards_played_turn := 0
var last_played: Dictionary = {}
## The junk card some strong cards leave behind: it cannot be played and is exhausted if it is still in hand at turn end.
const SIDE_EFFECT_CARD := {"id": "side_effect", "name": "부작용", "cost": 99, "type": "상태", "rarity": "일반",
	"art": "res://assets/cards/mira/side_effect_v2.png", "unplayable": true, "ethereal": true,
	"text": "사용할 수 없습니다. 휘발", "effect": "사용할 수 없습니다. 휘발"}
## Calamo's rats: one rat shrinks a hit by this much and is lost. Esca's embers: every this many embers give 1 block (was 3) at the start of a turn.
const RAT_GUARD := 4
const EMBER_WARMTH_STEP := 2
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
var content: Control
var standard_content: VBoxContainer
var battle_canvas: Control
var footer := Label.new()
var shell: MarginContainer
var title_menu: Control
var arrival_view: Control
var arrival_pending := false
var arrival_reward_taken := false
var arrival_event: Dictionary = {}
var arrival_card: Dictionary = {}
var story_flags: Dictionary = {}
var story_event: Dictionary = {}
var story_choice_taken := false
var story_follow_up := ""
## A fight an event leads into: the kind of enemy, started when the player leaves the event page.
var story_pending_battle := ""
var ending_seen := false
## Block the enemy keeps from its own move until its next turn, and the last enemy met (so fights do not repeat).
var enemy_block := 0
var last_enemy_id := ""
## Effects a story choice leaves for later, e.g. "next_battle_first_turn_block_minus_3".
var pending_effects: Array[String] = []
var block_penalty := 0
var battle_reward_claimed := false
const StoryRules = preload("res://scripts/story_rules.gd")
const RunSave = preload("res://scripts/run_save.gd")
const RelicStrip = preload("res://scripts/relic_strip.gd")
const RelicEngine = preload("res://scripts/relic_engine.gd")
const RelicChoice = preload("res://scripts/relic_choice.gd")
var relics = RelicEngine.new()
var battle_turn := 1
var kill_by_dot := false
var enemy_was_new := false
var reward_relic_lines: Array[String] = []
var reward_potion := ""
## HP a potion drunk this battle pays out on the victory screen (it does not stack: the best one counts).
var battle_end_heal := 0
## What the victory screen really paid (relic heal, potion heal), kept so that showing the screen again repeats the same lines.
var victory_heal_paid := {"relic": 0, "potion": 0}
var reward_cards: Array = []
var shop_visit_node := -1
var reward_relic_options: Array[String] = []
var reward_relic_taken := ""
const Timeline = preload("res://scripts/timeline.gd")
const CodexData = preload("res://scripts/codex_data.gd")
var run_log: Dictionary = {}
var last_settlement: Dictionary = {}

## Ends the current run's timeline bookkeeping exactly once (clear / death / abandon).
func settle_run(outcome: String) -> Dictionary:
	if run_log.is_empty() or run_log.get("settled", false): return {}
	var progress: Array = CodexData.progress()
	var percent := 0 if progress[1] == 0 else int(round(100.0 * progress[0] / progress[1]))
	var result := Timeline.settle(run_log, outcome, story_flags.keys(), percent)
	if not result.is_empty(): last_settlement = result
	return result

func add_timeline_summary() -> void:
	if last_settlement.is_empty(): return
	add_heading("연대표")
	add_text("점수 +%d  (누계 %d)" % [int(last_settlement.points), int(last_settlement.total)])
	for id in last_settlement.opened:
		var opened: Dictionary = Timeline.entry(str(id))
		if not opened.is_empty(): add_text("새 기록 · " + str(opened.title))
	add_button("연대표 보기", func(): show_codex_hub("story"))

func _notification(what: int) -> void:
	# an autosaved run can be continued later, so closing the game is not abandoning it
	if what == NOTIFICATION_WM_CLOSE_REQUEST and not _run_resumable(): settle_run("abandon")

func _ready():
	music = load("res://scripts/music.gd").new()
	music.name = "Music"
	add_child(music)
	sfx = load("res://scripts/sfx.gd").new()
	sfx.name = "Sfx"
	add_child(sfx)
	sfx.watch_buttons(get_tree())
	if RunSave.allowed(): _load_battle_speed()
	GameSettings.load_settings()
	GameSettings.apply_window()
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
	standard_content = content
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 14)
	scroll.add_child(content)

	footer.text = "Godot 4.x • 덱빌딩 로그라이크 프로토타입"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.modulate = Color("#8d7d75")
	root_v.add_child(footer)

func clear_content():
	if has_node("BattleFX"): get_node("BattleFX").queue_free()
	if is_instance_valid(battle_canvas):
		remove_child(battle_canvas)
		battle_canvas.queue_free()
		battle_canvas = null
		content = standard_content
	if is_instance_valid(shop_view):
		remove_child(shop_view)
		shop_view.queue_free()
		shop_view = null
	if is_instance_valid(reward_view):
		remove_child(reward_view)
		reward_view.queue_free()
		reward_view = null
	if is_instance_valid(rest_view):
		remove_child(rest_view)
		rest_view.queue_free()
		rest_view = null
	if is_instance_valid(arrival_view):
		remove_child(arrival_view)
		arrival_view.queue_free()
		arrival_view = null
	title.show()
	footer.show()
	title.get_parent().get_child(1).show()
	content.size_flags_vertical = Control.SIZE_FILL
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

## True while the autosave holds this expedition, i.e. leaving it is not giving it up.
func _run_resumable() -> bool:
	return RunSave.allowed() and not run_log.is_empty() and not run_log.get("settled", false) and RunSave.has_save()

func show_menu():
	if not _run_resumable(): settle_run("abandon")
	screen = "menu"
	clear_content()
	shell.hide()
	title_menu = load("res://scripts/title_menu.gd").new()
	title_menu.name = "TitleMenu"
	if RunSave.allowed():
		var saved := RunSave.summary()
		if not saved.is_empty():
			for c in characters:
				if str(c.get("id", "")) == str(saved.character): saved["name"] = str(c.get("name", ""))
			title_menu.continue_info = saved
	title_menu.chosen.connect(func(action):
		match action:
			"continue":
				if not continue_saved_run(): show_character_select()
			"single": show_character_select()
			"multi": show_multiplayer()
			"codex": show_codex_hub()
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
	selection.codex_requested.connect(show_codex_hub)
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
	settle_run("abandon")
	RunSave.autoclear()
	current_act = 1
	ending_seen = false
	reward_pity = 0
	last_settlement = {}
	story_flags.clear()
	story_event.clear()
	story_choice_taken = false
	story_follow_up = ""
	pending_effects.clear()
	block_penalty = 0
	relics.reset_run()
	shop_visit_node = -1
	shop_stock.clear()
	removal_count = 0
	owned_relics.clear()
	potions.clear()
	selected_character = ch
	FrameTint.hero = str(ch.get("id", ""))
	card_db = Data.cards(ch.id)
	var starting_relic := Data.starting_relic(ch.id)
	if not starting_relic.is_empty(): owned_relics.append(starting_relic.id)
	if not owned_relics.is_empty(): Discovery.record("유물", str(owned_relics.back()))
	max_hp = int(ch.max_hp)
	hp = max_hp
	gold = 120
	deck.clear()
	for i in range(5):
		deck.append(card_db.common[0].duplicate(true))
		Discovery.record("카드", str(deck.back().id))
	for i in range(5):
		deck.append(card_db.common[1].duplicate(true))
		Discovery.record("카드", str(deck.back().id))
	_generate_map()
	run_log = Timeline.new_run(str(ch.id))
	arrival_pending = true
	arrival_reward_taken = false
	arrival_event = Data.find_record("events","ash_cathedral_arrival")
	arrival_event = arrival_event.duplicate(true)
	arrival_event.dialogue = arrival_event.get("dialogue_by_character",{}).get(ch.id,arrival_event.dialogue)
	var pool: Array = card_db.get(ch.id,[])
	arrival_card = pool.pick_random().duplicate(true) if not pool.is_empty() else {}
	show_arrival()

## Continues the automatically saved expedition (see run_save.gd). Returns false when there is no usable save.
func continue_saved_run() -> bool:
	var data := RunSave.read()
	if data.is_empty() or not RunSave.restore(self, data): return false
	show_map()
	return true

func show_arrival() -> void:
	clear_content()
	screen = "arrival"
	shell.hide()
	arrival_view = load("res://scripts/act_arrival.gd").new()
	arrival_view.name = "ActArrival"
	arrival_view.relic_ids = owned_relics.duplicate()
	arrival_view.setup(arrival_event,arrival_card,selected_character.name)
	arrival_view.reward_chosen.connect(take_arrival_reward)
	arrival_view.continue_requested.connect(finish_arrival)
	add_child(arrival_view)
	if arrival_reward_taken:
		arrival_view.show_result(arrival_event.farewell)

func take_arrival_reward(index: int) -> void:
	if screen != "arrival" or not arrival_pending or arrival_reward_taken:
		return
	if index < 0 or index >= arrival_event.choices.size(): return
	var choice: Dictionary = arrival_event.choices[index]
	match choice.reward:
		"gold": gold += int(choice.amount)
		"max_hp":
			max_hp += int(choice.amount)
			hp = mini(max_hp,hp + int(choice.amount))
		"card":
			if arrival_card.is_empty(): return
			deck.append(arrival_card.duplicate(true))
			Discovery.record("카드", str(deck.back().id))
		_: return
	arrival_reward_taken = true
	arrival_view.show_result(choice.reply)

func finish_arrival() -> void:
	if not arrival_pending or not arrival_reward_taken: return
	arrival_pending = false
	show_map()

func _generate_map():
	expedition.generate(int(Time.get_unix_time_from_system() * 1000000) ^ randi(), current_act)
	# shop stock is kept per node; a new map has new nodes, so the old stock (and its sold-out items) must not come back
	shop_stock.clear()
	shop_visit_node = -1
	# a relic that reveals the map (탐험가의 지도) keeps working in every ACT
	has_full_map = false
	for relic_id in owned_relics:
		if Data.find_record("relics", str(relic_id)).get("reveal_map", false): has_full_map = true

func show_map():
	if arrival_pending:
		show_arrival()
		return
	screen = "map"
	clear_content()
	title.text = "원정 지도"
	# the map is the one place between rooms: a finished last ACT ends the run, anything else is saved for "continue"
	if expedition.completed and current_act >= LAST_ACT: RunSave.autoclear()
	else: RunSave.autosave(self)
	if expedition.completed:
		if current_act >= LAST_ACT and not ending_seen and not ending_key().is_empty():
			ending_seen = true
			show_ending()
			return
		# a cleared ACT that is not the last goes straight down to the next one (no stop on a summary screen)
		if current_act < LAST_ACT:
			settle_run("clear")
			var opened: Array[String] = []
			var unlocked_counts := {"카드": 0, "유물": 0, "포션": 0}
			for entry_id in last_settlement.get("opened", []):
				var entry: Dictionary = Timeline.entry(str(entry_id))
				if entry.is_empty(): continue
				opened.append(str(entry.title))
				for unlock in entry.get("unlocks", []):
					var kind := str(unlock.get("name", "")).split(" · ")[0]
					if unlocked_counts.has(kind): unlocked_counts[kind] += 1
			begin_next_act()
			# the summary screen is skipped, so the timeline's news is a short notice on the next ACT's first page
			if not opened.is_empty():
				var shown := " · ".join(opened.slice(0, 2)) + (" 외 %d" % (opened.size() - 2) if opened.size() > 2 else "")
				var gains: Array[String] = []
				for kind in unlocked_counts:
					if int(unlocked_counts[kind]) > 0: gains.append("%s %d" % [kind, int(unlocked_counts[kind])])
				var line := "연대표 · 새 기록 · " + shown
				if not gains.is_empty(): line += "\n해금 · " + " · ".join(gains)
				show_relic_toast(line, 800.0, 632.0, 732.0)
			return
		add_text("%s · HP %d/%d · GOLD %d  |  %s" % [selected_character.name, hp, max_hp, gold, act_title()])
		if current_act >= LAST_ACT: title.text = "원정의 끝"
		settle_run("clear")
		add_heading({1: "성당의 수문장을 쓰러뜨렸습니다", 2: "돌아오지 않는 선장을 쓰러뜨렸습니다", 3: "접목된 원장을 쓰러뜨렸습니다", 4: "삭제관을 쓰러뜨렸습니다", 5: "수령 성가대를 멈췄습니다"}[current_act])
		if current_act == 1: add_button("성당 조사 지도", show_cathedral_atlas)
		if current_act < LAST_ACT:
			add_button("%s로 내려간다" % act_title(current_act + 1), begin_next_act)
			add_text("HP는 최대치의 30%만큼 회복하고 내려갑니다. 덱·유물·골드·조사 기록은 그대로 이어집니다.")
		else:
			# the ending reached gets its own heading (name), then its closing sentence
			var closing := ending_summary().split(": ", true, 1)
			if closing.size() == 2:
				add_heading(closing[0])
				add_text(closing[1])
			else:
				add_text(ending_summary())
		add_timeline_summary()
		add_button("메인 메뉴", show_menu)
		return
	title.hide()
	footer.hide()
	title.get_parent().get_child(1).hide()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(_map_header())
	if not owned_relics.is_empty(): content.add_child(RelicStrip.build(owned_relics, 1360.0, 48.0))
	var hint := Label.new()
	hint.text = "탐험가의 지도 · 현재 ACT 전체 공개" if has_full_map else "연결된 길을 선택하세요 · 앞으로 두 걸음까지 공개 · 금빛 길은 지나온 경로"
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color("9c8a7c"))
	var legend_row := HBoxContainer.new()
	legend_row.add_theme_constant_override("separation", 6)
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	legend_row.add_child(hint)
	for kind in ["전투", "엘리트", "상점", "이벤트", "휴식", "보물", "보스"]:
		legend_row.add_child(_legend_chip(kind))
	content.add_child(legend_row)
	var scroll = ScrollContainer.new()
	scroll.name = "ExpeditionScroll"
	scroll.custom_minimum_size = Vector2(0, 470)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)
	var view = MapView.new()
	view.name = "RouteMap"
	scroll.add_child(view)
	view.setup(expedition, has_full_map, [{"player_id":"local", "character_id":selected_character.id, "node_id":expedition.current_id, "display_name":selected_character.name, "color":"e5bd72", "is_local":true}])
	view.node_selected.connect(enter_node)
	var toolbar = HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 10)
	toolbar.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_child(toolbar)
	var actions = [func(): scroll.scroll_vertical = int(view.point(expedition.current_id).y - 360), show_cathedral_atlas, show_deck, show_menu]
	var labels = ["현재 위치로", "성당 지도", "덱 보기", "메인 메뉴"]
	for i in range(labels.size()):
		var button = _map_button(labels[i])
		button.pressed.connect(actions[i])
		toolbar.add_child(button)
	await get_tree().process_frame
	if is_instance_valid(scroll):
		scroll.scroll_vertical = int(view.point(expedition.current_id).y - 360)

func _box(fill: Color, border: Color, radius := 6, margin := 12) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style

func _map_button(text_value: String) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(180, 42)
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color("e6d7bd"))
	button.add_theme_stylebox_override("normal", _box(Color("17111d"), Color("5d4a3a")))
	button.add_theme_stylebox_override("hover", _box(Color("2d2239"), Color("e2bb7e")))
	button.add_theme_stylebox_override("pressed", _box(Color("2d2239"), Color("e2bb7e")))
	button.add_theme_stylebox_override("focus", _box(Color("2d2239"), Color("e2bb7e")))
	return button

func _legend_chip(kind: String) -> Control:
	var chip := PanelContainer.new()
	chip.add_theme_stylebox_override("panel", _box(Color(0.1, 0.08, 0.13, 0.9), Color("3b2f33"), 14, 8))
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(row)
	var icon := TextureRect.new()
	icon.texture = load("res://assets/map/icons/%s.png" % MapView.ICONS[kind])
	icon.custom_minimum_size = Vector2(24, 24)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	var label := Label.new()
	label.text = kind
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color("c9bba8"))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)
	return chip

## Top strip of the map screen: portrait, name, HP bar, gold and the act name in one framed bar.
func _map_header() -> Control:
	var bar := PanelContainer.new()
	bar.name = "MapHeader"
	bar.add_theme_stylebox_override("panel", _box(Color(0.075, 0.055, 0.1, 0.96), Color("4a3a2e"), 10, 16))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	bar.add_child(row)
	var profile: Dictionary = Assets.profile(str(selected_character.get("id", "")))
	var portrait_path: String = str(profile.get("map_portrait", ""))
	if not portrait_path.is_empty() and ResourceLoader.exists(portrait_path):
		var face := TextureRect.new()
		face.texture = load(portrait_path)
		face.custom_minimum_size = Vector2(60, 60)
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		face.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var round_shader := Shader.new()
		round_shader.code = "shader_type canvas_item; void fragment(){vec4 c=texture(TEXTURE,UV); c.a*=1.0-smoothstep(0.47,0.5,length(UV-vec2(0.5))); COLOR=c;}"
		var round_material := ShaderMaterial.new()
		round_material.shader = round_shader
		face.material = round_material
		row.add_child(face)
	var name_box := VBoxContainer.new()
	name_box.add_theme_constant_override("separation", 0)
	name_box.alignment = BoxContainer.ALIGNMENT_CENTER
	var name_label := Label.new()
	name_label.text = str(selected_character.get("name", ""))
	name_label.add_theme_font_size_override("font_size", 30)
	name_label.add_theme_color_override("font_color", Color("ebd8b7"))
	name_box.add_child(name_label)
	var place := Label.new()
	place.text = act_title()
	place.add_theme_font_size_override("font_size", 15)
	place.add_theme_color_override("font_color", Color("ae8f62"))
	name_box.add_child(place)
	row.add_child(name_box)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	row.add_child(_stat("topbar/icon_hp", "%d / %d" % [hp, max_hp], Color("f0707e"), float(hp) / maxf(1.0, float(max_hp))))
	row.add_child(_stat("topbar/icon_gold", str(gold), Color("f2cf72"), -1.0))
	row.add_child(_stat("topbar/icon_deck", "%d장" % deck.size(), Color("cdbfe0"), -1.0))
	return bar

func _stat(icon_path: String, value: String, tint: Color, fill: float) -> Control:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	var icon := TextureRect.new()
	icon.texture = load("res://assets/ui/%s.png" % icon_path)
	icon.custom_minimum_size = Vector2(38, 38)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	box.add_child(icon)
	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", 2)
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", tint)
	text.add_child(label)
	if fill >= 0.0:
		var track := ProgressBar.new()
		track.show_percentage = false
		track.min_value = 0.0
		track.max_value = 1.0
		track.value = fill
		track.custom_minimum_size = Vector2(150, 6)
		track.add_theme_stylebox_override("background", _box(Color("2a1a22"), Color("2a1a22"), 3, 0))
		track.add_theme_stylebox_override("fill", _box(tint, tint, 3, 0))
		text.add_child(track)
	box.add_child(text)
	return box

func show_cathedral_atlas():
	if has_node("CathedralAtlas"): return
	var atlas = load("res://scripts/cathedral_atlas.gd").new()
	atlas.name = "CathedralAtlas"
	atlas.progress = 12 if story_flags.has("ward_ledger") else int(expedition.nodes[expedition.current_id].row)
	atlas.flags = story_flags.duplicate()
	atlas.observed.connect(func(id): story_flags[id] = true)
	atlas.closed.connect(func(): atlas.queue_free())
	add_child(atlas)

func enter_node(id:int):
	if screen != "map" or not expedition.enter(id):
		return
	screen = "encounter"
	sound("map_step")
	var t = expedition.nodes[id].type
	if t == "보스" and BOSS_INTRO.has(current_act) and not story_flags.has("event_seen_" + BOSS_INTRO[current_act]):
		show_story_event(BOSS_INTRO[current_act])
	elif t in ["전투", "엘리트", "보스"]:
		start_battle(t)
	elif expedition.nodes[id].has("fixed_event"):
		show_story_event(str(expedition.nodes[id].fixed_event))
	elif t == "상점":
		show_shop()
	elif t == "휴식":
		show_rest()
	elif t == "보물":
		show_treasure()
	else:
		var first_room := _first_room_scene()
		if first_room != "": show_story_event(first_room)
		else: show_event()

## The character's own scene at the first event room of ACT I (Mira's empty ward; for the others `<id>_first_room`); "" when there is none or it was seen.
func _first_room_scene() -> String:
	if current_act != 1: return ""
	var who := str(selected_character.get("id", ""))
	if who == "mira": return "empty_ward" if not story_flags.has("ward_resolved") else ""
	var id := who + "_first_room"
	if Data.find_record("events", id).is_empty() or story_flags.has("event_seen_" + id): return ""
	return id

const ACT_NAMES := {1: "ACT I · 잿빛 성당", 2: "ACT II · 검은 운하", 3: "ACT III · 유리 온실", 4: "ACT IV · 이름 없는 서고", 5: "ACT V · 새벽 없는 성소"}
const LAST_ACT := 5
## Fixed story rooms around an act's boss: the report before the fight and the scene after the win.
const BOSS_INTRO := {2: "act2_captain_intro", 3: "act3_director_intro", 4: "act4_eraser_intro", 5: "act5_choir_intro"}
const BOSS_AFTER := {2: "act2_stamp", 3: "act3_formula_end", 4: "act4_ledger_end", 5: "act5_ending"}

## The last screen of a finished expedition: the way the party chose to deal with the device, in a sentence that also reflects earlier choices.
func ending_summary() -> String:
	if story_flags.has("ending_remaining_fire"):
		return "남겨진 불: 장치는 고쳐졌고 자원자의 이름과 한도가 모든 칸에 적혔다. 불은 마을마다 켜져 있다. 한도를 넘는 날이 오면 누군가 치료를 멈춰야 한다."
	if story_flags.has("ending_long_night"):
		return "긴 밤의 귀환: 성화가 차례로 꺼졌다. 떠날 수 있는 사람들이 먼저 길을 나섰고, 닿지 못한 마을의 이름은 장부에 남았다."
	if story_flags.has("ending_separate_lamps"):
		return "각자의 등불: 중앙 분배관은 해체되었다. 작은 그릇과 공개된 명부가 마을마다 놓였고, 누가 무엇을 맡는지 이제 누구나 읽을 수 있다."
	return "이 원정은 여기서 마칩니다."

## Which of the three endings was chosen ("" when none): the key into ENDING_SCENES.
func ending_key() -> String:
	for key in ["remaining_fire", "long_night", "separate_lamps"]:
		if story_flags.has("ending_" + key): return key
	return ""

const ENDING_SCENES := {
	"remaining_fire": {"color": "d9a37f", "lines": [
		"장치 옆 석판에 이름이 한 줄씩 새겨졌다. 마지막 칸 아래에는 숫자 하나가 따로 적혔다.",
		"마을마다 문 앞에 불이 올라왔다. 심지를 다듬는 손은 저마다 달랐다.",
		"한도가 적힌 칸은 지우지 않고 비워 두었다. 칸 아래에는 날짜를 적을 줄이 남았다."]},
	"long_night": {"color": "9fb0bd", "lines": [
		"성화가 하나씩 꺼질 때마다 복도 벽의 그림자가 한 칸씩 물러났다.",
		"떠날 수 있는 사람들이 외투 단추를 채우며 줄을 섰다. 아무도 뒤를 세지 않았다.",
		"장부 마지막 장에 닿지 못한 마을의 이름이 적혔다. 잉크는 오래 걸려 말랐다."]},
	"separate_lamps": {"color": "cdbfa4", "lines": [
		"굵은 관이 마디마다 풀려 바닥에 놓였다. 이음쇠에는 번호표가 달려 있었다.",
		"작은 그릇이 마을마다 하나씩 나뉘었다. 그릇 옆에는 누구나 펼쳐 볼 수 있는 명부가 놓였다.",
		"등불은 한꺼번에 켜지지 않았다. 갈림길마다 따로, 제각기 다른 시각에 켜졌다."]},
}

## The quiet closing scene: a few lines, then the ending's name and closing sentence on black. A click leaves it for the summary screen.
func show_ending() -> void:
	var scene: Dictionary = ENDING_SCENES[ending_key()]
	var parts := ending_summary().split(": ", true, 1)
	var lines: Array[String] = []
	for text in scene.lines: lines.append(str(text))
	screen = "ending"
	sound("ending_toll")
	# the run counts as cleared now, so closing the game during the scene still records the ending
	settle_run("clear")
	clear_content()
	shell.hide()
	arrival_view = load("res://scripts/ending_view.gd").new()
	arrival_view.name = "EndingView"
	arrival_view.setup(parts[0], parts[1] if parts.size() > 1 else "", lines, Color(str(scene.color)))
	arrival_view.finished.connect(show_map)
	add_child(arrival_view)

## A short sound effect by name (see sfx.gd); silent while the file is missing.
func sound(id: String, pitch := 1.0) -> void:
	if sfx != null: sfx.play(id, pitch)

func act_title(act := 0) -> String:
	return str(ACT_NAMES.get(current_act if act == 0 else act, ACT_NAMES[1]))

## Down to the next ACT: the party keeps everything; a fresh map and a fresh timeline log (credited from that ACT) begin.
func begin_next_act() -> void:
	if current_act >= LAST_ACT or not expedition.completed: return
	current_act += 1
	hp = mini(max_hp, hp + ceili(max_hp * 0.3))
	story_event.clear()
	last_settlement = {}
	run_log = Timeline.new_run(str(selected_character.id), current_act)
	_generate_map()
	show_story_event("act%d_arrival" % current_act)

func advance_map():
	if screen == "reward" and enemy.get("type", "") == "보스" and current_act == 1 and not story_flags.has("ward_ledger"):
		show_story_event("act1_ledger")
		return
	if screen == "reward" and enemy.get("type", "") == "보스" and BOSS_AFTER.has(current_act) and not story_flags.has("event_seen_" + BOSS_AFTER[current_act]):
		show_story_event(BOSS_AFTER[current_act])
		return
	expedition.resolve()
	show_map()

func start_battle(kind:String):
	battle_reward_claimed = false
	screen = "battle"
	player_status.entries.clear()
	enemy_status.entries.clear()
	enemy = pick_enemy(kind)
	enemy_block = 0
	enemy_was_new = not Discovery.has("몬스터", str(enemy.id))
	Discovery.record("몬스터", str(enemy.id))
	battle_turn = 1
	kill_by_dot = false
	reward_relic_lines.clear()
	reward_potion = ""
	battle_end_heal = 0
	reward_relic_options.clear()
	reward_relic_taken = ""
	relics.begin_battle()
	music.play("boss" if enemy.get("type", "") == "보스" else "battle")
	if enemy.get("type", "") == "보스": sound("boss_intro")
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
	block_penalty = 0
	if pending_effects.has("next_battle_first_turn_block_minus_3"):
		pending_effects.erase("next_battle_first_turn_block_minus_3")
		block_penalty = 3
	for relic_id in owned_relics:
		block += int(Data.find_record("relics", relic_id).get("battle_start_block", 0))
	draw_pile.shuffle()
	discard_pile.clear()
	exhaust_pile.clear()
	pain_battle = 0
	cards_played_turn = 0
	last_played = {}
	hand.clear()
	energy = 3 + relic_total("battle_start_energy")
	enemy_status.set_amount("poison", relic_total("battle_start_poison"))
	enemy_status.set_amount("sin", relic_total("battle_start_sin"))
	player_status.set_amount("rats", relic_total("battle_start_rats"))
	player_status.set_amount("embers", relic_total("battle_start_embers"))
	_draw_cards(maxi(0, 5 + relics.modify("first_draw", relic_ctx(), owned_relics)))
	enemy_status.apply(enemy.get("powers", []))
	_apply_pending_battle_effects()
	apply_relic_result(relics.fire("battle_start", relic_ctx(), owned_relics))
	_load_hints()
	var mechanic_hint := "mech_" + str(selected_character.get("id", ""))
	if not hints_seen.has("battle_basics"): hint("battle_basics")
	elif HINTS.has(mechanic_hint) and not hints_seen.has(mechanic_hint): hint(mechanic_hint)
	else: hint("intent")
	apply_relic_result(relics.take_carry("battle"))
	apply_relic_result(relics.fire("turn_start", relic_ctx(), owned_relics))
	_turn_start_powers()
	show_battle()

## Preparations made in the room before a fight, spent at its start: a weakened or exposed enemy, a stronger enemy for a price, or a head start in block.
func _apply_pending_battle_effects() -> void:
	if pending_effects.has("next_battle_enemy_weak_2"):
		pending_effects.erase("next_battle_enemy_weak_2")
		enemy_status.set_amount("weak", 2)
	if pending_effects.has("next_battle_enemy_vulnerable_2"):
		pending_effects.erase("next_battle_enemy_vulnerable_2")
		enemy_status.set_amount("vulnerable", 2)
	if pending_effects.has("next_battle_enemy_strength_2"):
		pending_effects.erase("next_battle_enemy_strength_2")
		enemy_status.set_amount("strength", enemy_status.amount("strength") + 2)
	if pending_effects.has("next_battle_start_block_12"):
		pending_effects.erase("next_battle_start_block_12")
		block += 12

## A random monster of the right rank for this act, never the same one twice in a row when there is a choice.
func pick_enemy(kind: String) -> Dictionary:
	var rank: String = {"전투": "일반", "엘리트": "엘리트", "보스": "보스"}.get(kind, "일반")
	var all: Array = Data.read("monsters")
	var pool: Array = all.filter(func(m): return str(m.get("type", "")) == rank and int(m.get("act", 1)) == current_act)
	if pool.is_empty(): pool = all.filter(func(m): return str(m.get("type", "")) == rank)
	var fresh: Array = pool.filter(func(m): return str(m.id) != last_enemy_id)
	var choice: Dictionary = (fresh if not fresh.is_empty() else pool).pick_random()
	last_enemy_id = str(choice.id)
	return choice

## The move the enemy will make this turn: a scripted opener first, then its pattern; a phase whose HP line has been crossed replaces the pattern.
func enemy_action() -> Dictionary:
	return MonsterActions.pick(enemy, enemy_turn, enemy_hp, enemy_max_hp)

## One hit of an enemy move before block: its damage + strength + any stored bonus, half again as much while the player is vulnerable.
func enemy_hit_value(action: Dictionary, extra := 0) -> int:
	if int(action.get("damage", 0)) <= 0: return 0
	var value := int(action.damage) + enemy_status.amount("strength") + extra
	if enemy_status.amount("weak") > 0: value = floori(value * 0.75)
	if player_status.amount("vulnerable") > 0: value = int(value * 1.5)
	return maxi(0, value)

## Starts an enemy move: its own block, healing and buffs happen now; returns the number of hits and the damage of each.
func enemy_prepare(action: Dictionary) -> Dictionary:
	enemy_block = 0
	var notes: Array[String] = []
	if int(action.get("block", 0)) > 0:
		enemy_block = int(action.block)
		notes.append("방어 +%d" % enemy_block)
	if int(action.get("heal", 0)) > 0:
		var healed := mini(enemy_max_hp - enemy_hp, int(action.heal))
		enemy_hp += healed
		if healed > 0: notes.append("회복 +%d" % healed)
	if int(action.get("cleanse", 0)) > 0 and enemy_status.amount("poison") > 0:
		var cleansed := mini(enemy_status.amount("poison"), int(action.cleanse))
		enemy_status.set_amount("poison", enemy_status.amount("poison") - cleansed)
		notes.append("중독 -%d" % cleansed)
	# a share of the poison, for the late fights where a stack in the dozens would otherwise end them in a few turns
	if int(action.get("cleanse_pct", 0)) > 0 and enemy_status.amount("poison") > 0:
		var washed := ceili(enemy_status.amount("poison") * int(action.cleanse_pct) / 100.0)
		enemy_status.set_amount("poison", enemy_status.amount("poison") - washed)
		notes.append("중독 -%d" % washed)
	for item in action.get("buff", []):
		enemy_status.apply([item])
		notes.append(MonsterActions.status_text(item))
	for i in int(action.get("side_effect", 0)): discard_pile.append(SIDE_EFFECT_CARD.duplicate(true))
	if int(action.get("side_effect", 0)) > 0: notes.append("부작용 카드 +%d" % int(action.side_effect))
	var hits := 0
	var per_hit := 0
	if int(action.get("damage", 0)) > 0:
		hits = maxi(1, int(action.get("hits", 1)))
		per_hit = enemy_hit_value(action, enemy_status.consume_attack() + relics.modify("incoming_damage", relic_ctx(), owned_relics))
	return {"hits": hits, "per_hit": per_hit, "notes": notes}

## One hit lands on the player: block soaks it first. Returns the HP really lost.
func enemy_hit_player(per_hit: int) -> int:
	var struck := per_hit > 0  # counter answers an attack even when a rat or block takes all of it
	# a rat throws itself in the way: the hit shrinks by RAT_GUARD and one rat is lost
	if per_hit > 0 and player_status.amount("rats") > 0:
		per_hit = maxi(0, per_hit - RAT_GUARD)
		player_status.set_amount("rats", player_status.amount("rats") - 1)
		block += player_status.amount("rat_burrow")
	var soaked := mini(block, per_hit)
	block -= soaked
	var rest := per_hit - soaked
	var shield := mini(player_status.amount("barrier"), rest)
	if shield > 0:
		player_status.set_amount("barrier", player_status.amount("barrier") - shield)
		rest -= shield
	if struck and player_status.amount("counter") > 0:
		enemy_hp = maxi(0, enemy_hp - player_status.amount("counter"))
	return lose_hp(rest)

## After the hits: vulnerability that was there for them runs down, then the move's own debuffs are applied.
func enemy_finish(action: Dictionary) -> Array[String]:
	player_status.set_amount("counter", 0)
	player_status.decay("vulnerable")
	enemy_status.decay("weak")
	enemy_status.decay("vulnerable")
	var notes: Array[String] = []
	for item in action.get("apply_statuses", []):
		item = item.duplicate(true)
		# relics may cancel, shrink or send back a debuff (빛가림 천, 밀랍 귀퉁이, 분리된 수문추 ...)
		var debuff_ctx := relic_ctx()
		debuff_ctx["debuff"] = str(item.get("id", ""))
		var relic_effect := relics.fire("debuff_received", debuff_ctx, owned_relics)
		var skipped := int(relic_effect.get("negate", 0)) > 0
		if int(relic_effect.get("reduce", 0)) > 0: item["amount"] = int(item.get("amount", 0)) - int(relic_effect.reduce)
		if int(relic_effect.get("reflect", 0)) > 0: enemy_status.apply([item.duplicate(true)])
		if int(relic_effect.get("draw", 0)) > 0: _draw_cards(int(relic_effect.draw))
		if skipped or int(item.get("amount", 0)) <= 0: continue
		player_status.apply([item])
		notes.append(MonsterActions.status_text(item))
	if not notes.is_empty(): sound("debuff_apply")
	return notes

func _draw_cards(n:int):
	var before := hand.size()
	var drew_status := false
	for i in range(n):
		if hand.size() >= 10:
			break
		if draw_pile.is_empty():
			draw_pile = discard_pile.duplicate(true)
			discard_pile.clear()
			draw_pile.shuffle()
			if not draw_pile.is_empty(): sound("shuffle")
		if draw_pile.is_empty():
			break
		var drawn: Dictionary = draw_pile.pop_back()
		hand.append(drawn)
		if str(drawn.get("type", "")) == "상태" and screen == "battle": drew_status = true
	if hand.size() > before and screen == "battle": sound("card_draw")
	if drew_status: apply_relic_result(relics.fire("status_card_drawn", relic_ctx(), owned_relics))

## Every playable character uses the full battle scene (effects, hand, status panels).
func _rich_battle() -> bool:
	return true

func show_battle():
	clear_content()
	FrameTint.hero = str(selected_character.get("id", ""))
	if _rich_battle():
		shell.hide()
		battle_canvas = preload("res://scripts/battle_scene.gd").new()
		add_child(battle_canvas)
		content = battle_canvas
		battle_canvas.setup(self)
		_refresh_battle_tooltips()
		return
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
	add_text("%s · 다음 행동: %s" % [enemy.name, enemy_action().name]).name = "Intent"
	add_text("적 HP: %d / %d   ·   독 %d중첩 · 맹독 %d턴" % [enemy_hp, enemy_max_hp, enemy_status.amount("poison"), venom_turns]).name = "EnemySummary"
	if selected_character.id == "mira":
		content.add_theme_constant_override("separation", 6)
		title.hide()
		footer.hide()
		title.get_parent().get_child(1).hide()
		content.get_node("EnemySummary").hide()
		content.size_flags_vertical = Control.SIZE_EXPAND_FILL
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
		var belt = PotionBelt.new()
		content.add_child(belt)
		belt.setup(potions, POTION_SLOTS, not battle_busy)
		belt.custom_minimum_size = belt.size
		belt.used.connect(use_potion)
		add_button("턴 종료", end_turn).disabled = battle_busy
		add_button("덱 보기", show_deck).disabled = battle_busy

	_refresh_battle_tooltips()

func _refresh_battle_hp() -> void:
	_refresh_battle_tooltips()
	content.get_node("PlayerSummary").text = "%s  HP %d/%d   방어 %d   에너지 %d/3" % [selected_character.name, hp, max_hp, block, energy]
	var top_hp = content.get_node_or_null("TopBarHp")
	if top_hp: top_hp.text = "%d/%d" % [hp, max_hp]
	content.get_node("EnemySummary").text = "적 HP: %d / %d   ·   독 %d중첩 · 맹독 %d턴" % [enemy_hp, enemy_max_hp, enemy_status.amount("poison"), venom_turns]
	for pair in [["Player", hp, block], ["Enemy", enemy_hp, enemy_block]]:
		var panel = content.get_node_or_null("UnitStatuses/" + pair[0])
		if panel:
			panel.set_hp(pair[1])
			panel.set_block(pair[2])

func _refresh_battle_tooltips() -> void:
	for state in [player_status, enemy_status]:
		for id in state.entries: Discovery.record("파워", str(id))
	var hero = content.get_node_or_null("BattleStage/Hero")
	if hero:
		hero.tooltip_text = "%s · %s\nHP %d/%d · 방어 %d\n%s\n\n%s" % [selected_character.name, selected_character.get("class", ""), hp, max_hp, block, selected_character.get("theme", ""), StatusPanel.describe_all(player_status, max_hp)]
	var target = content.get_node_or_null("BattleStage/Enemy")
	var intent = content.get_node_or_null("Intent")
	var action: Dictionary = enemy_action()
	var text := "%s\n%s" % [action.name, MonsterActions.text(action, enemy_status.amount("strength") + enemy_status.amount("empower"))]
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

## The damage a card would deal to the enemy right now (before enemy block): strength-like bonuses,
## relics, weak on the player and vulnerable on the enemy included. Spends nothing.
func preview_damage(c: Dictionary) -> int:
	c = _with_bonus(c)  # a card with a bonus condition shows the damage it will really do
	var damage := int(c.get("damage", 0))
	if damage <= 0 and not _scales_with_counters(c): return 0
	if int(c.get("per_potion_damage", 0)) > 0: damage += int(c.per_potion_damage) * potions.size()
	if int(c.get("per_energy_damage", 0)) > 0: damage += int(c.per_energy_damage) * energy
	if int(c.get("pain_damage", 0)) > 0: damage += int(c.pain_damage) * pain_battle
	damage += _counter_damage(c)
	if damage <= 0: return 0
	if c.type == "공격":
		damage += player_status.peek_attack()
		damage += int(relics.preview("attack_damage", relic_ctx(c), owned_relics).add) + int(relics.battle.first_attack_bonus)
		if owned_relics.has("blood_contract"):
			damage = ceili(damage * Data.find_record("relics", "blood_contract").damage_multiplier)
		if player_status.amount("weak") > 0: damage = maxi(1, floori(damage * 0.75))
	if enemy_status.amount("vulnerable") > 0: damage = floori(damage * 1.5)
	return damage

## Damage a card adds per sin on the enemy, per rat or per ember (Severin, Calamo, Esca).
func _counter_damage(c: Dictionary) -> int:
	return int(c.get("sin_damage", 0)) * enemy_status.amount("sin") + int(c.get("rat_damage", 0)) * player_status.amount("rats") + int(c.get("ember_damage", 0)) * player_status.amount("embers")

func _scales_with_counters(c: Dictionary) -> bool:
	return int(c.get("sin_damage", 0)) > 0 or int(c.get("rat_damage", 0)) > 0 or int(c.get("ember_damage", 0)) > 0

## Stacks that a card adds, multiplies or spends once its damage is done: sin on the enemy, rats and embers on the player.
func _counter_stacks(c: Dictionary) -> void:
	var attack := str(c.type) == "공격"
	var sin_gain := int(c.get("sin", 0)) + (player_status.amount("sin_ledger") if attack else 0)
	var ember_gain := int(c.get("embers", 0)) + (player_status.amount("coal_bed") if attack else 0)
	if c.get("sin_spend", false): enemy_status.set_amount("sin", 0)
	if sin_gain > 0: enemy_status.set_amount("sin", enemy_status.amount("sin") + sin_gain)
	if int(c.get("sin_mult", 0)) > 1: enemy_status.set_amount("sin", enemy_status.amount("sin") * int(c.sin_mult))
	if c.get("rats_spend", false): player_status.set_amount("rats", 0)
	if int(c.get("rats", 0)) > 0: player_status.set_amount("rats", player_status.amount("rats") + int(c.rats))
	if int(c.get("rats_mult", 0)) > 1: player_status.set_amount("rats", player_status.amount("rats") * int(c.rats_mult))
	if c.get("embers_spend", false): player_status.set_amount("embers", 0)
	if ember_gain > 0: player_status.set_amount("embers", player_status.amount("embers") + ember_gain)
	if int(c.get("embers_mult", 0)) > 1: player_status.set_amount("embers", player_status.amount("embers") * int(c.embers_mult))

func _card_effect(c: Dictionary) -> int:
	var original := c
	c = _with_bonus(c)
	var ctx := relic_ctx(c)
	# stacks as they stand when the card is played (a verdict reads them before spending them)
	var counter_block := int(c.get("sin_block", 0)) * enemy_status.amount("sin") + int(c.get("rat_block", 0)) * player_status.amount("rats") + int(c.get("ember_block", 0)) * player_status.amount("embers")
	if int(c.get("hp_cost", 0)) > 0:
		var price := maxi(1, int(c.hp_cost) + relics.modify("card_hp_cost_less", ctx, owned_relics))
		lose_hp(mini(price, maxi(0, hp - 1)))
		apply_relic_result(relics.fire("card_hp_cost", ctx, owned_relics))
	if c.has("venom_turns"):
		venom_turns = int(c.venom_turns) + relics.modify("venom_turns", ctx, owned_relics)
		venom_rate = float(c.venom_rate)
		apply_relic_result(relics.fire("venom_applied", ctx, owned_relics))
	var damage := int(c.get("damage", 0))
	if int(c.get("per_potion_damage", 0)) > 0: damage += int(c.per_potion_damage) * potions.size()
	if int(c.get("per_energy_damage", 0)) > 0: damage += int(c.per_energy_damage) * int(c.get("x_energy", 0))
	if int(c.get("pain_damage", 0)) > 0: damage += int(c.pain_damage) * pain_battle
	damage += _counter_damage(c)
	if c.type == "공격":
		damage += player_status.consume_attack()
		damage += relics.modify("attack_damage", ctx, owned_relics) + relics.take_first_attack_bonus()
		if owned_relics.has("blood_contract"):
			damage = ceili(damage * Data.find_record("relics", "blood_contract").damage_multiplier)
		if player_status.amount("weak") > 0 and damage > 0: damage = maxi(1, floori(damage * 0.75))
	if enemy_status.amount("vulnerable") > 0 and damage > 0: damage = floori(damage * 1.5)
	var soaked := mini(enemy_block, damage)
	enemy_block -= soaked
	damage -= soaked
	enemy_hp = maxi(0, enemy_hp - damage)
	_counter_stacks(c)
	bleed += int(c.get("bleed", 0))
	var poison_amount := int(c.get("poison", 0)) + int(c.get("per_energy_poison", 0)) * int(c.get("x_energy", 0))
	if poison_amount > 0:
		poison_amount += relics.modify("card_poison", ctx, owned_relics)
		poison_amount *= relics.multiplier("card_poison_mult", ctx, owned_relics)
	if c.type == "스킬": poison_amount += player_status.amount("toxic_vapor")
	if c.type == "공격": poison_amount += player_status.amount("toxic_oath")
	if int(c.get("poison", 0)) > 0 and enemy_status.amount("vulnerable") > 0: poison_amount += player_status.amount("fever_record")
	enemy_status.set_amount("poison", enemy_status.amount("poison") + poison_amount)
	if int(c.get("poison_mult", 0)) > 1: enemy_status.set_amount("poison", enemy_status.amount("poison") * int(c.poison_mult))
	var burst := 0
	if c.get("poison_burst", false):
		burst = enemy_status.amount("poison")
		enemy_hp = maxi(0, enemy_hp - burst)
	if int(c.get("venom_extend", 0)) > 0:
		if venom_turns <= 0:
			enemy_status.set_amount("venom", int(c.venom_extend))
			venom_rate = 0.08
		else:
			venom_turns += int(c.venom_extend)
	var enemy_debuffs: Array = []
	if int(c.get("weak", 0)) > 0: enemy_debuffs.append({"id": "weak", "amount": int(c.weak)})
	if int(c.get("vulnerable", 0)) > 0: enemy_debuffs.append({"id": "vulnerable", "amount": int(c.vulnerable)})
	enemy_status.apply(enemy_debuffs)
	next_attack += int(c.get("next_attack", 0))
	var gained_block := int(c.get("block", 0)) + counter_block
	if gained_block > 0: gained_block += relics.modify("card_block", ctx, owned_relics)
	if gained_block > 0 and block_penalty > 0:
		var lost := mini(block_penalty, gained_block)
		gained_block -= lost
		block_penalty -= lost
	block += gained_block
	var heal_amount := int(c.get("heal", 0))
	if heal_amount > 0: heal_amount += relics.modify("card_heal", ctx, owned_relics)
	hp = mini(max_hp, hp + _scaled_heal(heal_amount))
	energy += int(c.get("energy", 0))
	if c.get("brew", false): brew_potion()
	if c.get("drink_potion", false): _drink_first_potion()
	if c.has("power"): player_status.apply([c.power])
	if int(c.get("counter", 0)) > 0: player_status.apply([{"id": "counter", "amount": int(c.counter)}])
	if int(c.get("barrier", 0)) > 0: player_status.apply([{"id": "barrier", "amount": int(c.barrier)}])
	if c.get("drink_all", false):
		while not potions.is_empty(): _drink_first_potion()
	for i in int(c.get("side_effect", 0)): discard_pile.append(SIDE_EFFECT_CARD.duplicate(true))
	if c.has("conjure"): _conjure(c.conjure)
	if int(c.get("transmute", 0)) > 0: _transmute(int(c.transmute))
	if c.get("echo", false) and not last_played.is_empty(): _echo()
	if c.get("purge", false): _purge_side_effects()
	if not original.get("echo", false): last_played = original
	var previous_type := str(relics.turn.types.back()) if not relics.turn.types.is_empty() else ""
	if (previous_type == "공격" and c.type == "스킬") or (previous_type == "스킬" and c.type == "공격"):
		apply_relic_result(relics.fire("card_alternate", ctx, owned_relics))
	cards_played_turn += 1
	if cards_played_turn == 3 and player_status.amount("prescription_pad") > 0: _draw_cards(player_status.amount("prescription_pad"))
	relics.note_card(c, gained_block)
	var played_result := relics.fire("card_played", relic_ctx(c), owned_relics)
	if int(played_result.get("repeat_block", 0)) > 0 and int(c.get("block", 0)) > 0: block += int(c.block)
	apply_relic_result(played_result)
	if int(c.get("draw", 0)) > 0: _draw_cards(int(c.draw))
	_refresh_battle_hp()
	return damage + burst

## A card whose `bonus` condition holds gets the bonus fields added (e.g. extra damage against a poisoned enemy).
func _with_bonus(c: Dictionary) -> Dictionary:
	var bonus: Dictionary = c.get("bonus", {})
	if bonus.is_empty() or not _bonus_holds(str(bonus.get("cond", "")), int(bonus.get("value", 1))): return c
	var merged := c.duplicate(true)
	for key in bonus.get("add", {}):
		merged[key] = merged.get(key, 0) + bonus.add[key]
	return merged

func _bonus_holds(cond: String, value: int) -> bool:
	match cond:
		"enemy_poison": return enemy_status.amount("poison") >= value
		"enemy_venom": return venom_turns >= value
		"enemy_vulnerable": return enemy_status.amount("vulnerable") >= value
		"enemy_weak": return enemy_status.amount("weak") >= value
		"played_before": return cards_played_turn >= value
		"hand_empty": return hand.is_empty()
		"hp_below_pct": return hp * 100 <= max_hp * value
		"potions_min": return potions.size() >= value
		"enemy_sin": return enemy_status.amount("sin") >= value
		"rats_min": return player_status.amount("rats") >= value
		"embers_min": return player_status.amount("embers") >= value
	return false

func _pool_cards(type := "") -> Array:
	return card_db.get(selected_character.id, []).filter(func(c): return (type == "" or str(c.type) == type) and str(c.type) != "파워")

## New cards made during a fight are free and are exhausted after use: {"type": "스킬", "n": 1}.
func _conjure(spec: Dictionary) -> void:
	var pool := _pool_cards(str(spec.get("type", "")))
	for i in int(spec.get("n", 1)):
		if pool.is_empty() or hand.size() >= 10: return
		var card: Dictionary = pool.pick_random().duplicate(true)
		card["cost"] = 0
		card["exhaust"] = true
		hand.append(card)

## Turns `n` random cards of the hand into other random cards of the character.
func _transmute(n: int) -> void:
	var pool := _pool_cards()
	for i in n:
		if hand.is_empty() or pool.is_empty(): return
		var index := randi_range(0, hand.size() - 1)
		var old_id := str(hand[index].id)
		var options := pool.filter(func(c): return str(c.id) != old_id)
		if options.is_empty(): return
		hand[index] = options.pick_random().duplicate(true)

## A free, exhausting copy of the last card played this battle goes to the hand.
func _echo() -> void:
	if hand.size() >= 10: return
	var copy: Dictionary = last_played.duplicate(true)
	copy["cost"] = 0
	copy["exhaust"] = true
	copy.erase("echo")
	hand.append(copy)

## Every side-effect card in the hand is exhausted for 1 energy each.
func _purge_side_effects() -> void:
	var kept: Array = []
	for card in hand:
		if str(card.get("id", "")) == "side_effect":
			exhaust_pile.append(card)
			energy += 1
		else:
			kept.append(card)
	hand = kept

## A random potion id the run may find (drops and brewing); empty when none is available.
func _random_potion_id() -> String:
	var pool: Array = Data.read("potions").filter(func(p): return Timeline.available(p))
	return "" if pool.is_empty() else str(pool.pick_random().id)

## Puts a new potion on the belt (a given id or a random one); nothing when the belt is full.
func brew_potion(id := "") -> String:
	if potions.size() >= POTION_SLOTS: return ""
	var picked := id if id != "" else _random_potion_id()
	if picked == "" or Data.find_record("potions", picked).is_empty(): return ""
	potions.append(picked)
	Discovery.record("포션", picked)
	return picked

## The first potion on the belt is drunk without choosing a slot (card effect).
func _drink_first_potion() -> void:
	if potions.is_empty(): return
	var potion: Dictionary = Data.find_record("potions", str(potions[0]))
	potions.remove_at(0)
	if not potion.is_empty(): _apply_potion(potion)

## Standing effects at the start of each of the player's turns: steeping adds venom turns, a brewing bench makes a potion.
func _turn_start_powers() -> void:
	var steep := player_status.amount("slow_steep")
	if steep > 0:
		if venom_turns <= 0:
			enemy_status.set_amount("venom", steep)
			venom_rate = 0.08
		else:
			venom_turns += steep
	# Severin, Calamo and Esca: standing effects that feed their counters, and the hearth's warmth
	if player_status.amount("inquest") > 0: enemy_status.set_amount("sin", enemy_status.amount("sin") + player_status.amount("inquest"))
	if player_status.amount("piper_march") > 0: player_status.set_amount("rats", player_status.amount("rats") + player_status.amount("piper_march"))
	if player_status.amount("hearth_keeper") > 0: player_status.set_amount("embers", player_status.amount("embers") + player_status.amount("hearth_keeper"))
	block += floori(player_status.amount("embers") / float(EMBER_WARMTH_STEP))
	if player_status.amount("brewing_bench") > 0: brew_potion()
	if player_status.amount("long_simmer") > 0: enemy_status.set_amount("poison", enemy_status.amount("poison") + player_status.amount("long_simmer"))
	if player_status.amount("distilled_breath") > 0: block += player_status.amount("distilled_breath")
	if player_status.amount("ether_cycle") > 0:
		energy += player_status.amount("ether_cycle")
		discard_pile.append(SIDE_EFFECT_CARD.duplicate(true))

## Powers that act as a turn ends, before the enemy's move.
## Every rat bites the enemy once as the turn ends. It happens after the enemy's move was chosen (like a poison tick), so the move the player was shown is the move that is made. Returns the damage.
func _rat_bite() -> int:
	var bites := player_status.amount("rats")
	if bites <= 0 or enemy_hp <= 0: return 0
	var dealt := mini(bites, enemy_hp)
	enemy_hp -= dealt
	return dealt

func _turn_end_powers() -> void:
	var festering := player_status.amount("festering")
	if festering > 0 and enemy_status.amount("poison") >= 5:
		enemy_status.set_amount("poison", enemy_status.amount("poison") + festering)
	var script := player_status.amount("bitter_script")
	if script > 0:
		var bad := 0
		for c in hand:
			if str(c.get("id", "")) == "side_effect": bad += 1
		if bad > 0: enemy_hp = maxi(0, enemy_hp - script * bad)

## `count` cards were exhausted (by a card with 소모, or by 휘발 at the end of a turn).
func _on_exhaust(count: int) -> void:
	var gain := player_status.amount("ash_ledger") * count
	if gain > 0: block += gain

func play_card(index:int):
	if battle_busy or screen != "battle" or index < 0 or index >= hand.size():
		return
	var c: Dictionary = hand[index]
	if int(c.cost) > energy: return
	if int(c.get("hp_cost", 0)) >= hp: return
	if c.get("unplayable", false): return
	if c.get("x", false):
		c = c.duplicate(true)
		c["x_energy"] = energy
		energy = 0
	battle_busy = true
	battle_motion = "attack" if c.type == "공격" else "skill"
	sound("card_attack" if c.type == "공격" else ("card_power" if str(c.type) == "파워" else "card_skill"), randf_range(0.97, 1.03))
	energy -= int(c.cost)
	if c.get("exhaust", false) or str(c.type) == "파워": exhaust_pile.append(c)
	else: discard_pile.append(c)
	if c.get("exhaust", false): _on_exhaust(1)
	hand.remove_at(index)
	show_battle()
	if _rich_battle():
		await get_tree().process_frame
		var hero = content.get_node("BattleStage/Hero")
		var target = content.get_node("BattleStage/Enemy")
		var fx = _begin_fx()
		var offensive: bool = c.get("damage", 0) > 0 or c.get("poison", 0) > 0 or c.get("venom_turns", 0) > 0 or c.get("bleed", 0) > 0 or c.get("sin", 0) > 0 or _scales_with_counters(c)
		var color := _card_color(c)
		var apply := func():
			var damage := _card_effect(c)
			if damage > 0: sound("hit_enemy", randf_range(0.95, 1.05))
			elif c.get("poison", 0) > 0 or c.get("venom_turns", 0) > 0: sound("poison")
			if c.get("block", 0) > 0: sound("block_gain")
			if c.get("heal", 0) > 0: sound("heal")
			if offensive:
				fx.impact(target, color, _impact_label(c, damage), damage > 0)
			if c.get("block", 0) > 0: fx.float_text(hero, "방어 +%d" % c.block, Color("79cce7"))
			if c.get("heal", 0) > 0: fx.float_text(hero, "회복 +%d" % c.heal, Color("8cedb0"))
		if offensive:
			await fx.strike(hero, target, c.type != "공격", color, apply)
		else:
			await fx.pulse(hero, Color("79cce7"), apply)
		if enemy_hp <= 0:
			sound("enemy_death")
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

## Colour of a card's strike effect: poison green, sin crimson, ember orange, rat olive, Mira's violet otherwise.
func _card_color(c: Dictionary) -> Color:
	if c.has("poison"): return Color("70e85a")
	if int(c.get("sin", 0)) > 0 or int(c.get("sin_damage", 0)) > 0: return Color("d8483f")
	if int(c.get("ember_damage", 0)) > 0 or int(c.get("embers", 0)) > 0: return Color("ff9a3c")
	if int(c.get("rat_damage", 0)) > 0 or int(c.get("rats", 0)) > 0: return Color("b3bf6c")
	return Color("bd74ff")

## The floating text over the enemy when a card lands: the damage, "막힘" when block took it all, or the stack it added.
func _impact_label(c: Dictionary, damage: int) -> String:
	if damage > 0: return str(-damage)
	if int(c.get("damage", 0)) > 0 or _scales_with_counters(c): return "막힘"
	if int(c.get("sin", 0)) > 0: return "죄목 +%d" % int(c.sin)
	if c.has("poison"): return "독 +%d" % int(c.poison)
	return "맹독 %d턴" % int(c.get("venom_turns", 0))

func _dot_phase(statuses, maximum: int, actor: Control, player: bool, fx) -> void:
	# Compute each tick once; display separate receipts for poison and venom.
	var receipts: Array = statuses.tick_details(maximum)
	for receipt in receipts:
		if player: lose_hp(int(receipt.damage))
		else: enemy_hp = maxi(0, enemy_hp - receipt.damage)
		_refresh_battle_hp()
		var color := Color("73e956") if receipt.id == "poison" else Color("c47bff")
		fx.impact(actor, color, "%s -%d" % [Data.find_record("powers", receipt.id).name, receipt.damage], false)
		await get_tree().create_timer(0.45).timeout

func end_turn():
	if battle_busy or screen != "battle": return
	battle_busy = true
	sound("turn_end")
	player_status.decay("weak")
	apply_relic_result(relics.fire("turn_end", relic_ctx(), owned_relics))
	_turn_end_powers()
	if _rich_battle():
		show_battle()
		await get_tree().process_frame
		var hero = content.get_node("BattleStage/Hero")
		var target = content.get_node("BattleStage/Enemy")
		var fx = _begin_fx()
		# the move is chosen before the poison ticks, so the move the player was shown is the move that is made (a tick that crosses a phase line changes the next one)
		var planned: Dictionary = enemy_action()
		var bitten := _rat_bite()
		var killed_by_rats := enemy_hp <= 0
		if bitten > 0:
			_refresh_battle_hp()
			fx.impact(target, Color("b3bf6c"), "쥐 -%d" % bitten, false)
			await get_tree().create_timer(0.45).timeout
		await _dot_phase(enemy_status, enemy_max_hp, target, false, fx)
		if enemy_hp <= 0 and not killed_by_rats: kill_by_dot = true
		if enemy_hp > 0:
			var action: Dictionary = planned
			var plan := enemy_prepare(action)
			_refresh_battle_hp()
			if not plan.notes.is_empty():
				fx.impact(target, Color("d3b4ff"), " · ".join(plan.notes), false)
				await get_tree().create_timer(0.55).timeout
			elif plan.hits == 0 and action.get("apply_statuses", []).is_empty():
				fx.float_text(target, "…", Color("a89cb0"))
				await get_tree().create_timer(0.5).timeout
			for i in plan.hits:
				if hp <= 0: break
				await fx.strike(target, hero, false, Color("f4b58d"), func():
					var damage := enemy_hit_player(int(plan.per_hit))
					if damage > 0: hero.play("death" if hp <= 0 else "hurt")
					fx.impact(hero, Color("f4b58d"), str(-damage) if damage > 0 else "방어", damage > 0)
					_refresh_battle_hp()
				)
			var debuffs := enemy_finish(action)
			if not debuffs.is_empty():
				fx.impact(hero, Color("c9a3ff"), " · ".join(debuffs), false)
				await get_tree().create_timer(0.5).timeout
			enemy_turn += 1
			await _dot_phase(player_status, max_hp, hero, true, fx)
		if enemy_hp <= 0:
			sound("enemy_death")
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
		var planned: Dictionary = enemy_action()
		_rat_bite()
		var killed_by_rats := enemy_hp <= 0
		enemy_hp = maxi(0, enemy_hp - enemy_status.tick(enemy_max_hp))
		if enemy_hp <= 0 and not killed_by_rats: kill_by_dot = true
		if enemy_hp > 0:
			var action: Dictionary = planned
			var plan := enemy_prepare(action)
			var damage := 0
			for i in plan.hits:
				if hp > 0: damage += enemy_hit_player(int(plan.per_hit))
			enemy_finish(action)
			enemy_turn += 1
			damage += lose_hp(player_status.tick(max_hp))
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
	var kept: Array = []
	var faded := 0
	# 서고 책갈피: at the end of the first turn the costliest card in hand is kept (the one that is hardest to play again)
	var bookmark := int(relics.fire("turn_end_retain", relic_ctx(), owned_relics).get("retain", 0))
	var bookmarked: Dictionary = {}
	if bookmark > 0:
		for c in hand:
			if c.get("ethereal", false) or c.get("unplayable", false) or c.get("retain", false): continue
			if bookmarked.is_empty() or int(c.get("cost", 0)) > int(bookmarked.get("cost", 0)): bookmarked = c
	for c in hand:
		if c.get("retain", false) or (not bookmarked.is_empty() and is_same(c, bookmarked)): kept.append(c)
		elif c.get("ethereal", false):
			exhaust_pile.append(c)
			faded += 1
		else: discard_pile.append(c)
	hand = kept
	cards_played_turn = 0
	block = 0
	_on_exhaust(faded)
	energy = 3
	_draw_cards(5)
	battle_turn += 1
	relics.begin_turn()
	apply_relic_result(relics.take_carry("turn"))
	apply_relic_result(relics.fire("turn_start", relic_ctx(), owned_relics))
	_turn_start_powers()
	show_battle()

## Chance of each rarity for one offered card, by the kind of fight. The odds are per rarity (not per card), so a rarity with few cards
## is still offered as often as it says. A reward with no 희귀-or-better card raises the next one's chance (the "pity" counter).
const REWARD_ODDS := {
	"전투": {"일반": 58, "고급": 34, "희귀": 7, "영웅": 1},
	"엘리트": {"일반": 42, "고급": 40, "희귀": 16, "영웅": 2},
	"보스": {"일반": 0, "고급": 0, "희귀": 85, "영웅": 15},
}
const PITY_STEP := 2
const PITY_CAP := 30
var reward_pity := 0

## The character's cards on offer after a fight: random, no card twice, rarer cards from elites, a boss always offers rare cards.
func roll_reward_cards(kind := "전투") -> Array:
	var pool: Array = card_db.get(selected_character.id, []).filter(func(c): return Timeline.available(c))
	var count := mini(3 + relics.modify("reward_choices", {}, owned_relics), pool.size())
	var odds: Dictionary = REWARD_ODDS.get(kind, REWARD_ODDS["전투"])
	var picked: Array = []
	var saw_rare := false
	while picked.size() < count and not pool.is_empty():
		# the pity counter moves 일반 odds to 희귀 (not for bosses, which already offer rare cards)
		var weights := odds.duplicate()
		if kind != "보스":
			var shift := mini(reward_pity, int(weights["일반"]))
			weights["일반"] -= shift
			weights["희귀"] += shift
		var total := 0
		for rarity in weights:
			if pool.any(func(c): return str(c.get("rarity", "일반")) == rarity): total += int(weights[rarity])
		var chosen := ""
		if total > 0:
			var roll := randi_range(1, total)
			for rarity in weights:
				if not pool.any(func(c): return str(c.get("rarity", "일반")) == rarity): continue
				roll -= int(weights[rarity])
				if roll <= 0:
					chosen = rarity
					break
		var candidates: Array = pool.filter(func(c): return chosen.is_empty() or str(c.get("rarity", "일반")) == chosen)
		if candidates.is_empty(): candidates = pool
		var card: Dictionary = candidates[randi_range(0, candidates.size() - 1)]
		if str(card.get("rarity", "")) in ["희귀", "영웅"]: saw_rare = true
		picked.append(card.duplicate(true))
		pool.erase(card)
	reward_pity = 0 if saw_rare else mini(PITY_CAP, reward_pity + PITY_STEP)
	return picked

## A victory may leave a potion: 30% after a fight, 60% after an elite, none from a boss. Nothing if the belt is full.
func _roll_potion_drop() -> String:
	var chance: float = {"일반": 0.30, "엘리트": 0.60}.get(str(enemy.get("type", "")), 0.0)
	if potions.size() >= POTION_SLOTS or randf() >= chance: return ""
	return brew_potion()

## Drink the potion in belt slot `index` during the player's turn. Effects (any may be absent): heal, block,
## energy, draw, damage (soaked by enemy block), poison (on the enemy), player_statuses / enemy_statuses.
func use_potion(index: int) -> void:
	if battle_busy or screen != "battle" or index < 0 or index >= potions.size(): return
	var potion: Dictionary = Data.find_record("potions", str(potions[index]))
	sound("potion")
	potions.remove_at(index)
	if potion.is_empty():
		show_battle()
		return
	var before := {"hp": hp, "block": block, "energy": energy, "enemy": enemy_hp, "poison": enemy_status.amount("poison"), "hand": hand.size()}
	var first_use := relics.fire("potion_use_first", relic_ctx(), owned_relics)
	_apply_potion(potion)
	if int(first_use.get("repeat_potion", 0)) > 0: _apply_potion(potion)
	if enemy_hp <= 0:
		show_reward()
		return
	show_battle()
	await get_tree().process_frame
	if screen != "battle" or not content.has_node("BattleStage/Hero"): return
	var hero = content.get_node("BattleStage/Hero")
	var target = content.get_node("BattleStage/Enemy")
	var fx = _begin_fx()
	var lines: Array = [[hero, str(potion.get("name", "포션")), Color("f2cf72")]]
	if hp > before.hp: lines.append([hero, "회복 +%d" % (hp - before.hp), Color("8cedb0")])
	if block > before.block: lines.append([hero, "방어 +%d" % (block - before.block), Color("79cce7")])
	if energy > before.energy: lines.append([hero, "에너지 +%d" % (energy - before.energy), Color("f2cf72")])
	if hand.size() > before.hand: lines.append([hero, "뽑기 +%d" % (hand.size() - before.hand), Color("d3b4ff")])
	if enemy_status.amount("poison") > before.poison: lines.append([target, "독 +%d" % (enemy_status.amount("poison") - before.poison), Color("70e85a")])
	if enemy_hp < before.enemy: fx.impact(target, Color("bd74ff"), str(-(before.enemy - enemy_hp)))
	fx.rings.append({"point": fx.center(hero), "color": Color("f2cf72"), "age": 0.0})
	for line in lines:
		if not is_instance_valid(fx) or not is_instance_valid(line[0]): return
		fx.float_text(line[0], line[1], line[2])
		await get_tree().create_timer(0.38).timeout
	await get_tree().create_timer(0.8).timeout
	if is_instance_valid(fx): fx.queue_free()

## Healing after relics that weaken it (검은 온실핵: 25% less).
func _scaled_heal(amount: int) -> int:
	if amount > 0 and owned_relics.has("relic_epic_005"): return floori(amount * 0.75)
	return amount

func _apply_potion(potion: Dictionary) -> void:
	var healing := int(potion.get("heal", 0))
	if healing > 0: healing += relics.modify("potion_heal", relic_ctx(), owned_relics)
	hp = mini(max_hp, hp + _scaled_heal(healing))
	block += int(potion.get("block", 0))
	energy += int(potion.get("energy", 0))
	var damage := int(potion.get("damage", 0))
	var soaked := mini(enemy_block, damage)
	enemy_block -= soaked
	enemy_hp = maxi(0, enemy_hp - (damage - soaked))
	if int(potion.get("poison", 0)) > 0:
		enemy_status.set_amount("poison", enemy_status.amount("poison") + int(potion.poison))
	player_status.apply(potion.get("player_statuses", []))
	enemy_status.apply(potion.get("enemy_statuses", []))
	if int(potion.get("draw", 0)) > 0: _draw_cards(int(potion.draw))
	battle_end_heal = maxi(battle_end_heal, int(potion.get("battle_end_heal", 0)))
	Discovery.record("포션", str(potion.id))
	apply_relic_result(relics.fire("potion_use", relic_ctx(), owned_relics))
	if player_status.amount("vial_collector") > 0:
		_draw_cards(player_status.amount("vial_collector"))
		block += 3 * player_status.amount("vial_collector")

func show_reward():
	screen = "reward"
	hint("reward")
	sound("victory")
	clear_content()
	title.text = "전투 보상"
	shell.hide()
	var reward_gold := int(enemy.gold) + relic_total("reward_gold_bonus")
	if not battle_reward_claimed:
		# the heals are paid only to a party still standing (a double knock-out is a win by a hair; no potion or relic brings anyone back) and a heal-reducing relic applies to them
		var standing := hp > 0
		victory_heal_paid = {"relic": _scaled_heal(relic_total("victory_heal")) if standing else 0, "potion": _scaled_heal(battle_end_heal) if standing else 0}
	var recovery: int = int(victory_heal_paid.relic)
	var notes: Array = [{"text": "GOLD +%d" % reward_gold, "tint": Color("f2cf72")}]
	if recovery > 0: notes.append({"text": "유물 · HP %d 회복" % recovery, "tint": Color("8cedb0")})
	if int(victory_heal_paid.potion) > 0: notes.append({"text": "포션 · HP %d 회복" % int(victory_heal_paid.potion), "tint": Color("8cedb0")})
	if not battle_reward_claimed:
		gold += reward_gold
		hp = mini(max_hp, maxi(1, hp + int(victory_heal_paid.relic) + int(victory_heal_paid.potion)))
		battle_reward_claimed = true
		Timeline.log_win(run_log, enemy)
		reward_relic_lines = apply_relic_result(relics.fire("battle_won", relic_ctx(), owned_relics))
		reward_potion = _roll_potion_drop()
		reward_cards = roll_reward_cards(str(enemy.get("type", "전투")))
		# elites and bosses leave a relic to choose from
		if str(enemy.get("type", "")) in ["엘리트", "보스"]:
			var offer := relic_candidates(false)
			offer.shuffle()
			for relic in offer.slice(0, 3): reward_relic_options.append(str(relic.id))
	for line in reward_relic_lines: notes.append({"text": "유물 · " + line, "tint": Color("d3b4ff")})
	if not reward_potion.is_empty(): notes.append({"text": "포션 획득 · " + str(Data.find_record("potions", reward_potion).name), "tint": Color("8fd8e8")})
	if not reward_relic_taken.is_empty(): notes.append({"text": "유물 획득 · " + str(Data.find_record("relics", reward_relic_taken).name), "tint": Color("e0a35a")})
	reward_view = RewardView.new()
	reward_view.setup({
		"notes": notes,
		"relic_options": reward_relic_options.map(func(id): return Data.find_record("relics", id)) if reward_relic_taken.is_empty() else [],
		"relic_taken": reward_relic_taken,
		"cards": reward_cards,
	})
	reward_view.relic_picked.connect(func(id):
		if screen != "reward": return
		grant_relic(id)
		reward_relic_taken = id
		show_reward())
	reward_view.card_picked.connect(func(card): take_reward_card(card))
	reward_view.skipped.connect(func():
		if screen == "reward": advance_map())
	add_child(reward_view)

func take_reward_card(card):
	if screen != "reward": return
	sound("card_pick")
	deck.append(card.duplicate(true))
	Discovery.record("카드", str(deck.back().id))
	advance_map()

const ShopView = preload("res://scripts/shop_view.gd")
const CARD_PRICES := {"일반": 45, "고급": 65, "희귀": 80, "영웅": 130}
const RELIC_PRICES := {"일반": 90, "고급": 120, "희귀": 150, "영웅": 190, "전설": 220}
const REMOVAL_BASE_PRICE := 75
const REMOVAL_PRICE_STEP := 50
const MERCHANT_LINES := {
	"enter": [
		"살 거면 빨리 골라. 이 안개는 오래 못 버텨.",
		"상처 입은 손님은 환영이지. 지갑만 멀쩡하다면.",
		"값은 깎지 않아. 그래도 여기보다 싼 곳은 없을걸.",
		"어서 와. 문은 닫아 줘, 안개가 들어오니까.",
		"이 길로 살아서 온 손님은 오랜만이군.",
		"둘러봐. 만져도 되지만 깨뜨리면 값을 치러야 해.",
		"촛불이 꺼지기 전에 끝내자고.",
		"성당 쪽에서 오는 길인가? 그럼 약이 필요하겠군."
	],
	"bought": [
		"좋은 선택이야. 물릴 수는 없네.",
		"거래 성립. 오래 쓰게나.",
		"그건 네게 어울리는군.",
		"값은 치렀고, 이제 네 물건이야.",
		"안목이 있군. 그건 오래 기다린 물건이야.",
		"쓸 일이 없기를 빌지. 쓸 일이 생기겠지만.",
		"장부에 적어 두지. 이름은 묻지 않겠네."
	],
	"poor": [
		"주머니가 가볍군. 다음에 오게나.",
		"골드가 모자라네. 이건 자선이 아니야.",
		"깎아 달라는 말은 접어 두게. 나도 먹고살아야 하니.",
		"그 값엔 포장지도 못 줘.",
		"한 푼이 모자라도 모자란 거야.",
		"다른 걸 알아보든가, 더 벌어 오든가."
	],
	"belt_full": [
		"허리띠가 가득 찼군. 하나 비우고 오게.",
		"병을 더 달 자리가 없어. 마시든가 버리든가.",
		"손이 모자라면 약도 못 쓰는 법이지."
	],
	"full_hp": [
		"그 몸에 이게 필요해? 아직 멀쩡해 보이는데.",
		"상처가 없는 사람에게 약을 팔면 내 양심이 아파.",
		"다치면 그때 오게. 약은 도망 안 가."
	],
	"remove": [
		"기억을 덜어내는 값이지. 후회는 공짜야.",
		"한 장쯤 없어도 길은 이어지네.",
		"버리는 것도 솜씨라네.",
		"가벼워진 덱이 더 멀리 가는 법이지.",
		"지운 건 돌아오지 않아. 알고 있겠지?"
	],
	"leave": [
		"살아서 돌아오면 또 보자고.",
		"조심하게. 안개 속엔 장사꾼보다 나쁜 놈들이 있어."
	],
	"hover_cards": [
		"그 카드는 값어치를 해. 내가 보증하지.",
		"눈이 가는 카드가 있나?",
		"카드 한 장이 판세를 바꾸기도 하지.",
		"그건 쓰는 사람을 가리는 물건이야."
	],
	"hover_relics": [
		"오래된 물건일수록 사연이 깊지.",
		"그건 누군가의 마지막 소지품이었어.",
		"만져 보면 알아. 아직 온기가 남았거든.",
		"유물은 임자를 스스로 고른다더군."
	],
	"hover_potions": [
		"급할 땐 그만한 게 없지.",
		"맛은 보장 못 해. 효과는 보장하지.",
		"한 모금이면 숨통이 트일 거야."
	],
	"hover_removal": [
		"덜어내고 싶은 게 있나?",
		"손이 많이 가는 일이라 값이 오르지.",
		"깔끔하게 지워 주지. 흔적도 없이."
	]
}
var merchant_last_line := ""

var shop_stock: Dictionary = {}
var shop_view: Control
var rest_view: Control
var reward_view: Control
const RewardView = preload("res://scripts/reward_view.gd")
const RestView = preload("res://scripts/rest_view.gd")
var removal_count := 0

func removal_price() -> int:
	return maxi(0, REMOVAL_BASE_PRICE + REMOVAL_PRICE_STEP * removal_count + relics.modify("removal_price", {}, owned_relics))

func merchant_line(kind: String) -> String:
	var options: Array = MERCHANT_LINES[kind]
	var line := str(options.pick_random())
	for attempt in range(4):
		if line != merchant_last_line or options.size() < 2: break
		line = str(options.pick_random())
	merchant_last_line = line
	return line

func make_shop_stock() -> Dictionary:
	var pool: Array = card_db.get(selected_character.id, []).filter(func(c): return Timeline.available(c))
	if pool.size() < 3:
		pool.append_array(card_db.get("common", []).filter(func(c): return Timeline.available(c)))
	pool.shuffle()
	var cards: Array = []
	for card in pool.slice(0, 3):
		var offered: Dictionary = card.duplicate(true)
		var price: int = int(CARD_PRICES.get(offered.get("rarity", "일반"), 60))
		if randf() < 0.35 and not offered.get("upgrade", {}).is_empty():
			offered = Data.upgraded(offered)
			price += 25
		price = maxi(5, price + randi_range(-2, 2) * 5)
		cards.append({"card": offered, "price": price, "base_price": price, "sold": false, "sale": false})
	if not cards.is_empty():
		var sale: Dictionary = cards.pick_random()
		sale.price = maxi(5, int(round(sale.base_price * 0.7 / 5.0)) * 5)
		sale.sale = true
	var relics: Array = []
	var candidates: Array = relic_candidates(true)
	candidates.shuffle()
	for relic in candidates.slice(0, 3):
		relics.append({"id": relic.id, "price": int(RELIC_PRICES.get(relic.get("rarity", "일반"), 90)), "sold": false})
	var potion_pool: Array = Data.read("potions").filter(func(p): return Timeline.available(p))
	potion_pool.shuffle()
	var potions: Array = []
	for potion in potion_pool.slice(0, 3):
		if Data.find_record("potions", potion.id).is_empty(): continue
		var potion_price := int(potion.price)
		if owned_relics.has("relic_epic_006"): potion_price = int(round(potion_price * 1.5 / 5.0)) * 5
		potions.append({"id": potion.id, "price": potion_price, "sold": false})
	return {"cards": cards, "relics": relics, "potions": potions}

func show_shop():
	clear_content()
	screen = "shop"
	var node_id: int = expedition.current_id
	if not shop_stock.has(node_id):
		shop_stock[node_id] = make_shop_stock()
	if shop_visit_node != node_id:
		shop_visit_node = node_id
		relics.begin_shop()
	shell.hide()
	shop_view = ShopView.new()
	shop_view.setup(shop_stock[node_id], deck)
	shop_view.purchase.connect(shop_purchase)
	shop_view.remove_card.connect(shop_remove_card)
	shop_view.hovered.connect(func(kind: String): shop_view.say(merchant_line("hover_" + kind)))
	shop_view.leave_requested.connect(func():
		if screen == "shop": advance_map()
	)
	shop_view.refresh(gold, hp, max_hp, removal_price())
	add_child(shop_view)
	shop_view.say(merchant_line("enter"))

func shop_refresh(line_kind: String) -> void:
	shop_view.refresh(gold, hp, max_hp, removal_price())
	shop_view.say(merchant_line(line_kind))

func shop_purchase(kind: String, index: int) -> void:
	if screen != "shop" or not is_instance_valid(shop_view): return
	var stock: Dictionary = shop_stock[expedition.current_id]
	if kind == "removal":
		shop_refresh("poor")
		return
	if not stock.has(kind) or index < 0 or index >= stock[kind].size(): return
	var item: Dictionary = stock[kind][index]
	if item.sold: return
	if gold < int(item.price):
		shop_refresh("poor")
		return
	if kind == "potions":
		var potion: Dictionary = Data.find_record("potions", item.id)
		if potion.is_empty(): return
		if potions.size() >= POTION_SLOTS:
			shop_refresh("belt_full")
			return
		potions.append(str(potion.id))
		Discovery.record("포션", str(potion.id))
		apply_relic_result(relics.fire("shop_potion", {}, owned_relics))
	elif kind == "relics":
		if not grant_relic(str(item.id)): return
	elif kind == "cards":
		deck.append(item.card.duplicate(true))
		Discovery.record("카드", str(deck.back().id))
	else:
		return
	gold -= int(item.price)
	sound("shop_buy")
	item.sold = true
	shop_refresh("bought")

func shop_remove_card(deck_index: int) -> void:
	var price := removal_price()
	if screen != "shop" or deck.size() <= 1 or deck_index < 0 or deck_index >= deck.size(): return
	if gold < price:
		shop_refresh("poor")
		return
	gold -= price
	sound("card_remove")
	deck.remove_at(deck_index)
	removal_count += 1
	apply_relic_result(relics.fire("shop_removal", {}, owned_relics))
	shop_refresh("remove")

## Dev shortcut (editor/debug builds only): F9 jumps straight to the campfire, starting a Mira run first when none is active.
func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build(): return
	if not (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F9): return
	if selected_character.is_empty():
		choose_character(characters[0])
		take_arrival_reward(0)
		finish_arrival()
	hp = maxi(1, int(max_hp * 0.55))
	show_rest()

func show_rest():
	clear_content()
	screen = "rest"
	shell.hide()
	var rest_amount := int(max_hp * 0.3) + relic_total("rest_heal_bonus") + relics.modify("rest_heal", {"max_hp": max_hp}, owned_relics)
	rest_view = RestView.new()
	rest_view.setup({"character": str(selected_character.get("id", "mira")), "rest_amount": rest_amount, "hp": hp, "max_hp": max_hp}, deck)
	rest_view.rested.connect(func():
		if screen != "rest": return
		var rest_result := relics.fire("rest", {"hp": hp, "max_hp": max_hp}, owned_relics)
		hp = min(max_hp, hp + _scaled_heal(rest_amount))
		apply_relic_result(rest_result)
		apply_relic_result(relics.fire("rest_any", {"max_hp": max_hp}, owned_relics))
		advance_map())
	rest_view.upgraded.connect(func(index: int):
		if screen != "rest": return
		upgrade_card(index))
	add_child(rest_view)

## Relics the player could still receive. `shop_only` keeps the stricter shop rule (the `shop` flag).
func relic_candidates(shop_only := false) -> Array:
	var found: Array = []
	for relic in relic_db:
		if not str(relic.get("starter_character", "")).is_empty() or relic.get("rarity", "") == "고대": continue
		if owned_relics.has(relic.id) or not Timeline.available(relic): continue
		if shop_only and not relic.get("shop", true): continue
		if not shop_only and not relic.get("ordinary_drop", true): continue
		found.append(relic)
	return found

## Adds a relic with its immediate effects. Used by the shop and the treasure room.
func grant_relic(id: String) -> bool:
	var relic: Dictionary = Data.find_record("relics", id)
	if relic.is_empty() or owned_relics.has(id): return false
	owned_relics.append(id)
	sound("relic_get")
	Discovery.record("유물", id)
	if relic.get("reveal_map", false): has_full_map = true
	apply_relic_result(relics.fire("acquire", {}, [id]))
	if relic.has("hp_multiplier"):
		max_hp = maxi(1, floori(max_hp * relic.hp_multiplier))
		hp = mini(hp, max_hp)
	return true

func show_treasure():
	clear_content()
	title.text = "보물"
	var options: Array = []
	var pool := relic_candidates(false)
	pool.shuffle()
	var map_record: Dictionary = Data.find_record("relics", "explorer_map")
	if not owned_relics.has("explorer_map") and not map_record.is_empty():
		options.append(map_record)
		pool = pool.filter(func(r): return r.id != "explorer_map")
	options.append_array(pool.slice(0, 3 - options.size()))
	add_text("상자 안에 유물이 놓여 있다. 하나만 가져갈 수 있다.")
	apply_relic_result(relics.fire("treasure", {}, owned_relics))
	if not options.is_empty():
		var row := RelicChoice.new()
		row.setup(options, "Treasure_")
		row.picked.connect(func(id):
			grant_relic(id)
			advance_map()
		)
		content.add_child(row)
	if options.is_empty():
		add_text("상자는 비어 있다. 골드 40을 찾았다.")
		gold += 40
		add_button("계속한다", advance_map)

func show_story_event(id: String, chained := false) -> void:
	story_event = Data.find_record("events", id).duplicate(true)
	if story_event.is_empty():
		show_event()
		return
	clear_content()
	screen = "story_event"
	story_choice_taken = false
	story_follow_up = ""
	story_pending_battle = ""
	if not chained: apply_relic_result(relics.fire("event_enter", {}, owned_relics))
	sound("event_open")
	var character_id := str(selected_character.get("id", ""))
	story_event["choices"] = StoryRules.visible_choices(story_event.choices, character_id)
	story_event["dialogue"] = str(story_event.effect).split("\n\n")
	# a character's own lines are one text or a list of pages
	var own = story_event.get("dialogue_by_character", {}).get(character_id, "")
	if own is Array:
		for page in own:
			if not str(page).is_empty(): story_event["dialogue"].append(str(page))
	elif not str(own).is_empty():
		story_event["dialogue"].append(str(own))
	story_event["continue_label"] = "지도에 돌아간다 →"
	if int(story_event.get("act", 1)) >= 2: story_event["chapter"] = act_title(int(story_event.act))
	var flag_lines: Array[String] = []
	for flag in story_event.get("dialogue_by_flag", {}):
		if story_flags.has(flag): flag_lines.append(str(story_event.dialogue_by_flag[flag]))
	# a scene that can stack many earlier-choice lines (the epilogues) may group them so the reader is not paged through one sentence at a time
	var group := maxi(1, int(story_event.get("merge_flag_lines", 1)))
	for start in range(0, flag_lines.size(), group):
		story_event["dialogue"].append(" ".join(flag_lines.slice(start, start + group)))
	var event_price := relics.preview("event_cost", {}, owned_relics)
	for choice in story_event.choices:
		var full_cost := int(choice.get("gold_cost", 0))
		if full_cost > 0 and (event_price.add != 0 or event_price.free):
			var new_cost: int = 0 if event_price.free else maxi(0, full_cost + int(event_price.add))
			choice["gold_cost"] = new_cost
			choice["relic_free"] = bool(event_price.free)
			var old_text := "골드 %d을 내고 " % full_cost
			var old_text_alt := "골드 %d를 내고 " % full_cost
			choice["description"] = str(choice.description).replace(old_text, "골드 %d을 내고 " % new_cost if new_cost > 0 else "").replace(old_text_alt, "골드 %d를 내고 " % new_cost if new_cost > 0 else "")
		choice["effect_line"] = StoryRules.effect_summary(choice, relic_db)
		var reason := StoryRules.unavailable(choice, hp, gold, owned_relics, story_flags, relic_db)
		choice["disabled"] = not reason.is_empty()
		choice["disabled_reason"] = reason
		if not reason.is_empty(): choice.description += " · " + reason
	shell.hide()
	arrival_view = load("res://scripts/act_arrival.gd").new()
	arrival_view.relic_ids = owned_relics.duplicate()
	arrival_view.setup(story_event, {}, selected_character.name)
	arrival_view.reward_chosen.connect(take_story_choice)
	arrival_view.continue_requested.connect(func():
		if screen != "story_event" or not story_choice_taken: return
		if not story_pending_battle.is_empty():
			var kind := story_pending_battle
			story_pending_battle = ""
			start_battle(kind)
			return
		var next_id := story_follow_up
		if not next_id.is_empty() and not Data.find_record("events", next_id).is_empty(): show_story_event(next_id, true)
		else: advance_map()
	)
	add_child(arrival_view)

func take_story_choice(index: int) -> void:
	if screen != "story_event" or story_choice_taken or index < 0 or index >= story_event.choices.size():
		return
	var choice: Dictionary = story_event.choices[index]
	if not StoryRules.unavailable(choice, hp, gold, owned_relics, story_flags, relic_db).is_empty(): return
	story_choice_taken = true
	var gold_cost := int(choice.get("gold_cost", 0))
	if choice.get("relic_free", false): relics.fire("event_cost", {}, owned_relics)
	if gold < gold_cost:
		# gold is short: pay with relics of the stated rarity instead
		var payable: Array = StoryRules.alt_relics(choice, owned_relics, relic_db)
		for i in int(choice.alt_cost.get("count", 1)): owned_relics.erase(payable[i])
		gold_cost = 0
	if gold_cost > 0: apply_relic_result(relics.fire("event_paid", {}, owned_relics))
	hp = mini(max_hp, hp - int(choice.get("hp_cost", 0)) + int(choice.get("heal", 0)))
	gold += int(choice.get("gold_gain", 0)) - gold_cost
	if int(choice.get("gold_gain", 0)) > 0: sound("gold_gain")
	if choice.has("relic"): owned_relics.append(choice.relic)
	if not owned_relics.is_empty(): Discovery.record("유물", str(owned_relics.back()))
	if story_event.id == "empty_ward": story_flags["ward_resolved"] = true
	story_flags["event_seen_" + story_event.id] = true
	for flag in choice.get("exclusive_flags", []): story_flags.erase(flag)
	if choice.has("flag"): story_flags[choice.flag] = true
	for flag in choice.get("extra_flags", []): story_flags[flag] = true
	if choice.has("pending_effect"): pending_effects.append(str(choice.pending_effect))
	var fallback: Dictionary = choice.get("if_missing_repair", {})
	if not fallback.is_empty() and not story_flags.has(fallback.flag):
		story_flags[fallback.flag] = true
		if fallback.has("pending_effect"): pending_effects.append(str(fallback.pending_effect))
	story_follow_up = str(choice.get("follow_up", ""))
	story_extras(choice)
	var reply := str(choice.get("reply", ""))
	# hidden-result choices: one outcome is drawn by weight; its own text replaces the choice's reply
	var outcomes: Array = choice.get("outcomes", [])
	if not outcomes.is_empty():
		var outcome := pick_outcome(outcomes)
		gold = maxi(0, gold + int(outcome.get("gold_gain", 0)) - int(outcome.get("gold_loss", 0)))
		if int(outcome.get("heal", 0)) > 0: hp = mini(max_hp, hp + int(outcome.heal))
		if int(outcome.get("hp_loss", 0)) > 0: hp = maxi(1, hp - int(outcome.hp_loss))
		if outcome.has("relic") and not owned_relics.has(outcome.relic): grant_relic(str(outcome.relic))
		story_extras(outcome)
		for flag in outcome.get("extra_flags", []): story_flags[flag] = true
		if outcome.has("reply"): reply = str(outcome.reply)
	var extra := str(choice.get("reply_extra_by_character", {}).get(str(selected_character.get("id", "")), ""))
	if not extra.is_empty(): reply += "\n\n" + extra
	# earlier choices of the expedition colour how this one plays out (every matching flag adds its sentence)
	var by_flag: Dictionary = choice.get("reply_extra_by_flag", {})
	for flag in by_flag:
		if story_flags.has(flag): reply += "\n\n" + str(by_flag[flag])
	arrival_view.show_result(reply)

## One outcome out of a list of {"weight": n, ...}.
func pick_outcome(outcomes: Array) -> Dictionary:
	var total := 0
	for outcome in outcomes: total += maxi(1, int(outcome.get("weight", 1)))
	var roll := randi_range(1, total)
	for outcome in outcomes:
		roll -= maxi(1, int(outcome.get("weight", 1)))
		if roll <= 0: return outcome
	return outcomes.back()

## Deck and fight effects an event choice (or one of its outcomes) can have.
func story_extras(src: Dictionary) -> void:
	if int(src.get("max_hp_gain", 0)) > 0:
		max_hp += int(src.max_hp_gain)
		hp = mini(max_hp, hp + int(src.max_hp_gain))
	if int(src.get("heal_pct", 0)) > 0: hp = mini(max_hp, hp + ceili(max_hp * float(src.heal_pct) / 100.0))
	if int(src.get("card_upgrade", 0)) > 0: upgrade_random_cards(int(src.card_upgrade))
	if int(src.get("card_remove", 0)) > 0:
		# only the plain starting cards can be let go, and the deck never drops below five
		for i in int(src.card_remove):
			var options: Array[int] = []
			for index in deck.size():
				if ["strike", "defend"].has(str(deck[index].get("id", ""))): options.append(index)
			if deck.size() <= 5 or options.is_empty(): break
			deck.remove_at(options.pick_random())
	if src.has("card_add"):
		var pool: Array = card_db.get(str(selected_character.get("id", "")), [])
		var picked := {}
		if str(src.card_add) == "character":
			if not pool.is_empty(): picked = pool.pick_random().duplicate(true)
		else:
			for card in pool:
				if str(card.get("id", "")) == str(src.card_add): picked = card.duplicate(true)
		if not picked.is_empty():
			deck.append(picked)
			Discovery.record("카드", str(picked.get("id", "")))
	for i in int(src.get("curse_add", 0)): deck.append(SIDE_EFFECT_CARD.duplicate(true))
	if src.has("battle"): story_pending_battle = str(src.battle)

func upgrade_random_cards(count: int) -> Array[String]:
	var names: Array[String] = []
	for n in count:
		var options: Array[int] = []
		for i in deck.size():
			if not deck[i].get("upgraded", false) and not deck[i].get("upgrade", {}).is_empty(): options.append(i)
		if options.is_empty(): break
		var chosen: int = options.pick_random()
		deck[chosen] = Data.upgraded(deck[chosen])
		names.append(str(deck[chosen].name))
	return names

## ACT I events still available to this character: shared ones and the character's own.
func event_candidates() -> Dictionary:
	var found := {"common": [], "personal": []}
	var who := str(selected_character.get("id", ""))
	for item in Data.read("events"):
		if int(item.get("act", 0)) != current_act or story_flags.has("event_seen_" + item.id): continue
		var kind := str(item.get("pool", ""))
		if kind != "common" and kind != "personal": continue
		if kind == "personal" and str(item.get("character_restriction", "")) != who: continue
		var ready := true
		for flag in item.get("requires_flags", []):
			if not story_flags.has(flag): ready = false
		if str(item.get("requires_relic", "")) != "" and not owned_relics.has(item.requires_relic): ready = false
		if ready: found[kind].append(item)
	return found

func show_event():
	var candidates := event_candidates()
	# a scene that continues a story the player earned (it needs earlier records) is never left to chance once it is available
	# (a scene marked `guaranteed` carries the main thread of a character's story: it is shown at the first event room of its act, not left to the coin flip below)
	var earned: Array = candidates.personal.filter(func(item): return not item.get("requires_flags", []).is_empty() or bool(item.get("guaranteed", false)))
	if not earned.is_empty():
		show_story_event(str(earned.pick_random().id))
		return
	# a character's own scene comes up about every other event, so it is met within a run
	var pool: Array = candidates.personal if not candidates.personal.is_empty() and randf() < 0.5 else candidates.common
	if pool.is_empty(): pool = candidates.personal
	if not pool.is_empty():
		show_story_event(pool.pick_random().id)
		return
	clear_content()
	var event = Data.find_record("events","twisted_altar")
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
	sound("card_upgrade")
	if not deck[index].get("upgraded", false):
		deck[index] = Data.upgraded(deck[index])
	apply_relic_result(relics.fire("rest_any", {"max_hp": max_hp}, owned_relics))
	apply_relic_result(relics.fire("rest_upgrade", {"max_hp": max_hp}, owned_relics))
	advance_map()

## The deck as card pictures, laid over whatever screen is open (map or battle), so closing it
## leaves that screen exactly as it was.
func show_deck():
	if has_node("DeckView"): return
	var view = load("res://scripts/deck_view.gd").new()
	view.setup(deck, str(selected_character.get("name", "")))
	view.closed.connect(func():
		view.queue_free()
	)
	add_child(view)

## Illustrated codex hub (cards, relics, potions, monsters, story). The older reader that
## `show_codex()` opens still serves characters, story and the manuscript review.
func show_codex_hub(open := ""):
	for card in deck: Discovery.record("카드", str(card.id))
	for relic_id in owned_relics: Discovery.record("유물", relic_id)
	if has_node("CodexHub") or has_node("Codex"):
		return
	var hub = load("res://scripts/codex_hub.gd").new()
	hub.name = "CodexHub"
	hub.story_flags = story_flags.duplicate()
	hub.card_character = str(selected_character.get("id", ""))
	add_child(hub)
	hub.closed.connect(func():
		remove_child(hub)
		hub.queue_free()
		music.for_screen(screen)
	)
	music.play("story")
	if open == "story": hub.open_tile(4)
	elif open == "notes": hub.open_notes_screen()

func show_codex():
	for card in deck: Discovery.record("카드", str(card.id))
	for relic_id in owned_relics: Discovery.record("유물", relic_id)
	if has_node("Codex"):
		return
	var archive = load("res://scenes/Codex.tscn").instantiate()
	archive.story_flags = story_flags.duplicate()
	archive.card_character = str(selected_character.get("id", ""))
	add_child(archive)
	archive.closed.connect(func():
		remove_child(archive)
		archive.queue_free()
	)

func show_settings():
	clear_content()
	title.text = "설정"
	add_text("배경음악")
	var volume := HSlider.new()
	volume.name = "MusicVolume"
	volume.min_value = 0.0
	volume.max_value = 1.0
	volume.step = 0.05
	volume.value = music.volume
	volume.custom_minimum_size = Vector2(360, 32)
	volume.value_changed.connect(music.set_volume)
	content.add_child(volume)
	var mute := CheckBox.new()
	mute.name = "MusicMute"
	mute.text = "배경음악 끄기"
	mute.button_pressed = music.muted
	mute.toggled.connect(music.set_muted)
	content.add_child(mute)
	add_text("효과음")
	var sfx_slider := HSlider.new()
	sfx_slider.name = "SfxVolume"
	sfx_slider.min_value = 0.0
	sfx_slider.max_value = 1.0
	sfx_slider.step = 0.05
	sfx_slider.value = music.sfx_volume
	sfx_slider.custom_minimum_size = Vector2(360, 32)
	sfx_slider.value_changed.connect(music.set_sfx_volume)
	# letting go of the slider plays a sample, so the level can be judged by ear
	sfx_slider.drag_ended.connect(func(_changed: bool): sound("card_skill"))
	content.add_child(sfx_slider)
	var sfx_mute := CheckBox.new()
	sfx_mute.name = "SfxMute"
	sfx_mute.text = "효과음 끄기"
	sfx_mute.button_pressed = music.sfx_muted
	sfx_mute.toggled.connect(music.set_sfx_muted)
	content.add_child(sfx_mute)
	add_text("이야기 글자 속도 (화면의 글을 누르면 한 번에 펼쳐집니다)")
	var speed_box := HBoxContainer.new()
	speed_box.name = "TextSpeed"
	for i in GameSettings.SPEEDS.size():
		var pick := Button.new()
		pick.toggle_mode = true
		pick.button_pressed = GameSettings.speed == i
		pick.text = ("● " if pick.button_pressed else "") + GameSettings.SPEEDS[i]
		pick.custom_minimum_size = Vector2(110, 40)
		pick.pressed.connect(func():
			GameSettings.set_speed(i)
			# the chosen one is marked with a dot (a pressed button alone is hard to tell apart on the dark theme)
			for k in speed_box.get_child_count():
				var other: Button = speed_box.get_child(k)
				other.button_pressed = k == i
				other.text = ("● " if k == i else "") + GameSettings.SPEEDS[k])
		speed_box.add_child(pick)
	content.add_child(speed_box)
	var full := CheckBox.new()
	full.name = "Fullscreen"
	full.text = "전체 화면"
	full.button_pressed = GameSettings.fullscreen
	full.toggled.connect(GameSettings.set_fullscreen)
	content.add_child(full)
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
	sound("defeat")
	RunSave.autoclear()
	var killer := str(enemy.get("name", ""))
	var row := 0
	if expedition.current_id >= 0 and expedition.current_id < expedition.nodes.size(): row = int(expedition.nodes[expedition.current_id].get("row", 0))
	if not killer.is_empty():
		add_heading("%s 앞에서 쓰러졌습니다" % killer)
		add_text(("%s · %d번째 방 · %s" % [act_title(), row, selected_character.name]) if row > 0 else ("%s · %s" % [act_title(), selected_character.name]))
	add_text("덱 %d장 · 유물 %d개 · 골드 %d" % [deck.size(), owned_relics.size(), gold])
	if not potions.is_empty(): add_text("마시지 못한 포션 %d개가 벨트에 남아 있었습니다." % potions.size())
	add_text(defeat_tip())
	add_text("다시 원정할 수 있습니다.")
	settle_run("death")
	add_timeline_summary()
	var again: Dictionary = selected_character
	add_button("같은 캐릭터로 다시 원정", func(): choose_character(again))
	add_button("메인 메뉴", show_menu)

## One line of advice for the defeat screen, chosen from what actually went wrong (the first rule that fits wins).
func defeat_tip() -> String:
	var guards := deck.filter(func(c): return int(c.get("block", 0)) > 0 or int(c.get("barrier", 0)) > 0 or int(c.get("counter", 0)) > 0).size()
	var kind := str(enemy.get("type", ""))
	if not enemy.is_empty() and enemy_max_hp > 0 and enemy_hp > 0 and enemy_hp * 4 <= enemy_max_hp:
		return "팁: 적 HP가 거의 바닥이었습니다. 한 턴을 더 버틸 방어도나 회복을 덱에 더했다면 이길 수도 있었습니다."
	if not potions.is_empty():
		return "팁: 포션은 아끼다 쓰러지면 아무 소용이 없습니다. 위험하다 싶으면 먼저 마시세요."
	if kind == "보스" and battle_turn <= 4:
		return "팁: 보스 앞에서 일찍 무너졌습니다. 보스 앞 휴식에서는 회복과 카드 강화 중 더 급한 쪽을 먼저 고르세요."
	if deck.size() > 0 and guards * 5 < deck.size():
		return "팁: 방어도를 주는 카드가 적었습니다. 받는 피해를 줄이는 카드를 몇 장 섞어 보세요."
	if deck.size() >= 30:
		return "팁: 덱이 두꺼워 필요한 카드가 늦게 나옵니다. 상점이나 이벤트에서 카드를 제거하는 것도 방법입니다."
	return "팁: 적 머리 위 숫자는 이번 턴에 받을 피해입니다. 매 턴 막을지 맞설지 먼저 정해 보세요."

func add_picture(parent: Node, tex: Texture2D, minimum: Vector2) -> TextureRect:
	var picture = TextureRect.new()
	picture.texture = tex
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.custom_minimum_size = minimum
	parent.add_child(picture)
	return picture

func relic_ctx(card := {}) -> Dictionary:
	return {"turn": battle_turn, "hp": hp, "max_hp": max_hp, "kind": str(enemy.get("type", "")),
		"enemy_hp": enemy_hp, "enemy_max_hp": enemy_max_hp, "enemy_poison": enemy_status.amount("poison"),
		"enemy_venom": venom_turns, "self_poison": player_status.amount("poison"), "card": card,
		"dot_kill": kill_by_dot, "new_enemy": enemy_was_new, "energy": energy, "reward_gold": int(enemy.get("gold", 0)) + relic_total("reward_gold_bonus"),
		"upgraded_cards": deck.filter(func(c): return c.get("upgraded", false)).size(),
		"deck_no_heal": not deck.any(func(c): return int(c.get("heal", 0)) > 0),
		"no_curse": not deck.any(func(c): return str(c.get("type", "")) == "저주")}

## Every loss of the player's HP in battle goes through here, so a lethal save and the "HP lost" relics
## act the same for enemy attacks and poison, and see the HP that was really lost.
func lose_hp(amount: int) -> int:
	if amount <= 0: return 0
	var before := hp
	hp = maxi(0, hp - amount)
	if hp <= 0: apply_relic_result(relics.fire("lethal", relic_ctx(), owned_relics))
	var lost := before - hp
	if lost > 0 and screen == "battle":
		block += player_status.amount("numbed_senses")
		sound("hit_player", randf_range(0.96, 1.04))
		pain_battle += lost
		var echoed := player_status.amount("pain_ledger") + lost * player_status.amount("pain_mirror")
		if echoed > 0: enemy_hp = maxi(0, enemy_hp - echoed)
	if lost > 0 and hp > 0:
		var ctx := relic_ctx()
		ctx["damage"] = lost
		apply_relic_result(relics.fire("hp_lost", ctx, owned_relics))
	return lost

## Applies the summed operations of a relic trigger and returns short lines describing them.
func apply_relic_result(result: Dictionary) -> Array[String]:
	var notes: Array[String] = []
	if result.has("max_hp"):
		var delta := int(result.max_hp)
		max_hp = maxi(1, max_hp + delta)
		hp = mini(max_hp, hp + maxi(0, delta))
		notes.append("최대 HP %+d" % delta)
	if int(result.get("heal_pct", 0)) > 0:
		var amount := ceili(max_hp * float(result.heal_pct) / 100.0)
		hp = mini(max_hp, hp + amount)
		notes.append("HP +%d" % amount)
	if int(result.get("hp_loss", 0)) > 0:
		# a relic's own cost never kills, but it still counts as HP lost
		var cost := mini(int(result.hp_loss), maxi(0, hp - 1))
		hp -= cost
		notes.append("HP -%d" % cost)
		if cost > 0 and screen == "battle":
			pain_battle += cost
			var cost_ctx := relic_ctx()
			cost_ctx["damage"] = cost
			apply_relic_result(relics.fire("hp_lost", cost_ctx, owned_relics))
	if int(result.get("survive", 0)) > 0:
		hp = 1
		notes.append("HP 1로 버팀")
	if int(result.get("heal", 0)) > 0:
		hp = mini(max_hp, hp + _scaled_heal(int(result.heal)))
		notes.append("HP +%d" % int(result.heal))
	if int(result.get("gold", 0)) != 0:
		gold = maxi(0, gold + int(result.gold))
		notes.append("GOLD %+d" % int(result.gold))
	if int(result.get("block", 0)) != 0:
		block = maxi(0, block + int(result.block))
		notes.append("방어도 %+d" % int(result.block))
	if int(result.get("self_poison", 0)) > 0:
		player_status.apply([{"id": "poison", "amount": int(result.self_poison)}])
		notes.append("중독 %d" % int(result.self_poison))
	if int(result.get("enemy_weak", 0)) > 0:
		enemy_status.apply([{"id": "weak", "amount": int(result.enemy_weak)}])
		notes.append("적 약화 %d" % int(result.enemy_weak))
	if int(result.get("potion", 0)) > 0 and not brew_potion().is_empty(): notes.append("포션 1개")
	if int(result.get("energy", 0)) > 0:
		energy += int(result.energy)
		notes.append("에너지 +%d" % int(result.energy))
	if int(result.get("draw", 0)) > 0:
		_draw_cards(int(result.draw))
		notes.append("카드 %d장" % int(result.draw))
	if int(result.get("poison_enemy", 0)) > 0:
		enemy_status.set_amount("poison", enemy_status.amount("poison") + int(result.poison_enemy))
		notes.append("적 중독 +%d" % int(result.poison_enemy))
	if int(result.get("upgrade_random", 0)) > 0:
		var options: Array[int] = []
		for i in deck.size():
			if not deck[i].get("upgraded", false) and not deck[i].get("upgrade", {}).is_empty(): options.append(i)
		if not options.is_empty():
			var chosen: int = options.pick_random()
			deck[chosen] = Data.upgraded(deck[chosen])
			notes.append("%s 강화" % str(deck[chosen].name))
	if int(result.get("cleanse_poison", 0)) > 0:
		player_status.set_amount("poison", maxi(0, player_status.amount("poison") - int(result.cleanse_poison)))
	if not notes.is_empty() and screen == "battle" and not relics.last_fired.is_empty():
		show_relic_toast("%s · %s" % [", ".join(relics.last_fired), ", ".join(notes)])
	return notes

## A short notice at the top of the battle so the player sees which relic just acted.
## One-time tips for a first-time player (shown once ever, remembered in user://hints_seen.json; never during tests).
const HINTS := {
	"battle_basics": "카드를 적에게 끌어다 놓거나 1~9 키로 쓰세요. 에너지가 다 떨어지면 E 키로 턴을 끝냅니다.",
	"intent": "적 머리 위의 숫자는 이번 턴 끝에 받을 피해입니다. 방어도를 쌓으면 막을 수 있어요.",
	"reward": "카드는 하나만 고르거나 건너뛸 수 있습니다. 덱이 얇을수록 좋은 카드를 자주 뽑습니다.",
	# the first fight of each new character explains its own counter in one line
	"mech_severin": "죄목은 적에게 쌓입니다. 판결 카드를 쓰면 죄목 1개마다 피해가 늘고, 쓴 죄목은 사라집니다.",
	"mech_calamo": "쥐는 턴이 끝날 때 적을 물고, 적의 공격 한 번마다 한 마리가 대신 맞아 피해를 줄입니다.",
	"mech_esca": "불씨를 모아 두면 턴 시작에 방어도가 생깁니다. 화덕 카드는 불씨를 모두 태워 피해로 바꿉니다.",
}
static var hints_file := "user://hints_seen.json"
var hints_seen: Dictionary = {}

## The tips already shown are read from the file once (also before the first check of "was this tip seen").
func _load_hints() -> void:
	if not RunSave.allowed() or not hints_seen.is_empty() or not FileAccess.file_exists(hints_file): return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(hints_file))
	if parsed is Dictionary: hints_seen = parsed

func hint(id: String) -> void:
	if not RunSave.allowed() or not HINTS.has(id): return
	_load_hints()
	if hints_seen.has(id): return
	hints_seen[id] = true
	var file := FileAccess.open(hints_file, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(hints_seen))
		file.close()
	show_relic_toast(str(HINTS[id]), 96.0, 220.0, 1000.0, 4.2)

func show_relic_toast(text: String, y := 170.0, x := 220.0, width := 1000.0, hold := 1.6) -> void:
	var toast := find_child("RelicToast", false, false) as Label
	if toast == null:
		toast = Label.new()
		toast.name = "RelicToast"
		toast.position = Vector2(220, 170)
		toast.size = Vector2(1000, 40)
		toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
		toast.z_index = 50
		toast.add_theme_font_size_override("font_size", 24)
		toast.add_theme_color_override("font_color", Color("f2d27a"))
		toast.add_theme_color_override("font_outline_color", Color("120c18"))
		toast.add_theme_constant_override("outline_size", 8)
		add_child(toast)
	toast.text = text
	# x, y and width are in the 1440x900 design space; the window may be another size (the same scaling the screens use)
	var view := get_viewport_rect().size
	var ratio := minf(view.x / 1440.0, view.y / 900.0)
	toast.position = (view - Vector2(1440, 900) * ratio) / 2.0 + Vector2(x, y) * ratio
	toast.size.x = width * ratio
	toast.add_theme_font_size_override("font_size", maxi(14, roundi(24.0 * ratio)))
	toast.modulate.a = 1.0
	if toast.has_meta("fade"):
		var previous = toast.get_meta("fade")
		if previous is Tween and previous.is_valid(): previous.kill()
	var fade := create_tween()
	fade.tween_interval(hold)
	fade.tween_property(toast, "modulate:a", 0.0, 0.6)
	toast.set_meta("fade", fade)

func relic_total(effect: String) -> int:
	var total := 0
	for id in owned_relics:
		total += int(Data.find_record("relics", id).get(effect, 0))
	return total

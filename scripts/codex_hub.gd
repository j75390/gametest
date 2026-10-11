extends "res://scripts/codex_screen.gd"
## Codex hub: illustrated tiles for each collection. Opens the sub-screens as child overlays.
const CodexData = preload("res://scripts/codex_data.gd")
const Timeline = preload("res://scripts/timeline.gd")
const TILES := [
	{"id": "cards", "title": "카드 도감", "text": "원정에서 만난 모든 카드를 확인하세요.", "art": "res://assets/ui/codex/hub_cards_v1.png", "script": "res://scripts/codex_cards.gd"},
	{"id": "relics", "title": "유물 보관함", "text": "원정에서 얻은 유물과 장신구를 살펴보세요.", "art": "res://assets/ui/codex/hub_relics_v1.png", "script": "res://scripts/codex_collectibles.gd"},
	{"id": "potions", "title": "포션 연구실", "text": "원정에서 발견한 약과 조제물을 관찰하세요.", "art": "res://assets/ui/codex/hub_potions_v1.png", "script": "res://scripts/codex_collectibles.gd"},
	{"id": "monsters", "title": "몬스터 도감", "text": "원정에서 마주친 모든 적을 확인하세요.", "art": "res://assets/ui/codex/hub_monsters_v1.png", "script": "res://scripts/codex_monsters.gd"},
	{"id": "story", "title": "스토리", "text": "사건을 해결하면 이야기와 새 기록이 열립니다.", "art": "res://assets/ui/codex/hub_story_v1.png", "script": "res://scripts/codex_timeline.gd"}]
const TILE_W := 262.0
const TILE_H := 440.0
const GAP := 22.0

var tiles: Array[Button] = []
var child_screen: Control
var progress_label: Label

func build() -> void:
	make_label(canvas, "원정 도감", Rect2(0, 44, 1440, 64), 44, GOLD, true)
	progress_label = make_label(canvas, "", Rect2(0, 108, 1440, 34), 22, MUTED)
	_refresh_progress()
	var total_w := TILE_W * TILES.size() + GAP * (TILES.size() - 1)
	var x0 := (1440.0 - total_w) * 0.5
	for i in range(TILES.size()):
		_tile(i, Vector2(x0 + i * (TILE_W + GAP), 182))
	var character_panel := make_panel(canvas, Rect2(x0, 656, 520, 96), Color(0.1, 0.08, 0.14, 0.94), EDGE, 12)
	make_label(character_panel, "캐릭터 도감", Rect2(24, 8, 300, 40), 26, PARCHMENT, true, HORIZONTAL_ALIGNMENT_LEFT)
	make_label(character_panel, "원정대원의 기록과 전용 카드", Rect2(24, 48, 440, 34), 18, MUTED, false, HORIZONTAL_ALIGNMENT_LEFT)
	var open_character := click_area(character_panel, Rect2(0, 0, 520, 96))
	open_character.name = "OpenCharacters"
	open_character.pressed.connect(open_characters)
	var review := Button.new()
	review.name = "OpenReview"
	review.text = "제작자용 · 원고 검수 ↗"
	review.position = Vector2(1100, 700)
	review.size = Vector2(300, 44)
	review.flat = true
	review.add_theme_font_size_override("font_size", 18)
	review.add_theme_font_override("font", UiFont.serif(false))
	review.add_theme_color_override("font_color", MUTED)
	review.add_theme_color_override("font_hover_color", GOLD)
	review.pressed.connect(open_legacy.bind("캐릭터"))
	canvas.add_child(review)
	var notes_panel := make_panel(canvas, Rect2(x0 + 542, 656, 520, 96), Color(0.1, 0.08, 0.14, 0.94), EDGE, 12)
	make_label(notes_panel, "조사 기록", Rect2(24, 8, 300, 40), 26, PARCHMENT, true, HORIZONTAL_ALIGNMENT_LEFT)
	make_label(notes_panel, "원정에서 모은 단서와 기록을 읽습니다", Rect2(24, 48, 440, 34), 18, MUTED, false, HORIZONTAL_ALIGNMENT_LEFT)
	var open_notes := click_area(notes_panel, Rect2(0, 0, 520, 96))
	open_notes.name = "OpenNotes"
	open_notes.pressed.connect(open_notes_screen)

func _refresh_progress() -> void:
	var p: Array = CodexData.progress()
	var percent := 0 if p[1] == 0 else int(round(100.0 * p[0] / p[1]))
	progress_label.text = "도감 완성률  %d%%   ·   발견 %d / %d" % [percent, p[0], p[1]]

func _tile(index: int, at: Vector2) -> void:
	var info: Dictionary = TILES[index]
	var panel := make_panel(canvas, Rect2(at, Vector2(TILE_W, TILE_H)), Color("1b1522"), Color("6a5640"), 10)
	panel.name = "Tile_" + info.id
	var window := make_panel(panel, Rect2(14, 16, TILE_W - 28, 190), Color("0b080f"), Color("c9a86a"), 4)
	make_texture(window, info.art, Rect2(4, 4, TILE_W - 36, 182))
	make_label(panel, info.title, Rect2(8, 222, TILE_W - 16, 44), 28, GOLD, true)
	var rule := ColorRect.new()
	rule.color = Color("6a5640")
	rule.position = Vector2(34, 272)
	rule.size = Vector2(TILE_W - 68, 2)
	panel.add_child(rule)
	make_label(panel, info.text, Rect2(20, 284, TILE_W - 40, 110), 20, PARCHMENT)
	var hit := click_area(panel, Rect2(0, 0, TILE_W, TILE_H), 10)
	hit.name = "Open_" + info.id
	hit.pressed.connect(open_tile.bind(index))
	tiles.append(hit)
	if info.id == "story":
		var fresh := Timeline.new_count()
		if fresh > 0:
			var tag := make_panel(panel, Rect2(TILE_W - 112, 26, 98, 30), Color("c9a24a"), Color("fff0b8"), 8)
			tag.name = "NewBadge"
			make_label(tag, "새 기록 %d" % fresh, Rect2(0, 0, 98, 30), 17, Color("1b0f0f"), true)

func open_tile(index: int) -> void:
	if is_instance_valid(child_screen): return
	var info: Dictionary = TILES[index]
	var screen: Control = load(info.script).new()
	screen.set("story_flags", story_flags)
	screen.set("card_character", card_character)
	if info.id in ["relics", "potions"]: screen.set("kind", "유물" if info.id == "relics" else "포션")
	_attach(screen)

func open_characters() -> void:
	if is_instance_valid(child_screen): return
	var screen: Control = load("res://scripts/codex_characters.gd").new()
	screen.set("story_flags", story_flags)
	screen.set("card_character", card_character)
	screen.connect("cards_requested", _open_cards_for)
	_attach(screen)

## From a character page straight to the card shelf filtered to that character.
func _open_cards_for(owner: String) -> void:
	if is_instance_valid(child_screen):
		child_screen.queue_free()
		child_screen = null
	var cards: Control = load("res://scripts/codex_cards.gd").new()
	cards.set("story_flags", story_flags)
	cards.set("card_character", card_character)
	cards.set("preset_owner", owner)
	_attach(cards)

## Investigation notes (clues, stories, regions) in the new reader.
func open_notes_screen(tab_name: String = "") -> void:
	if is_instance_valid(child_screen): return
	var notes: Control = load("res://scripts/codex_notes.gd").new()
	notes.set("story_flags", story_flags)
	if not tab_name.is_empty(): notes.set("tab", tab_name)
	_attach(notes)

## The previous reader still serves the character pages and the manuscript review.
func open_legacy(category: String) -> void:
	if is_instance_valid(child_screen): return
	var legacy: Control = load("res://scenes/Codex.tscn").instantiate()
	legacy.story_flags = story_flags.duplicate()
	legacy.card_character = card_character
	legacy.set_meta("legacy_category", category)
	_attach(legacy)
	legacy._change_category(category)

func _attach(screen: Control) -> void:
	child_screen = screen
	add_child(screen)
	screen.closed.connect(func():
		# Only the screen that asked to close is closed; a replaced screen cannot close its successor.
		var was_story := str(screen.get_script().resource_path).ends_with("codex_timeline.gd")
		if is_instance_valid(screen): screen.queue_free()
		if child_screen == screen: child_screen = null
		_refresh_progress()
		var badge := canvas.find_child("NewBadge", true, false)
		if badge and was_story: badge.queue_free()
	)

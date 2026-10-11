extends Control
## Player archive. Draft reading is a separate, explicit overlay.
signal closed
const Discovery = preload("res://scripts/codex_discovery.gd")
const COLLECTIONS := ["카드", "유물", "포션", "인챈트", "파워"]
const SECRET_KINDS := ["카드", "유물", "포션", "몬스터", "인챈트", "파워"]
const UNKNOWN := {"카드":"아직 이 카드를 발견하지 못했습니다.", "유물":"아직 이 유물을 발견하지 못했습니다.", "포션":"아직 이 포션을 발견하지 못했습니다.", "몬스터":"아직 이 몬스터를 만나지 못했습니다."}
const Assets = preload("res://scripts/character_assets.gd")
const Data = preload("res://scripts/game_data.gd")
const CardView = preload("res://scripts/battle_card.gd")
const CATEGORIES := ["캐릭터", "카드", "유물", "몬스터", "포션", "인챈트", "이벤트", "파워", "지역", "스토리"]
const INK := Color("100e16")
const GOLD := Color("bda578")
const MUTED := Color("a99ea9")
var records: Dictionary = {}
var story_flags: Dictionary = {}
var card_character := ""
var review_mode := false
var category := "캐릭터"
var selected_id := ""
var active_record: Dictionary = {}
var filters: Array[OptionButton] = []
var tab_buttons: Array[Button] = []
var list_buttons: Array[Button] = []
var search: LineEdit
var result_label: Label
var heading: Label
var list_box: VBoxContainer
var catalog_grid: GridContainer
var list_scroll: ScrollContainer
var reader_scroll: ScrollContainer
var art_box: VBoxContainer
var detail_box: VBoxContainer
var detail_row: HBoxContainer
var browse_panel: PanelContainer
var detail_panel: PanelContainer
var review_child: Control
var focus_before_review: Control

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_load_records()
	_catalog_records()
	_build()
	_change_category("유물" if review_mode else "캐릭터")
	tab_buttons[CATEGORIES.find(category)].grab_focus()

func _read(path: String) -> Variant:
	return JSON.parse_string(FileAccess.get_file_as_string(path))

func _load_records() -> void:
	var cards: Dictionary = Data.cards(card_character)
	var bios := {
		"mira": "검은 안개가 남긴 독을 약으로 바꾸는 연금술사. 죽은 성당의 지하 실험실에서 영혼을 증류한다.",
		"kalian": "무너진 성채의 마지막 검객. 갑옷에 새겨진 맹세를 지키기 위해 끝없는 원정에 오른다.",
		"sera": "별이 사라진 밤을 연구하는 마도사. 금지된 언어로 저주를 엮어 적의 운명을 무너뜨린다.",
		"lucian": "꺼져 가는 성화를 지키는 사제. 원정대의 상처를 돌보며 폐허 속에 남은 빛을 찾는다."
	}
	records["캐릭터"] = []
	for ch in _read("res://data/characters.json"):
		records["캐릭터"].append({"id": ch.id, "name": ch.name,
			"subtitle": ch.get("class", ""), "tags": ch.theme, "description": ch.get("biography", bios.get(ch.id, "")),
			"art": "res://assets/characters/%s_full.png" % ch.id,
			"sprite": "res://assets/characters/%s_motions.png" % ch.id,
			"stats": ["최대 체력  /  %d" % ch.max_hp, "시작 에너지  /  3"],
			"cards": cards.get(ch.id, []), "status": "원정대원 · 전용 카드 기록"})
	for record in records["캐릭터"]:
		var pack := Assets.profile(record.id)
		if pack.has("motions"):
			record.art = pack.full
			record.sprite = pack.motions.idle[0].path
			record["gallery"] = pack.get("gallery", [])
	records["지역"] = []
	records["지역"].append({"id":"basin_atlas", "name":"잿빛 분지", "subtitle":"분지의 지형", "description":"북쪽과 동서쪽의 능선이 분지를 둘러싸고, 물길은 남쪽 마을로 흘러간다. 성당은 서쪽 언덕, 운하는 낮은 땅에 있다. 동쪽 단구의 온실 너머로 오래된 회랑이 이어진다.\n\n이 지도는 땅의 모습을 보여 준다. 실제로 통과할 수 있는 길과 조사한 흔적은 원정 중 성당 지도에 기록한다.", "art":"res://assets/map/region_atlas_v1.png", "stats":[]})
	records["스토리"] = []
	for pair in [["지역", "regions"], ["스토리", "lore"]]:
		for item in Data.read(pair[1]):
			if item.get("requires_flag", "") == "" or story_flags.has(item.get("requires_flag", "")):
				records[pair[0]].append(_entry(item, pair[0]))

func _catalog_records() -> void:
	for narrative in Data.read("narrative_records"):
		var flag: String = narrative.get("requires_flag", "")
		var relic: String = narrative.get("requires_relic", "")
		if not review_mode and not flag.is_empty() and not story_flags.has(flag): continue
		if not review_mode and not relic.is_empty() and not Discovery.has("유물", relic): continue
		records[narrative.kind].append(narrative.duplicate(true))
	for story in Data.read("story_records"):
		if story.get("requires_flag", "") == "" or story_flags.has(story.requires_flag):
			records["스토리"].append(story)
	records["카드"] = []
	for pool in Data.cards(card_character).values():
		for card in pool:
			records["카드"].append(_entry(card, "카드"))
	for pair in [["유물", "relics"], ["몬스터", "monsters"], ["포션", "potions"], ["인챈트", "enchantments"], ["이벤트", "events"], ["파워", "powers"]]:
		records[pair[0]] = []
		for item in Data.read(pair[1]):
			if pair[0] not in SECRET_KINDS and item.get("discovery_flag", "") != "" and not story_flags.has(item.discovery_flag): continue
			records[pair[0]].append(_entry(item, pair[0]))
	if review_mode:
		_load_manuscripts()

func _entry(item: Dictionary, kind: String) -> Dictionary:
	var r := item.duplicate(true)
	r["undiscovered"] = not review_mode and kind in SECRET_KINDS and not Discovery.has(kind, str(item.id))
	r["subtitle"] = (item.get("rarity", "") + " · " if not item.get("rarity", "").is_empty() else "") + item.get("type", kind)
	r["description"] = Data.effect_text(item) if kind in ["카드", "포션"] else item.get("effect", item.get("description", ""))
	r["tags"] = " / ".join(item.get("keywords", []))
	r["status"] = "원정 기록 / " + kind
	r["stats"] = []
	if kind == "카드":
		r.stats.append("에너지 / %d · 대상 / %s" % [item.cost, item.target])
		r.stats.append("캐릭터 / " + _owner(item.character))
		r.stats.append("강화 효과 / " + Data.effect_text(Data.upgraded(item)))
	if kind == "유물":
		r.stats.append("저주 / " + ("있음" if item.get("cursed", false) else "없음"))
	if kind == "몬스터":
		r.stats.append("HP / %d · ACT %d · %s" % [item.hp, item.act, item.type])
		var Actions = preload("res://scripts/monster_actions.gd")
		for action in item.get("opener", []):
			r.stats.append("첫 행동 / %s · %s" % [action.name, Actions.text(action)])
		for action in item.pattern:
			r.stats.append("행동 / %s · %s" % [action.name, Actions.text(action)])
		for phase in item.get("phases", []):
			r.stats.append("HP %d%% 이하 · %s" % [int(phase.below_pct), str(phase.get("name", ""))])
			for action in phase.pattern:
				r.stats.append("  행동 / %s · %s" % [action.name, Actions.text(action)])

	if kind == "이벤트" and review_mode:
		for choice in item.choices:
			r.stats.append("선택 / " + choice.name + " — " + choice.get("description", ""))
			if review_mode: r.stats.append("결과 / " + choice.get("reply", ""))
	if item.get("flavor_text", "") != "":
		r["notes"] = item.flavor_text + "\n\n" + item.get("notes", "")
	if review_mode and not item.get("sources", []).is_empty(): r.stats.append("획득처 / " + " · ".join(item.sources))
	return r

func _owner(id: String) -> String:
	for ch in Data.read("characters"):
		if ch.id == id:
			return ch.name
	return "공용"

func _style(color: Color, border: Color, width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(width)
	style.set_content_margin_all(12)
	style.set_corner_radius_all(4)
	return style

func _label(parent: Node, value: String, font_size: int = 18, tint: Color = Color("e4d9c9")) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", tint)
	parent.add_child(label)
	return label

func _button(parent: Node, caption: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size.y = 42
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _panel(parent: Node) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _style(Color("17131d"), Color("352d38")))
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	return box

func _scroll(parent: Node, id: String) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.name = id
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	parent.add_child(scroll)
	return scroll

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = INK
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var backdrop := TextureRect.new()
	backdrop.texture = load("res://assets/backgrounds/selection_ruins_v2.png")
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.modulate = Color(0.24,0.22,0.28,0.35)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	var ui_theme := Theme.new()
	ui_theme.default_font_size = 17
	ui_theme.set_stylebox("normal", "Button", _style(Color("1b1720"), Color("403540")))
	ui_theme.set_stylebox("hover", "Button", _style(Color("302335"), GOLD))
	ui_theme.set_stylebox("pressed", "Button", _style(Color("422333"), GOLD))
	ui_theme.set_stylebox("focus", "Button", _style(Color.TRANSPARENT, GOLD, 2))
	ui_theme.set_color("font_color", "Button", Color("e5d8c6"))
	ui_theme.set_stylebox("normal", "LineEdit", _style(Color("18121e"), Color("4c3f50")))
	theme = ui_theme
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 22)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 18)
	margin.add_child(root)
	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 54
	root.add_child(header)
	heading = _label(header, "제작 원고 검수" if review_mode else "원정 도감", 30)
	if review_mode: _label(header, "후반 스포일러 포함 · 효과 적용 여부는 각 원고에 표시", 14, GOLD)
	_button(header, "돌아가기  ×" if review_mode else "닫기  ×", func(): closed.emit())
	root.add_child(HSeparator.new())
	var layout := HBoxContainer.new()
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 20)
	root.add_child(layout)
	var navigation := VBoxContainer.new()
	navigation.custom_minimum_size.x = 145
	navigation.add_theme_constant_override("separation", 5)
	layout.add_child(navigation)
	for label in CATEGORIES:
		var button := _button(navigation, label, _change_category.bind(label))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = true
		tab_buttons.append(button)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	navigation.add_child(spacer)
	var main := VBoxContainer.new()
	main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.add_theme_constant_override("separation", 14)
	layout.add_child(main)
	var toolbar := HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 8)
	main.add_child(toolbar)
	search = LineEdit.new()
	search.name = "Search"
	search.placeholder_text = "이름 검색"
	search.clear_button_enabled = true
	search.custom_minimum_size = Vector2(180, 42)
	search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar.add_child(search)
	search.text_changed.connect(func(_text): _rebuild_list())
	for label in ["등급", "종류", "캐릭터"]:
		var filter := OptionButton.new()
		filter.custom_minimum_size.x = 130
		filter.item_selected.connect(func(_index): _rebuild_list())
		toolbar.add_child(filter)
		filters.append(filter)
	result_label = _label(toolbar, "", 14, MUTED)
	result_label.custom_minimum_size.x = 85
	result_label.size_flags_horizontal = Control.SIZE_SHRINK_END
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_child(body)
	var browse := _panel(body)
	browse_panel = browse.get_parent()
	list_scroll = _scroll(browse, "RecordList")
	var list_root := VBoxContainer.new()
	list_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_scroll.add_child(list_root)
	list_box = VBoxContainer.new()
	list_box.add_theme_constant_override("separation", 8)
	list_root.add_child(list_box)
	catalog_grid = GridContainer.new()
	catalog_grid.add_theme_constant_override("h_separation", 12)
	catalog_grid.add_theme_constant_override("v_separation", 14)
	list_root.add_child(catalog_grid)
	list_scroll.resized.connect(_fit_grid)
	var reader := _panel(body)
	detail_panel = reader.get_parent()
	reader_scroll = _scroll(reader, "RecordDetails")
	detail_row = HBoxContainer.new()
	detail_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_row.add_theme_constant_override("separation", 22)
	reader_scroll.add_child(detail_row)
	art_box = _panel(detail_row)
	art_box.get_parent().size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	detail_box = VBoxContainer.new()
	detail_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_box.add_theme_constant_override("separation", 18)
	detail_row.add_child(detail_box)

func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

func _change_category(next_category: String) -> void:
	category = next_category
	search.set_block_signals(true)
	search.text = ""
	search.set_block_signals(false)
	for i in range(filters.size()):
		var filter := filters[i]
		filter.clear()
		filter.add_item(["등급", "종류", "캐릭터"][i] + " · 전체")
		var values: Array[String] = []
		for record in records[category]:
			if record.get("undiscovered", false): continue
			var value: String = record.get(["rarity", "type", "character"][i], "")
			if not value.is_empty() and not values.has(value): values.append(value)
		for value in values:
			filter.add_item(_owner(value) if i == 2 else value)
			filter.set_item_metadata(filter.item_count - 1, value)
		filter.select(0)
		filter.visible = category in ["카드", "유물", "몬스터", "포션", "인챈트", "파워"] and values.size() > 1
	for i in range(tab_buttons.size()): tab_buttons[i].set_pressed_no_signal(CATEGORIES[i] == category)
	var cards := category in COLLECTIONS and not review_mode
	heading.text = "제작 원고 검수" if review_mode else category + " 도감"
	browse_panel.add_theme_stylebox_override("panel", _style(Color(0.06,0.05,0.08,0.25), Color.TRANSPARENT, 0) if cards else _style(Color("17131d"), Color("352d38")))
	detail_panel.visible = not cards
	catalog_grid.visible = cards
	list_box.visible = not cards
	browse_panel.custom_minimum_size.x = 220 if not cards else 370
	browse_panel.size_flags_horizontal = Control.SIZE_FILL if not cards else Control.SIZE_EXPAND_FILL
	detail_panel.custom_minimum_size.x = 0 if not cards else 320
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL if not cards else Control.SIZE_FILL
	selected_id = records[category][0].id if not records[category].is_empty() else ""
	list_scroll.scroll_vertical = 0
	_rebuild_list()
	_fit_grid.call_deferred()

func _fit_grid() -> void:
	if is_instance_valid(catalog_grid): catalog_grid.columns = maxi(1, floori((list_scroll.size.x - 12) / (222.0 if category == "카드" else 144.0)))

func _rebuild_list() -> void:
	_clear(list_box)
	_clear(catalog_grid)
	list_buttons.clear()
	var filtered: Array = []
	for record in records[category]:
		var matches := true
		for i in range(filters.size()):
			if filters[i].visible and filters[i].selected > 0:
				var actual = record.get(["rarity", "type", "character"][i], "")
				var wanted = filters[i].get_selected_metadata()
				if actual != wanted and not (i == 2 and category == "카드" and actual == "common"): matches = false
		var query := search.text.strip_edges().to_lower()
		if record.get("undiscovered", false) and (not query.is_empty() or filters.any(func(f): return f.visible and f.selected > 0)): matches = false
		if matches and (query.is_empty() or (record.name + " " + record.get("tags", "") + " " + record.get("description", "")).to_lower().contains(query)): filtered.append(record)
	result_label.text = "%d개" % filtered.size()
	if filtered.is_empty():
		if category in COLLECTIONS and not review_mode: _label(catalog_grid, "일치하는 기록이 없습니다.", 20, MUTED)
		_clear(art_box)
		_clear(detail_box)
		art_box.get_parent().hide()
		active_record = {}
		selected_id = ""
		_label(detail_box, "일치하는 기록이 없습니다." if not search.text.is_empty() else "아직 발견한 기록이 없습니다.", 22, MUTED)
		return
	if not filtered.any(func(r): return r.id == selected_id): selected_id = filtered[0].id
	for record in filtered:
		var button: Button
		if category in COLLECTIONS and not review_mode:
			button = _button(catalog_grid, "", func(): pass)
			button.custom_minimum_size = Vector2(210,315) if category == "카드" else Vector2(132,145)
			button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
			if category == "카드" and not record.get("undiscovered", false):
				var visual := CardView.new()
				button.add_child(visual)
				visual.setup(record)
				visual.scale = Vector2.ONE * (210.0 / 220.0)
			else:
				var art := TextureRect.new()
				art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				art.position = Vector2(12,12)
				art.size = button.custom_minimum_size - Vector2(24,24)
				art.mouse_filter = Control.MOUSE_FILTER_IGNORE
				art.texture = _texture(record.get("art", ""))
				if category == "카드": art.texture = load("res://assets/ui/selection/codex_card_back.svg")
				elif record.get("undiscovered", false):
					if art.texture == null or not art.texture.get_image().detect_alpha():
						art.texture = load("res://assets/ui/selection/codex_unknown_potion.svg" if category == "포션" else "res://assets/ui/selection/codex_unknown_relic.svg")
					var shader := Shader.new()
					shader.code = "shader_type canvas_item; void fragment(){ float a=texture(TEXTURE,UV).a; vec2 d=TEXTURE_PIXEL_SIZE*3.0; float edge=max(max(texture(TEXTURE,UV+vec2(d.x,0)).a,texture(TEXTURE,UV-vec2(d.x,0)).a),max(texture(TEXTURE,UV+vec2(0,d.y)).a,texture(TEXTURE,UV-vec2(0,d.y)).a)); COLOR=vec4(mix(vec3(0.27),vec3(0.025),step(0.1,a)),max(a,edge)); }"
					var mat := ShaderMaterial.new()
					mat.shader = shader
					art.material = mat
				button.add_child(art)
				if art.texture == null:
					button.text = "미발견" if record.get("undiscovered",false) else record.name
			button.tooltip_text = ("미발견\n" + UNKNOWN.get(category,"아직 이 기록을 발견하지 못했습니다.")) if record.get("undiscovered",false) else record.name + "\n" + record.description
		else:
			button = _button(list_box, "미발견" if record.get("undiscovered",false) else record.name, _select.bind(record))
			button.custom_minimum_size = Vector2(185, 54)
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.toggle_mode = true
		button.set_meta("record_id", record.id)
		list_buttons.append(button)
		if record.id == selected_id: _select(record)

func _texture(path: String) -> Texture2D:
	if not path.begins_with("res://assets/") or not ResourceLoader.exists(path): return null
	return load(path) as Texture2D

func _select(record: Dictionary) -> void:
	active_record = record
	selected_id = record.id
	if record.get("undiscovered",false):
		_clear(art_box)
		_clear(detail_box)
		art_box.get_parent().hide()
		_label(detail_box,"미발견",30)
		_label(detail_box,UNKNOWN.get(category,"아직 이 기록을 발견하지 못했습니다."),20)
		return
	selected_id = record.id
	for button in list_buttons: button.set_pressed_no_signal(button.get_meta("record_id") == selected_id)
	_clear(art_box)
	_clear(detail_box)
	reader_scroll.scroll_vertical = 0
	if category in ["스토리", "지역"] and not review_mode:
		_show_story(record)
		return
	var art := _texture(record.get("art", ""))
	var show_art := art != null and category != "카드"
	art_box.get_parent().visible = show_art
	art_box.get_parent().custom_minimum_size.x = 290 if category == "캐릭터" else 180
	art_box.get_parent().size_flags_horizontal = Control.SIZE_FILL
	if show_art:
		var pic := TextureRect.new()
		pic.name = "FullArtwork"
		pic.texture = art
		pic.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.custom_minimum_size = Vector2(0, 490 if category == "캐릭터" else 210)
		art_box.add_child(pic)
	_label(detail_box, record.name, 30)
	if not record.get("subtitle", "").is_empty(): _label(detail_box, record.subtitle, 16, GOLD)
	if not record.get("tags", "").is_empty(): _label(detail_box, record.tags, 15, Color("bd9fcb"))
	detail_box.add_child(HSeparator.new())
	_label(detail_box, record.description, 20)
	for stat in record.get("stats", []): _label(detail_box, stat, 17, GOLD)
	if category == "캐릭터":
		_button(detail_box, "전용 카드 보기 →", _show_character_cards.bind(record.id))
	if review_mode: _label(detail_box, record.get("status", ""), 14, MUTED)
	if review_mode and not record.get("notes", "").is_empty(): _label(detail_box, record.notes, 17, MUTED)
	var links: Array = record.get("related", []).duplicate() if review_mode else []
	for other_kind in (records if review_mode else {}):
		for other in records[other_kind]:
			var link: String = other_kind + ":" + other.id
			if other.get("related", []).has(category + ":" + record.id) and not links.has(link): links.append(link)
	var visible_links: Array = []
	for link in links:
		var parts = link.split(":", true, 1)
		if parts.size() != 2: continue
		for related in records.get(parts[0], []):
			if related.id == parts[1]: visible_links.append([parts[0], related])
	if not visible_links.is_empty():
		detail_box.add_child(HSeparator.new())
		_label(detail_box, "이어지는 기록", 18, GOLD)
		for link in visible_links:
			var button := _button(detail_box, link[1].name + "  →", _navigate.bind(link[0], link[1].id))
			button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _show_story(record: Dictionary) -> void:
	# One reading column; scene artwork never competes with a narrow text column.
	art_box.get_parent().hide()
	var title := _label(detail_box, record.name, 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var subtitle := _label(detail_box, record.get("subtitle", ""), 16, GOLD)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var art := _texture(record.get("art", ""))
	if art:
		var aspect := AspectRatioContainer.new()
		aspect.name = "StoryScene"
		aspect.ratio = float(art.get_width()) / float(art.get_height())
		aspect.custom_minimum_size.y = 320
		if category == "지역":
			aspect.resized.connect(func(): aspect.custom_minimum_size.y = aspect.size.x / aspect.ratio)
		aspect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		detail_box.add_child(aspect)
		var picture := TextureRect.new()
		picture.texture = art
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		aspect.add_child(picture)
		if category == "지역":
			picture.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			picture.gui_input.connect(func(event):
				if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT: _open_map_image(art)
			)
			_button(detail_box, "지도 크게 보기 · 확대 / 축소", _open_map_image.bind(art))
	var prose := _label(detail_box, record.description, 20)
	prose.name = "StoryProse"
	prose.add_theme_constant_override("line_spacing", 8)

func _open_map_image(art: Texture2D) -> void:
	if has_node("MapImageViewer"): return
	var viewer = load("res://scripts/map_image_viewer.gd").new()
	viewer.name = "MapImageViewer"
	viewer.art = art
	add_child(viewer)

func _show_character_cards(id: String) -> void:
	card_character = id
	_load_records()
	_catalog_records()
	_change_category("카드")
	for i in range(filters[2].item_count):
		if filters[2].get_item_metadata(i) == id:
			filters[2].select(i)
	_rebuild_list()

func _navigate(kind: String, id: String) -> void:
	_change_category(kind)
	selected_id = id
	_rebuild_list()
	for button in list_buttons:
		if button.get_meta("record_id") == id: list_scroll.ensure_control_visible.call_deferred(button)

func _open_review() -> void:
	if is_instance_valid(review_child): return
	focus_before_review = get_viewport().gui_get_focus_owner()
	review_child = get_script().new()
	review_child.name = "ManuscriptReader"
	review_child.review_mode = true
	review_child.story_flags = story_flags.duplicate()
	review_child.card_character = card_character
	add_child(review_child)
	review_child.closed.connect(func():
		remove_child(review_child)
		review_child.queue_free()
		review_child = null
		if is_instance_valid(focus_before_review): focus_before_review.grab_focus()
	)

func _set_review_mode(enabled: bool) -> void:
	review_mode = enabled
	_load_records()
	_catalog_records()
	heading.text = "제작 원고 검수" if enabled else "원정 도감"
	_change_category(category)

func _unhandled_key_input(event: InputEvent) -> void:
	if has_node("MapImageViewer"): return
	if is_instance_valid(review_child): return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		closed.emit()

func _load_manuscripts() -> void:
	var library: Dictionary = Data.read("_library")
	for pair in [["유물", "relics"], ["포션", "potions"], ["이벤트", "events"], ["파워", "powers"], ["지역", "regions"], ["스토리", "lore"]]:
		var by_id := {}
		for current in records[pair[0]]: by_id[current.id] = current
		for source in library.get(pair[1], []):
			var item: Dictionary = source.get("runtime", {}).duplicate(true)
			item.merge(source, true)
			item["name"] = source.get("name", source.get("title", ""))
			item["effect"] = source.get("story", source.get("effect", source.get("description", "")))
			item["art"] = source.get("image", source.get("icon", ""))
			item["cursed"] = source.get("curse_tag", false)
			if pair[1] == "powers": item["type"] = {"BUFF":"버프", "DEBUFF":"디버프", "POWER":"파워", "CURSE":"저주", "SPECIAL":"특수"}.get(source.get("category", ""), "특수")
			var entry := _entry(item, pair[0])
			var stage: String = source.get("implementation", "proposal")
			entry.status = "게임 적용 · 문구 검수 가능" if stage == "playable" else ("후반 스토리 원고 · 진행 미구현" if stage == "manuscript" else "효과·수치 검수안 · 전투 미적용")
			entry.subtitle = entry.subtitle + " · " + ("적용" if stage == "playable" else "원고")
			if source.get("character_restriction", "") != "": entry.stats.append("전용 / " + _owner(source.character_restriction))
			by_id[entry.id] = entry
		records[pair[0]] = by_id.values()

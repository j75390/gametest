extends Control
## Independent, data-backed archive. Reference package assets are never loaded.
signal closed
const Assets = preload("res://scripts/character_assets.gd")
const CharacterVisual = preload("res://scripts/character_visual.gd")

const Data = preload("res://scripts/game_data.gd")
const CATEGORIES := ["캐릭터", "카드", "유물", "몬스터", "포션", "인챈트", "이벤트", "파워", "지역", "스토리"]
var filters: Array[OptionButton] = []
var result_label: Label
const MOTIONS := ["기본", "이동", "공격", "스킬", "피격", "사망"]
const INK := Color("100e16")
const GOLD := Color("bda578")
const MUTED := Color("a99ea9")
var records: Dictionary = {}
var category := "캐릭터"
var selected_id := ""
var search: LineEdit
var list_box: VBoxContainer
var art_box: VBoxContainer
var detail_box: VBoxContainer
var gallery_box: HBoxContainer
var tab_buttons: Array[Button] = []
var motion_buttons: Array[Button] = []
var list_buttons: Array[Button] = []
var sprite_preview: TextureRect
var sheet: Texture2D
var motion_index := 0
var frame_index := 0
var frame_time := 0.0
var playing := true
var pause_button: Button
var active_record: Dictionary = {}
var body: HBoxContainer
var outer_scroll: ScrollContainer
var reader_scroll: ScrollContainer
var list_scroll: ScrollContainer
var gallery_scroll: ScrollContainer

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _load_records()
    _catalog_records()
    _build()
    _change_category("캐릭터")
    tab_buttons[0].grab_focus()

func _read(path: String) -> Variant:
    return JSON.parse_string(FileAccess.get_file_as_string(path))

func _load_records() -> void:
    var cards: Dictionary = Data.cards()
    var bios := {
        "mira": "검은 안개가 남긴 독을 약으로 바꾸는 연금술사. 죽은 성당의 지하 실험실에서 영혼을 증류한다.",
        "kalian": "무너진 성채의 마지막 검객. 갑옷에 새겨진 맹세를 지키기 위해 끝없는 원정에 오른다.",
        "sera": "별이 사라진 밤을 연구하는 마도사. 금지된 언어로 저주를 엮어 적의 운명을 무너뜨린다.",
        "lucian": "꺼져 가는 성화를 지키는 사제. 원정대의 상처를 돌보며 폐허 속에 남은 빛을 찾는다."
    }
    records["캐릭터"] = []
    for ch in _read("res://data/characters.json"):
        records["캐릭터"].append({"id": ch.id, "name": ch.name,
            "subtitle": ch.get("class", ""), "tags": ch.theme, "description": bios.get(ch.id, ""),
            "art": "res://assets/characters/%s_full.png" % ch.id,
            "sprite": "res://assets/characters/%s_motions.png" % ch.id,
            "stats": ["최대 체력  /  %d" % ch.max_hp, "시작 에너지  /  3", "시작 덱  /  공격 5 · 방어 5"],
            "cards": cards.get(ch.id, []), "status": "원정대원 · 전용 카드 기록"})
    for record in records["캐릭터"]:
        var pack := Assets.profile(record.id)
        if pack.has("motions"):
            record.art = pack.full
            record.sprite = pack.motions.idle[0].path
            record["gallery"] = pack.get("gallery", [])
    records["지역"] = [{"id": "ash_cathedral", "name": "잿빛 성당", "subtitle": "지역 기록 · ACT I 구상",
        "tags": "폐허 / 촛불 / 검은 안개", "description": "종소리가 멎은 뒤에도 촛불은 꺼지지 않았다. 붉은 배너 너머로 난 길은 검은 안개 속에서 다시 갈라진다.",
        "art": "res://assets/cards/ash_cathedral.png", "stats": ["지도 공개  /  앞쪽 두 칸", "탐험가의 지도  /  현재 지도 공개"],
        "status": "세계관 기록 · ACT 전환 구현 전", "notes": "지역별 몬스터·이벤트 풀과 5개 ACT 진행은 아직 구현되지 않았습니다."}]
    records["스토리"] = [{"id": "last_flame", "name": "마지막 성화", "subtitle": "원정 기록 · 서문",
        "tags": "성당 / 원정대 / 저주", "description": "우리가 성문을 나섰을 때, 하늘에는 별이 없었다.\n\n미라는 빈 약병을 챙겼고, 칼리안은 무뎌진 검을 갈았다. 세라는 읽을 수 없는 지도를 접었다. 루시안은 마지막 촛불을 감싸 쥐었다.\n\n길은 하나가 아니었다. 무엇을 버리고 무엇을 가져갈 것인가. 원정대가 고를 수 있는 것은 오직 다음 한 걸음뿐이었다.",
        "art": "res://assets/cards/ash_cathedral.png", "stats": [], "status": "세계관 서문", "notes": "스토리 이벤트의 잠금·해금 진행은 아직 연결되지 않았습니다."}]

func _catalog_records() -> void:
    records["카드"] = []
    for pool in Data.cards().values():
        for card in pool:
            records["카드"].append(_entry(card, "카드"))
    for pair in [["유물", "relics"], ["몬스터", "monsters"], ["포션", "potions"], ["인챈트", "enchantments"], ["이벤트", "events"], ["파워", "powers"]]:
        records[pair[0]] = []
        for item in Data.read(pair[1]):
            records[pair[0]].append(_entry(item, pair[0]))

func _entry(item: Dictionary, kind: String) -> Dictionary:
    var r := item.duplicate(true)
    r["subtitle"] = item.get("rarity", "") + " · " + item.get("type", kind)
    r["description"] = Data.effect_text(item) if kind in ["카드", "포션"] else item.get("effect", "")
    r["tags"] = " / ".join(item.get("keywords", []))
    r["status"] = "원정 기록 / " + kind
    r["stats"] = []
    if kind == "카드":
        r.stats.append("에너지 / %d · 대상 / %s" % [item.cost, item.target])
        r.stats.append("캐릭터 / " + _owner(item.character))
        r.stats.append("기본 효과 / " + Data.effect_text(item))
        r.stats.append("강화 효과 / " + Data.effect_text(Data.upgraded(item)))
    if kind == "유물":
        r.stats.append("저주 / " + ("있음" if item.cursed else "없음"))
    if kind == "몬스터":
        r.stats.append("HP / %d · ACT %d · %s" % [item.hp, item.act, item.type])
        for action in item.pattern:
            r.stats.append("행동 / %s · 피해 %d" % [action.name, action.damage])
        r.stats.append("드랍 / 골드 %d · 캐릭터 전용 카드 보상" % item.gold)
    if kind == "이벤트":
        for choice in item.choices:
            r.stats.append("선택 / " + choice.name)
    r.stats.append("획득처 / " + " · ".join(item.get("sources", [])))
    return r

func _owner(id: String) -> String:
    for ch in Data.read("characters"):
        if ch.id == id:
            return ch.name
    return "공용"

func _style(color: Color, border: Color, width: int = 1) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = color
    s.border_color = border
    s.set_border_width_all(width)
    s.set_content_margin_all(10)
    s.corner_radius_top_left = 3
    s.corner_radius_bottom_right = 3
    return s

func _label(parent: Node, text_value: String, font_size: int = 16, color: Color = Color("e4d9c9")) -> Label:
    var label := Label.new()
    label.text = text_value
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", color)
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    parent.add_child(label)
    return label

func _button(parent: Node, caption: String, callback: Callable) -> Button:
    var b := Button.new()
    b.text = caption
    b.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
    b.custom_minimum_size.y = 42
    b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    b.pressed.connect(callback)
    parent.add_child(b)
    return b

func _panel(parent: Node, width: float = 0.0) -> VBoxContainer:
    var panel := PanelContainer.new()
    panel.custom_minimum_size.x = width
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    panel.add_theme_stylebox_override("panel", _style(Color("17131d"), Color("493c46")))
    parent.add_child(panel)
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 12)
    panel.add_child(v)
    return v

func _scroll(parent: Node, node_name: String) -> ScrollContainer:
    var sc := ScrollContainer.new()
    sc.name = node_name
    sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
    sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    sc.follow_focus = true
    parent.add_child(sc)
    return sc

func _build() -> void:
    var bg := ColorRect.new()
    bg.color = INK
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)
    var ui_theme := Theme.new()
    ui_theme.default_font_size = 16
    ui_theme.set_color("font_color", "Button", Color("d6c7b4"))
    ui_theme.set_stylebox("normal", "Button", _style(Color("201922"), Color("59464a")))
    ui_theme.set_stylebox("hover", "Button", _style(Color("382532"), GOLD))
    ui_theme.set_stylebox("pressed", "Button", _style(Color("4b2434"), GOLD))
    ui_theme.set_stylebox("focus", "Button", _style(Color(0, 0, 0, 0), GOLD, 2))
    ui_theme.set_stylebox("normal", "LineEdit", _style(Color("100d16"), Color("59464a")))
    ui_theme.set_color("font_color", "LineEdit", Color("e4d9c9"))
    theme = ui_theme
    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    for side in ["left", "right", "top", "bottom"]:
        margin.add_theme_constant_override("margin_" + side, 16)
    add_child(margin)
    outer_scroll = _scroll(margin, "ArchiveScroll")
    outer_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    var root := VBoxContainer.new()
    root.custom_minimum_size.x = 880
    root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    root.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root.add_theme_constant_override("separation", 10)
    outer_scroll.add_child(root)
    var header := HBoxContainer.new()
    root.add_child(header)
    var heading := VBoxContainer.new()
    heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(heading)
    _label(heading, "운빨 원정대  /  검은 기록보관소", 14, GOLD)
    _label(heading, "원정 도감", 32)
    _button(header, "닫기  ×", func(): closed.emit())
    var tabs := GridContainer.new()
    tabs.columns = 5
    tabs.name = "Categories"
    tabs.add_theme_constant_override("separation", 8)
    root.add_child(tabs)
    for tab_name in CATEGORIES:
        var b := _button(tabs, tab_name, _change_category.bind(tab_name))
        b.toggle_mode = true
        b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        tab_buttons.append(b)
    body = HBoxContainer.new()
    body.name = "ThreeColumns"
    body.custom_minimum_size.y = 400
    body.size_flags_vertical = Control.SIZE_EXPAND_FILL
    body.add_theme_constant_override("separation", 14)
    root.add_child(body)
    var left := _panel(body, 200)
    left.get_parent().size_flags_horizontal = Control.SIZE_FILL
    _label(left, "기록 목록", 18, GOLD)
    search = LineEdit.new()
    search.name = "Search"
    search.placeholder_text = "이름 · 속성 검색"
    search.clear_button_enabled = true
    search.text_changed.connect(func(_query): _rebuild_list())
    left.add_child(search)
    for label in ["등급", "타입", "캐릭터"]:
        var filter := OptionButton.new()
        filter.add_item(label + " · 전체")
        filter.item_selected.connect(func(_i): _rebuild_list())
        left.add_child(filter)
        filters.append(filter)
    result_label = _label(left, "", 13, MUTED)
    list_scroll = _scroll(left, "ListScroll")
    list_box = VBoxContainer.new()
    list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    list_box.add_theme_constant_override("separation", 8)
    list_scroll.add_child(list_box)
    art_box = _panel(body, 270)
    art_box.get_parent().size_flags_stretch_ratio = 1.35
    var right := _panel(body, 280)
    reader_scroll = _scroll(right, "DetailsScroll")
    detail_box = VBoxContainer.new()
    detail_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    detail_box.add_theme_constant_override("separation", 13)
    reader_scroll.add_child(detail_box)
    var lower := _panel(root)
    _label(lower, "전투 모션  /  전용 카드 기록", 17, GOLD)
    gallery_scroll = _scroll(lower, "GalleryScroll")
    gallery_scroll.custom_minimum_size.y = 230
    gallery_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    gallery_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    gallery_box = HBoxContainer.new()
    gallery_box.add_theme_constant_override("separation", 16)
    gallery_scroll.add_child(gallery_box)
    # The close button and Escape key both return to the underlying menu.

func _clear(node: Node) -> void:
    for child in node.get_children():
        node.remove_child(child)
        child.queue_free()

func _change_category(next_category: String) -> void:
    category = next_category
    search.text = ""
    for i in range(filters.size()):
        filters[i].clear()
        filters[i].add_item(["등급", "타입", "캐릭터"][i] + " · 전체")
        var values: Array[String] = []
        for r in records[category]:
            var value: String = r.get(["rarity", "type", "character"][i], "")
            if not value.is_empty() and not values.has(value):
                values.append(value)
                filters[i].add_item(_owner(value) if i == 2 else value)
                filters[i].set_item_metadata(filters[i].item_count - 1, value)
        filters[i].select(0)
    for i in range(tab_buttons.size()):
        tab_buttons[i].set_pressed_no_signal(CATEGORIES[i] == category)
    selected_id = records[category][0].id if not records[category].is_empty() else ""
    _rebuild_list()

func _rebuild_list() -> void:
    _clear(list_box)
    list_buttons.clear()
    var filtered: Array = []
    for record in records[category]:
        var match_filters := true
        for i in range(filters.size()):
            if filters[i].selected > 0 and record.get(["rarity", "type", "character"][i], "") != filters[i].get_selected_metadata():
                match_filters = false
        if match_filters and (search.text.strip_edges().is_empty() or JSON.stringify(record).to_lower().contains(search.text.strip_edges().to_lower())):
            filtered.append(record)
    result_label.text = "%d개 기록" % filtered.size()
    if filtered.is_empty():
        _label(list_box, "일치하는 기록이 없습니다.", 16, MUTED)
        selected_id = ""
        active_record = {}
        sheet = null
        _clear(art_box)
        _clear(detail_box)
        _clear(gallery_box)
        _label(detail_box, "검색어를 바꾸어 주세요.", 18)
        return
    if not filtered.any(func(r): return r.id == selected_id):
        selected_id = filtered[0].id
    for record in filtered:
        var b := _button(list_box, record.name + "\n" + record.subtitle, _select.bind(record))
        b.custom_minimum_size = Vector2(165, 76)
        b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        b.toggle_mode = true
        b.set_meta("record_id", record.id)
        list_buttons.append(b)
        if record.id == selected_id:
            _select(record)

func _texture(path: String) -> Texture2D:
    var allowed := path.begins_with("res://assets/characters/") or path.begins_with("res://assets/monsters/") or path.begins_with("res://assets/cards/")
    if not allowed or not ResourceLoader.exists(path):
        return null
    return load(path) as Texture2D

func _picture(parent: Node, texture: Texture2D, minimum: Vector2) -> TextureRect:
    var pic := TextureRect.new()
    pic.texture = texture
    pic.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    pic.custom_minimum_size = minimum
    pic.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    pic.size_flags_vertical = Control.SIZE_EXPAND_FILL
    parent.add_child(pic)
    return pic

func _select(record: Dictionary) -> void:
    active_record = record
    selected_id = record.id
    for button in list_buttons:
        button.set_pressed_no_signal(button.get_meta("record_id") == selected_id)
    _clear(art_box)
    _clear(detail_box)
    _clear(gallery_box)
    sheet = null
    sprite_preview = null
    motion_buttons.clear()
    motion_index = 0
    frame_index = 0
    playing = true
    reader_scroll.scroll_vertical = 0
    gallery_scroll.scroll_horizontal = 0
    _label(art_box, "ARCHIVE  /  " + record.id.to_upper(), 12, GOLD)
    var artwork := _texture(record.get("art", ""))
    if artwork:
        var large := _picture(art_box, artwork, Vector2(0, 280))
        large.name = "FullArtwork"
    else:
        _label(art_box, "전용 아트 미등록", 20, MUTED)
    _label(art_box, record.name, 22).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _label(detail_box, record.subtitle, 14, GOLD)
    _label(detail_box, record.name, 30)
    _label(detail_box, record.tags, 15, Color("c7a3c9"))
    detail_box.add_child(HSeparator.new())
    _label(detail_box, record.description, 17)
    for stat in record.get("stats", []):
        _label(detail_box, stat, 16, GOLD)
    _label(detail_box, record.status, 13, MUTED)
    if record.has("notes"):
        _label(detail_box, record.notes, 15, MUTED)
    _label(detail_box, "관련 기록 / 시너지", 18, GOLD)
    var links: Array = record.get("related", []).duplicate()
    for other_kind in records:
        for other in records[other_kind]:
            if other.get("related", []).has(category + ":" + record.id) and not links.has(other_kind + ":" + other.id):
                links.append(other_kind + ":" + other.id)
    if links.is_empty():
        _label(detail_box, "등록된 관련 기록 없음", 14, MUTED)
    for link in links:
        var parts = link.split(":")
        for related in records.get(parts[0], []):
            if related.id == parts[1]:
                _button(detail_box, "관련 " + parts[0] + " · " + related.name, _navigate.bind(parts[0], parts[1]))
    var cards: Array = record.get("cards", [])
    if not cards.is_empty():
        _label(detail_box, "전용 스킬", 18, GOLD)
        for card in cards:
            _label(detail_box, card.name + "  /  에너지 " + str(int(card.cost)), 17)
            _label(detail_box, card.text, 15, MUTED)
    if record.has("sprite"):
        _build_motion(record.sprite)
    for card in cards:
        _build_card(card, record.name)
    if record.has("gallery"):
        var gallery_controls := VBoxContainer.new()
        gallery_controls.custom_minimum_size.x = 165
        gallery_box.add_child(gallery_controls)
        _label(gallery_controls, "원화 · SD 갤러리", 17, GOLD)
        for item in record.gallery:
            _button(gallery_controls, item.name, _show_gallery.bind(item.path, item.name))
    if cards.is_empty():
        var info := VBoxContainer.new()
        info.custom_minimum_size.x = 420
        gallery_box.add_child(info)
        _label(info, "기록 열람", 20, GOLD)
        _label(info, record.get("notes", record.description), 16)
        _label(info, "선택한 분류의 상세 정보는 우측 패널에서 스크롤해 읽을 수 있습니다.", 14, MUTED)

func _build_motion(path: String) -> void:
    var panel := HBoxContainer.new()
    panel.custom_minimum_size.x = 320
    panel.add_theme_constant_override("separation", 12)
    gallery_box.add_child(panel)
    sheet = _texture(path)
    if not sheet:
        _label(panel, "독립 SD 모션 자산 미등록", 16, MUTED)
        return
    if Assets.profile(selected_id).has("motions"):
        sprite_preview = CharacterVisual.new()
        sprite_preview.custom_minimum_size = Vector2(210, 210)
        sprite_preview.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
        panel.add_child(sprite_preview)
        sprite_preview.loop_preview = true
        sprite_preview.setup(selected_id)
        sprite_preview.set_process(playing)
    else:
        sprite_preview = _picture(panel, null, Vector2(145, 180))
        sprite_preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    var controls := VBoxContainer.new()
    controls.custom_minimum_size.x = 158
    panel.add_child(controls)
    var grid := GridContainer.new()
    grid.columns = 2
    controls.add_child(grid)
    for i in range(MOTIONS.size()):
        var b := _button(grid, MOTIONS[i], _set_motion.bind(i))
        b.custom_minimum_size.x = 74
        b.toggle_mode = true
        if Assets.profile(selected_id).has("motions") and Assets.count(selected_id, Assets.KEYS[i]) == 0:
            b.disabled = true
            b.text += " · 제작 중"
        motion_buttons.append(b)
    pause_button = _button(controls, "Ⅱ 일시정지", _toggle_play)
    _set_motion(0)

func _set_motion(index: int) -> void:
    motion_index = index
    frame_index = 0
    frame_time = 0.0
    for i in range(motion_buttons.size()):
        motion_buttons[i].set_pressed_no_signal(i == index)
    _update_frame()

func _toggle_play() -> void:
    playing = not playing
    pause_button.text = "Ⅱ 일시정지" if playing else "▷ 재생"
    if is_instance_valid(sprite_preview) and sprite_preview is CharacterVisual:
        sprite_preview.set_process(playing)

func _update_frame() -> void:
    if not sheet or not is_instance_valid(sprite_preview):
        return
    if Assets.profile(selected_id).has("motions"):
        sprite_preview.play(Assets.KEYS[motion_index])
        return
    var atlas := AtlasTexture.new()
    atlas.atlas = sheet
    var cell := Vector2(sheet.get_width() / 4.0, sheet.get_height() / 6.0)
    atlas.region = Rect2(Vector2(frame_index, motion_index) * cell, cell)
    var frame_rows := {
        "mira": [0, 211, 420, 627, 835, 1029, 1214],
        "sera": [0, 256, 512, 768, 1044, 1280, 1536],
        "lucian": [0, 256, 512, 754, 1024, 1280, 1536]
    }
    if frame_rows.has(selected_id):
        # Measured boundaries of dedicated animation sheets, not full-body art.
        var rows: Array = frame_rows[selected_id]
        atlas.region = Rect2(frame_index * cell.x, rows[motion_index], cell.x, rows[motion_index + 1] - rows[motion_index])
    sprite_preview.texture = atlas

func _process(delta: float) -> void:
    if is_instance_valid(sprite_preview) and sprite_preview is CharacterVisual:
        return
    if sheet and playing:
        frame_time += delta
        var duration := Assets.duration(selected_id, Assets.KEYS[motion_index], frame_index) if Assets.profile(selected_id).has("motions") else 0.18
        if frame_time >= duration:
            frame_time -= duration
            var total := Assets.count(selected_id, Assets.KEYS[motion_index])
            frame_index = (frame_index + 1) % (total if total > 0 else 4)
            _update_frame()

func _build_card(card: Dictionary, owner_name: String) -> void:
    var box := _panel(gallery_box, 220)
    box.add_theme_constant_override("separation", 7)
    box.get_parent().size_flags_horizontal = Control.SIZE_FILL
    var path: String = card.get("art", "res://assets/cards/%s.png" % card.id)
    if not ResourceLoader.exists(path):
        path = "res://assets/cards/%s.svg" % card.id
    _picture(box, _texture(path), Vector2(0, 70))
    _label(box, card.name + "  ·  " + str(int(card.cost)), 18, GOLD)
    _label(box, card.rarity + " / " + card.type + " / 기본", 13, MUTED)
    _label(box, card.text, 14)
    _button(box, "상세 보기 · " + owner_name, _show_card.bind(card, owner_name))

func _navigate(kind: String, id: String) -> void:
    _change_category(kind)
    selected_id = id
    _rebuild_list()

func _show_card(card: Dictionary, _owner_name: String) -> void:
    _navigate("카드", card.id)

func _show_gallery(path: String, caption: String) -> void:
    _clear(art_box)
    var picture := _picture(art_box, _texture(path), Vector2(0, 280))
    picture.name = "FullArtwork"
    _label(art_box, caption, 18, GOLD)

func _unhandled_key_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        get_viewport().set_input_as_handled()
        closed.emit()

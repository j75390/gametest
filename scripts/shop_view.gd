extends Control
## Shelf-style roguelike shop. Pure view: main.gd owns gold/deck/stock and applies purchases.
signal purchase(kind: String, index: int)
signal remove_card(deck_index: int)
signal leave_requested
signal hovered(kind: String)

const Data = preload("res://scripts/game_data.gd")
const PotionBelt = preload("res://scripts/potion_belt.gd")
const UiFont = preload("res://scripts/ui_font.gd")
const BattleCard = preload("res://scripts/battle_card.gd")
const BACKGROUND := "res://assets/shop/shop_bg_v1.png"
const MERCHANT := "res://assets/shop/merchant_v1.png"
const TRAY := "res://assets/shop/display_tray_v1.png"
const GOLD := Color("d8b47a")
const POOR := Color("d85a5a")
const PANEL := Color("17121d")
const CARD_SCALE := 0.8

var canvas := Control.new()
var stock: Dictionary
var deck: Array
var gold := 0
var hp := 0
var max_hp := 0
var removal_price := 75
var shelf := Control.new()
var speech: Label
var status: Label
var picker: Control

func setup(shop_stock: Dictionary, deck_ref: Array) -> void:
	stock = shop_stock
	deck = deck_ref

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := ColorRect.new()
	backdrop.color = Color("0b080f")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	add_child(canvas)
	canvas.size = Vector2(1440, 900)
	if ResourceLoader.exists(BACKGROUND):
		var bg := TextureRect.new()
		bg.texture = load(BACKGROUND)
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.size = Vector2(1440, 900)
		bg.modulate = Color(0.55, 0.5, 0.6)
		canvas.add_child(bg)
	_build_merchant()
	canvas.add_child(shelf)
	resized.connect(_fit)
	_fit()
	rebuild()

func _fit() -> void:
	var ratio := minf(size.x / 1440.0, size.y / 900.0)
	canvas.scale = Vector2.ONE * ratio
	canvas.position = (size - Vector2(1440, 900) * ratio) * 0.5

func _build_merchant() -> void:
	var frame := _panel(Rect2(36, 32, 380, 560), canvas)
	if ResourceLoader.exists(MERCHANT):
		var portrait := TextureRect.new()
		portrait.texture = load(MERCHANT)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		portrait.position = Vector2(8, 8)
		portrait.size = Vector2(364, 544)
		frame.add_child(portrait)
	else:
		_label("행상인", Rect2(0, 250, 380, 40), 28, Color("6b5a78"), frame, true)
	var bubble := _panel(Rect2(36, 608, 380, 120), canvas)
	speech = _label("", Rect2(18, 12, 344, 96), 20, Color("e6d8c4"), bubble)
	speech.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	speech.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var wallet := _panel(Rect2(36, 744, 380, 124), canvas)
	status = _label("", Rect2(18, 10, 344, 104), 24, GOLD, wallet, true)
	status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func say(line: String) -> void:
	if speech: speech.text = "“%s”" % line

func refresh(new_gold: int, new_hp: int, new_max_hp: int, new_removal_price: int) -> void:
	gold = new_gold
	hp = new_hp
	max_hp = new_max_hp
	removal_price = new_removal_price
	if is_node_ready(): rebuild()

func rebuild() -> void:
	for child in shelf.get_children():
		shelf.remove_child(child)
		child.queue_free()
	status.text = "골드  %dG\n체력  %d / %d" % [gold, hp, max_hp]
	_heading("진열대 · 카드", Rect2(448, 36, 600, 36), 28)
	if ResourceLoader.exists(TRAY):
		var tray := TextureRect.new()
		tray.texture = load(TRAY)
		tray.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tray.stretch_mode = TextureRect.STRETCH_SCALE
		tray.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		tray.position = Vector2(430, 236)
		tray.size = Vector2(644, 214)
		tray.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shelf.add_child(tray)
	var cards: Array = stock.cards
	for i in range(cards.size()):
		_card_slot(i, cards[i], Vector2(448 + i * 216, 84))
	_heading("유물", Rect2(448, 420, 300, 34), 26)
	var relics: Array = stock.relics
	for i in range(relics.size()):
		var relic: Dictionary = Data.find_record("relics", relics[i].id)
		if relic.is_empty(): continue
		_item_slot("relics", i, relics[i], relic.name, relic.get("effect", ""), relic.get("art", ""), Vector2(448 + i * 214, 460), "")
	_heading("포션 · 전투 중 사용", Rect2(448, 612, 400, 34), 26)
	var potions: Array = stock.potions
	for i in range(potions.size()):
		var potion: Dictionary = Data.find_record("potions", potions[i].id)
		if potion.is_empty(): continue
		_item_slot("potions", i, potions[i], potion.name, PotionBelt.effect_line(potion), potion.get("art", ""), Vector2(448 + i * 214, 652), "")
	_removal_panel()
	var exit := _button("상점 나가기", Rect2(1090, 800, 314, 68), shelf, 24)
	exit.pressed.connect(func(): leave_requested.emit())

func _card_slot(index: int, item: Dictionary, at: Vector2) -> void:
	var holder := Control.new()
	holder.position = at
	holder.size = BattleCard.CARD_SIZE * CARD_SCALE
	shelf.add_child(holder)
	var card_view := BattleCard.new()
	if str(item.card.get("art", "")).is_empty():
		_label(str(item.card.name), Rect2(0, 0, 176, 264), 22, Color("e6d8c4"), holder, true)
	else:
		card_view.setup(item.card)
		card_view.scale = Vector2.ONE * CARD_SCALE
		holder.add_child(card_view)
	var sold: bool = item.sold
	if sold:
		holder.modulate = Color(0.35, 0.35, 0.4)
		_label("매진", Rect2(0, 110, 176, 44), 34, Color("e6d8c4"), holder, true)
	if not sold:
		var plate := Panel.new()
		plate.position = Vector2(at.x + 16, at.y + 273)
		plate.size = Vector2(144, 34)
		plate.add_theme_stylebox_override("panel", _box(Color(0.06, 0.04, 0.09, 0.88), 17))
		plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shelf.add_child(plate)
	_price_tag(item, Rect2(at.x, at.y + 272, 176, 36), shelf)
	if item.get("sale", false) and not sold:
		var percent := int(round((1.0 - float(item.price) / maxf(1.0, float(item.base_price))) * 100.0))
		var badge := _label("-%d%%" % percent, Rect2(at.x + 104, at.y - 14, 76, 34), 22, Color("fff4e0"), shelf, true)
		badge.name = "SaleBadge"
		badge.add_theme_stylebox_override("normal", _box(Color("b02c2c"), 8))
	var hit := _flat_button(Rect2(at, holder.size), shelf)
	hit.tooltip_text = "%s\n%s" % [item.card.name, Data.effect_text(item.card)]
	hit.disabled = sold
	hit.pressed.connect(func(): _buy("cards", index))
	hit.mouse_entered.connect(func(): hovered.emit("cards"))

func _item_slot(kind: String, index: int, item: Dictionary, title: String, body: String, icon_path: String, at: Vector2, block_reason: String) -> void:
	var sold: bool = item.sold
	var box := _panel(Rect2(at, Vector2(200, 140)), shelf)
	if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
		var icon := TextureRect.new()
		icon.texture = load(icon_path)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.position = Vector2(10, 10)
		icon.size = Vector2(72, 72)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(icon)
	# a long name gets a smaller font so it breaks between words, not in the middle of one (the name box is only 106 px wide)
	var name_size := 19 if title.length() <= 5 else (16 if title.length() == 6 else (14 if title.length() == 7 else 13))
	var name_label := _label(title, Rect2(88, 12, 106, 72), name_size, Color("ebd8b7"), box, true)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if sold:
		box.modulate = Color(0.4, 0.4, 0.45)
		_label("매진", Rect2(0, 92, 200, 36), 26, Color("e6d8c4"), box, true)
	elif not block_reason.is_empty():
		_label(block_reason, Rect2(0, 96, 200, 32), 20, Color("9a8fa8"), box)
	else:
		_price_tag(item, Rect2(0, 94, 200, 36), box)
	var hit := _flat_button(Rect2(at, Vector2(200, 140)), shelf)
	hit.tooltip_text = "%s\n%s" % [title, body]
	hit.disabled = sold
	hit.pressed.connect(func(): _buy(kind, index))
	hit.mouse_entered.connect(func(): hovered.emit(kind))

func _heading(value: String, rect: Rect2, font_size: int) -> void:
	_label(value, rect, font_size, GOLD, shelf, true).horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

func _price_tag(item: Dictionary, rect: Rect2, parent: Control) -> void:
	if item.sold: return
	var price := int(item.price)
	if item.get("sale", false):
		# old price struck through on the left, the new lower price large and green on the right
		var old_text := "%dG" % int(item.base_price)
		var old := _label(old_text, Rect2(rect.position.x + 16, rect.position.y, rect.size.x * 0.4, rect.size.y), 18, Color("a89aa6"), parent)
		var strike := ColorRect.new()
		strike.color = Color("d85a5a")
		strike.size = Vector2(old_text.length() * 10.0 + 4, 2)
		strike.position = Vector2(old.position.x + old.size.x * 0.5 - strike.size.x * 0.5, old.position.y + rect.size.y * 0.5)
		strike.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(strike)
		_label("%dG" % price, Rect2(rect.position.x + rect.size.x * 0.4, rect.position.y, rect.size.x * 0.6 - 16, rect.size.y), 28, Color("8fe0a0") if gold >= price else POOR, parent, true)
		return
	_label("%dG" % price, rect, 24, GOLD if gold >= price else POOR, parent, true)

func _removal_panel() -> void:
	var box := _panel(Rect2(1090, 84, 314, 330), shelf)
	_label("기억 지우기", Rect2(0, 18, 314, 36), 28, Color("ebd8b7"), box, true)
	var note := _label("덱에서 카드 한 장을 영구히 제거합니다.\n제거할 때마다 값이 50G 오릅니다.", Rect2(20, 70, 274, 120), 19, Color("d4c7c0"), box)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	var can_remove := deck.size() > 1
	_label("%dG" % removal_price if can_remove else "제거 불가", Rect2(0, 206, 314, 40), 30, GOLD if gold >= removal_price else POOR, box, true)
	var pick := _button("제거할 카드 선택", Rect2(20, 258, 274, 56), box, 21)
	pick.disabled = not can_remove
	pick.pressed.connect(_open_picker)
	pick.mouse_entered.connect(func(): hovered.emit("removal"))

func _buy(kind: String, index: int) -> void:
	if is_instance_valid(picker): return
	purchase.emit(kind, index)

func _open_picker() -> void:
	if is_instance_valid(picker): return
	if gold < removal_price:
		purchase.emit("removal", -1)
		return
	picker = Control.new()
	picker.size = Vector2(1440, 900)
	canvas.add_child(picker)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.05, 0.92)
	dim.size = Vector2(1440, 900)
	picker.add_child(dim)
	_label("제거할 카드를 고르세요 · %dG" % removal_price, Rect2(0, 24, 1440, 44), 32, GOLD, picker, true)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(80, 84)
	scroll.size = Vector2(1280, 700)
	picker.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 7
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(grid)
	var scale := 0.7
	for i in range(deck.size()):
		var cell := Control.new()
		cell.custom_minimum_size = BattleCard.CARD_SIZE * scale
		grid.add_child(cell)
		if str(deck[i].get("art", "")).is_empty():
			_label(str(deck[i].name), Rect2(Vector2.ZERO, cell.custom_minimum_size), 20, Color("e6d8c4"), cell, true)
		else:
			var card_view := BattleCard.new()
			card_view.setup(deck[i])
			card_view.scale = Vector2.ONE * scale
			cell.add_child(card_view)
		var hit := _flat_button(Rect2(Vector2.ZERO, cell.custom_minimum_size), cell)
		hit.pressed.connect(func(): _confirm_removal(i))
	var cancel := _button("취소", Rect2(570, 804, 300, 64), picker, 24)
	cancel.pressed.connect(_close_picker)

func _confirm_removal(deck_index: int) -> void:
	_close_picker()
	remove_card.emit(deck_index)

func _close_picker() -> void:
	if is_instance_valid(picker):
		picker.queue_free()
		picker = null

func _box(color: Color, radius := 10) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.content_margin_left = 6
	style.content_margin_right = 6
	return style

func _panel(rect: Rect2, parent: Control) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	var style := _box(Color(PANEL, 0.94), 12)
	style.border_color = Color("5b4a3a")
	style.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(panel)
	return panel

func _label(value: String, rect: Rect2, font_size: int, tint: Color, parent: Control, bold := false) -> Label:
	var item := Label.new()
	item.text = value
	item.position = rect.position
	item.size = rect.size
	item.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	item.add_theme_font_size_override("font_size", font_size)
	item.add_theme_font_override("font", UiFont.serif(bold))
	item.add_theme_color_override("font_color", tint)
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(item)
	return item

func _button(value: String, rect: Rect2, parent: Control, font_size: int) -> Button:
	var item := Button.new()
	item.text = value
	item.position = rect.position
	item.size = rect.size
	item.add_theme_font_size_override("font_size", font_size)
	item.add_theme_font_override("font", UiFont.serif())
	parent.add_child(item)
	return item

## Transparent click area with a visible border on hover/focus, laid over a drawn slot.
func _flat_button(rect: Rect2, parent: Control) -> Button:
	var item := Button.new()
	item.position = rect.position
	item.size = rect.size
	item.focus_mode = Control.FOCUS_NONE
	var hover := _box(Color(0.6, 0.45, 0.8, 0.12), 12)
	hover.border_color = Color("bba0d1")
	hover.set_border_width_all(3)
	var clear := StyleBoxEmpty.new()
	for state in ["normal", "pressed", "disabled", "focus"]:
		item.add_theme_stylebox_override(state, clear)
	item.add_theme_stylebox_override("hover", hover)
	parent.add_child(item)
	return item

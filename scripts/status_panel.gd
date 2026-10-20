extends VBoxContainer
const Data = preload("res://scripts/game_data.gd")
var health_text: Label
var display_name := ""
var maximum_hp := 1
var fill_style: StyleBoxFlat
var block_badge: TextureRect
const HP_COLOR := Color("b63c59")
const BLOCK_COLOR := Color("5d8db8")

## Block turns the bar steel-blue and shows its amount on a badge at the bar's left end.
func set_block(value: int) -> void:
	if fill_style: fill_style.bg_color = BLOCK_COLOR if value > 0 else HP_COLOR
	if block_badge:
		block_badge.visible = value > 0
		block_badge.get_node("Value").text = str(value)

func set_hp(value: int):
	get_child(0).value = maxi(0, value)
	if health_text: health_text.text = "%s  %d/%d" % [display_name, maxi(0, value), maximum_hp]

static func describe(id: String, statuses, maximum: int) -> String:
	var record := Data.find_record("powers", id)
	var count: int = statuses.amount(id)
	var unit := "턴" if record.get("stack_mode") == "DURATION" else "중첩"
	var text := "%s · %d%s\n%s" % [record.name, count, unit, record.get("tooltip", record.effect)]
	if record.get("behavior") == "dot_percent":
		var rate := float(statuses.entries[id].get("rate", record.get("rate", 0.08)))
		text = "%s · %d턴\n자신의 턴 시작 시 최대 HP의 %d%%만큼 HP를 잃고 남은 시간이 1턴 감소합니다. 피해는 올림하며 최소 1입니다. 방어도를 무시하며 중독과 별도로 적용됩니다." % [record.name, count, roundi(rate * 100)]
		text += "\n다음 턴 피해: %d (최대 HP %d)" % [maxi(1, ceili(maximum * rate)), maximum]
	elif record.get("behavior") == "dot_flat": text += "\n다음 턴 피해: %d" % count
	return text

static func describe_all(statuses, maximum: int) -> String:
	var parts: Array[String] = []
	for id in statuses.entries: parts.append(describe(id, statuses, maximum))
	return "\n\n".join(parts) if not parts.is_empty() else "현재 적용된 상태 없음"

func setup(unit_name: String, hp: int, maximum: int, statuses, block := 0, width := 280) -> void:
	display_name = unit_name
	maximum_hp = maximum
	custom_minimum_size.x = width
	var bar := ProgressBar.new()
	bar.max_value = maximum
	bar.value = maxi(0, hp)
	bar.show_percentage = false
	var background := StyleBoxFlat.new()
	background.bg_color = Color("21141e")
	background.set_corner_radius_all(5)
	background.set_border_width_all(1)
	background.border_color = Color("75583e")
	bar.add_theme_stylebox_override("background", background)
	var fill := StyleBoxFlat.new()
	fill.bg_color = HP_COLOR
	fill.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("fill", fill)
	fill_style = fill
	bar.custom_minimum_size = Vector2(width, 18)
	bar.tooltip_text = "%s · HP %d/%d" % [unit_name, maxi(0, hp), maximum]
	add_child(bar)
	health_text = Label.new()
	health_text.text = "%s  %d/%d" % [unit_name, maxi(0, hp), maximum]
	health_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	health_text.add_theme_font_size_override("font_size", 17)
	health_text.add_theme_color_override("font_outline_color", Color.BLACK)
	health_text.add_theme_constant_override("outline_size", 5)
	health_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(health_text)
	health_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	block_badge = TextureRect.new()
	block_badge.name = "BlockBadge"
	block_badge.texture = load("res://assets/ui/battle/block_shield.png")
	block_badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	block_badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	block_badge.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	block_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var block_value := Label.new()
	block_value.name = "Value"
	block_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	block_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	block_value.add_theme_font_size_override("font_size", 21)
	block_value.add_theme_color_override("font_outline_color", Color("10243a"))
	block_value.add_theme_constant_override("outline_size", 6)
	block_value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	block_badge.add_child(block_value)
	block_value.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bar.add_child(block_badge)
	block_badge.position = Vector2(-30, -14)
	block_badge.size = Vector2(46, 46)
	set_block(block)
	var row := HFlowContainer.new()
	row.custom_minimum_size.y = 34
	add_child(row)
	# with many statuses (power cards pile up) the icons get smaller so the rows stay clear of the hand
	var icon_px := 34.0 if statuses.entries.size() <= 10 else (28.0 if statuses.entries.size() <= 15 else 24.0)
	for id in statuses.entries:
		var record := Data.find_record("powers", id)
		var icon = preload("res://scripts/battle_unit_view.gd").new()
		icon.name = id
		icon.texture = load(record.art)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(icon_px, icon_px)
		icon.mouse_filter = Control.MOUSE_FILTER_STOP
		var count: int = statuses.amount(id)
		icon.tooltip_text = describe(id, statuses, maximum)
		row.add_child(icon)
		var number := Label.new()
		number.text = str(count)
		number.add_theme_color_override("font_shadow_color", Color.BLACK)
		number.add_theme_constant_override("shadow_offset_x", 1)
		number.add_theme_constant_override("shadow_offset_y", 1)
		number.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.add_child(number)
		number.position = Vector2(icon_px * 0.58, icon_px * 0.44)

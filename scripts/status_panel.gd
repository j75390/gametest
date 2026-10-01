extends VBoxContainer
const Data = preload("res://scripts/game_data.gd")

static func describe(id: String, statuses, maximum: int) -> String:
	var record := Data.find_record("powers", id)
	var count: int = statuses.amount(id)
	var unit := "턴" if record.get("stack_mode") == "DURATION" else "중첩"
	var text := "%s · %d%s\n%s" % [record.name, count, unit, record.get("tooltip", record.effect)]
	if record.get("behavior") == "dot_percent":
		var rate := float(statuses.entries[id].get("rate", record.get("rate", 0.08)))
		text += "\n다음 턴 피해: %d (최대 HP의 %d%%)" % [maxi(1, ceili(maximum * rate)), roundi(rate * 100)]
	elif record.get("behavior") == "dot_flat": text += "\n다음 턴 피해: %d" % count
	return text

static func describe_all(statuses, maximum: int) -> String:
	var parts: Array[String] = []
	for id in statuses.entries: parts.append(describe(id, statuses, maximum))
	return "\n\n".join(parts) if not parts.is_empty() else "현재 적용된 상태 없음"

func setup(unit_name: String, hp: int, maximum: int, statuses) -> void:
	custom_minimum_size.x = 280
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
	fill.bg_color = Color("b63c59")
	fill.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("fill", fill)
	bar.custom_minimum_size = Vector2(280, 18)
	bar.tooltip_text = "%s · HP %d/%d" % [unit_name, maxi(0, hp), maximum]
	add_child(bar)
	var row := HFlowContainer.new()
	row.custom_minimum_size.y = 34
	add_child(row)
	for id in statuses.entries:
		var record := Data.find_record("powers", id)
		var icon = preload("res://scripts/battle_unit_view.gd").new()
		icon.name = id
		icon.texture = load(record.art)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(34, 34)
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
		number.position = Vector2(20, 15)

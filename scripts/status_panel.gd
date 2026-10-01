extends VBoxContainer
const Data = preload("res://scripts/game_data.gd")

func setup(unit_name: String, hp: int, maximum: int, statuses) -> void:
	custom_minimum_size.x = 280
	var bar := ProgressBar.new()
	bar.max_value = maximum
	bar.value = maxi(0, hp)
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(280, 18)
	bar.tooltip_text = "%s · HP %d/%d" % [unit_name, maxi(0, hp), maximum]
	add_child(bar)
	var row := HFlowContainer.new()
	row.custom_minimum_size.y = 34
	add_child(row)
	for id in statuses.entries:
		var record := Data.find_record("powers", id)
		var icon := TextureRect.new()
		icon.name = id
		icon.texture = load(record.art)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(34, 34)
		icon.mouse_filter = Control.MOUSE_FILTER_STOP
		var count: int = statuses.amount(id)
		var unit := "턴" if record.get("stack_mode") == "DURATION" else "중첩"
		icon.tooltip_text = "%s\n%s · %d%s\n%s" % [record.name, record.get("type", "파워"), count, unit, record.get("tooltip", record.effect)]
		if record.get("behavior") == "dot_percent":
			var rate := float(statuses.entries[id].get("rate", record.get("rate", 0.08)))
			icon.tooltip_text += "\n다음 턴 피해: %d (최대 HP의 %d%%)" % [maxi(1, ceili(maximum * rate)), roundi(rate * 100)]
		elif record.get("behavior") == "dot_flat":
			icon.tooltip_text += "\n다음 턴 피해: %d" % count
		row.add_child(icon)
		var number := Label.new()
		number.text = str(count)
		number.add_theme_color_override("font_shadow_color", Color.BLACK)
		number.add_theme_constant_override("shadow_offset_x", 1)
		number.add_theme_constant_override("shadow_offset_y", 1)
		number.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.add_child(number)
		number.position = Vector2(20, 15)

extends RefCounted
## Same panel style as build(), with a gold title line above the body text.
static func build_titled(title: String, body: String) -> Control:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1b1423")
	style.border_color = Color("b79660")
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	var heading := Label.new()
	heading.text = title
	heading.add_theme_font_size_override("font_size", 21)
	heading.add_theme_color_override("font_color", Color("e8c171"))
	box.add_child(heading)
	var text := Label.new()
	text.text = body
	text.custom_minimum_size.x = 340
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_font_size_override("font_size", 17)
	text.add_theme_color_override("font_color", Color("f1e5d1"))
	box.add_child(text)
	return panel

static func build(text: String) -> Control:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1b1423")
	style.border_color = Color("b79660")
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = text
	label.custom_minimum_size.x = 340
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", Color("f1e5d1"))
	panel.add_child(label)
	return panel

extends TextureRect
## Icon whose hover tooltip is a titled panel (gold title + body text).
var title := ""
var body := ""

func setup_tip(heading: String, text: String) -> void:
	title = heading
	body = text
	tooltip_text = heading

func _make_custom_tooltip(_for_text: String) -> Object:
	return preload("res://scripts/battle_tooltip.gd").build_titled(title, body)

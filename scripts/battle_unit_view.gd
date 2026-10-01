extends TextureRect
func _make_custom_tooltip(for_text: String) -> Object:
	return preload("res://scripts/battle_tooltip.gd").build(for_text)

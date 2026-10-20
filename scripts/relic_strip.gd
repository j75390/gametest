extends RefCounted
## A row of the relics the party carries, as small framed icons with the same hover text as the battle top bar.
## Used on screens that have no top bar (the map and the story pages).
const TipIcon = preload("res://scripts/tip_icon.gd")
const Data = preload("res://scripts/game_data.gd")

## `owned` = relic ids; the row is `width` wide at most (icons overlap a little when there are many) and `slot` px tall.
static func build(owned: Array, width: float, slot := 52.0) -> Control:
	var strip := Control.new()
	strip.name = "RelicStrip"
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.custom_minimum_size = Vector2(width, slot)
	strip.size = Vector2(width, slot)
	var pitch := minf(slot + 6.0, (width - slot) / maxf(1.0, float(owned.size() - 1))) if owned.size() > 1 else slot + 6.0
	for i in range(owned.size()):
		var record: Dictionary = Data.find_record("relics", str(owned[i]))
		var frame := TipIcon.new()
		frame.name = "StripRelic%d" % i
		frame.texture = load("res://assets/ui/topbar/relic_slot.png")
		frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		frame.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		frame.mouse_filter = Control.MOUSE_FILTER_STOP
		frame.setup_tip(str(record.get("name", owned[i])), "%s · %s" % [record.get("rarity", ""), record.get("effect", "")] if not record.is_empty() else "")
		frame.position = Vector2(i * pitch, 0)
		frame.size = Vector2(slot, slot)
		strip.add_child(frame)
		var art_path := str(record.get("art", ""))
		if not art_path.is_empty() and ResourceLoader.exists(art_path):
			var art := TextureRect.new()
			art.texture = load(art_path)
			art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			art.mouse_filter = Control.MOUSE_FILTER_IGNORE
			art.position = Vector2(slot * 0.19, slot * 0.19)
			art.size = Vector2(slot * 0.62, slot * 0.62)
			frame.add_child(art)
	return strip

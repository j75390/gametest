extends Control
## Three potion slots shown during battle. Click a filled slot to drink it; empty slots stay as dim outlines.
## The owner passes the ids it holds and whether drinking is allowed right now.
const Data = preload("res://scripts/game_data.gd")
const TipIcon = preload("res://scripts/tip_icon.gd")
const SLOT := 56.0
const GAP := 8.0

signal used(index: int)

func setup(potion_ids: Array, slots: int, enabled: bool) -> void:
	name = "PotionBelt"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(slots * SLOT + (slots - 1) * GAP, SLOT)
	for i in range(slots):
		var holder := Control.new()
		holder.name = "PotionSlot_%d" % i
		holder.position = Vector2(i * (SLOT + GAP), 0)
		holder.size = Vector2(SLOT, SLOT)
		add_child(holder)
		var frame := Panel.new()
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.size = holder.size
		var box := StyleBoxFlat.new()
		box.bg_color = Color(0.09, 0.06, 0.13, 0.85)
		box.border_color = Color("ad8953") if i < potion_ids.size() else Color(0.45, 0.38, 0.30, 0.55)
		box.set_border_width_all(2)
		box.set_corner_radius_all(10)
		frame.add_theme_stylebox_override("panel", box)
		holder.add_child(frame)
		if i >= potion_ids.size(): continue
		var potion: Dictionary = Data.find_record("potions", str(potion_ids[i]))
		if potion.is_empty(): continue
		var icon := TipIcon.new()
		icon.name = "Icon"
		icon.texture = load(str(potion.get("art", ""))) if ResourceLoader.exists(str(potion.get("art", ""))) else null
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		icon.position = Vector2(5, 5)
		icon.size = Vector2(SLOT - 10, SLOT - 10)
		icon.mouse_filter = Control.MOUSE_FILTER_STOP
		icon.pivot_offset = icon.size / 2
		if enabled:
			icon.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			icon.mouse_entered.connect(func():
				create_tween().tween_property(icon, "scale", Vector2.ONE * 1.18, 0.1)
				box.border_color = Color("f2cf72")
				box.bg_color = Color(0.2, 0.13, 0.28, 0.95))
			icon.mouse_exited.connect(func():
				create_tween().tween_property(icon, "scale", Vector2.ONE, 0.1)
				box.border_color = Color("ad8953")
				box.bg_color = Color(0.09, 0.06, 0.13, 0.85))
		icon.modulate = Color.WHITE if enabled else Color(1, 1, 1, 0.45)
		icon.setup_tip(str(potion.name), "%s\n\n클릭하면 마십니다." % effect_line(potion))
		icon.gui_input.connect(func(event: InputEvent):
			if enabled and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				used.emit(i)
		)
		holder.add_child(icon)

static func effect_line(potion: Dictionary) -> String:
	var text := str(potion.get("effect", ""))
	return text if not text.is_empty() else Data.effect_text(potion)

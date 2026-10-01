extends TextureRect
const Assets = preload("res://scripts/character_assets.gd")
var character_id := ""
var motion := "idle"
var frame_index := 0
var elapsed := 0.0
var loop_preview := false
var finished := false

func _make_custom_tooltip(for_text: String) -> Object:
	return preload("res://scripts/battle_tooltip.gd").build(for_text)

func setup(id: String, initial_motion: String = "idle") -> void:
	character_id = id
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if Assets.profile(id).get("pixel_art", false) else CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	play(initial_motion)

func play(next_motion: String) -> void:
	motion = next_motion
	frame_index = 0
	elapsed = 0.0
	finished = false
	texture = Assets.frame(character_id, motion, 0)

func _process(delta: float) -> void:
	var total := Assets.count(character_id, motion)
	if total == 0 or finished:
		return
	elapsed += delta
	# Consume every elapsed frame, including when rendering stalls briefly.
	while elapsed >= Assets.duration(character_id, motion, frame_index):
		elapsed -= Assets.duration(character_id, motion, frame_index)
		frame_index += 1
		if frame_index >= total:
			if loop_preview or motion in ["idle", "walk"]:
				frame_index = 0
			elif motion == "death":
				frame_index = total - 1
				finished = true
				elapsed = 0.0
				break
			else:
				var remainder := elapsed
				play("idle")
				elapsed = remainder
				total = Assets.count(character_id, motion)
				if total == 0:
					return
	texture = Assets.frame(character_id, motion, frame_index)

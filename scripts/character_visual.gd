extends TextureRect
const Assets = preload("res://scripts/character_assets.gd")
var character_id := ""
var motion := "idle"
var frame_index := 0
var elapsed := 0.0

func setup(id: String, initial_motion: String = "idle") -> void:
	character_id = id
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	play(initial_motion)

func play(next_motion: String) -> void:
	motion = next_motion
	frame_index = 0
	elapsed = 0.0
	texture = Assets.frame(character_id, motion, 0)

func _process(delta: float) -> void:
	var total := Assets.count(character_id, motion)
	if total == 0:
		return
	elapsed += delta
	var frame_duration := Assets.duration(character_id, motion, frame_index)
	if elapsed < frame_duration:
		return
	elapsed -= frame_duration
	frame_index += 1
	if frame_index >= total:
		if motion == "death":
			frame_index = total - 1
		elif motion in ["idle", "walk"]:
			frame_index = 0
		else:
			play("idle")
			return
	texture = Assets.frame(character_id, motion, frame_index)

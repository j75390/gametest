extends RefCounted
## Standalone animation frames: whole textures only, never sheet regions.
const KEYS := ["idle", "walk", "attack", "skill", "hurt", "death"]
static var profiles: Dictionary = {}

static func profile(character_id: String) -> Dictionary:
	if profiles.is_empty():
		profiles = JSON.parse_string(FileAccess.get_file_as_string("res://data/character_assets.json"))
	return profiles.get(character_id, {})

static func picture(character_id: String, role: String) -> Texture2D:
	var path: String = profile(character_id).get(role, "res://assets/characters/%s_full.png" % character_id)
	return load(path) as Texture2D if ResourceLoader.exists(path) else null

static func count(character_id: String, motion: String) -> int:
	return profile(character_id).get("motions", {}).get(motion, []).size()

static func frame(character_id: String, motion: String, index: int) -> Texture2D:
	var frames: Array = profile(character_id).get("motions", {}).get(motion, [])
	if frames.is_empty():
		var idle: Array = profile(character_id).get("motions", {}).get("idle", [])
		return load(idle[0].path) as Texture2D if not idle.is_empty() else null
	var item: Dictionary = frames[clampi(index, 0, frames.size() - 1)]
	return load(item.path) as Texture2D

static func duration(character_id: String, motion: String, index: int) -> float:
	var frames: Array = profile(character_id).get("motions", {}).get(motion, [])
	if frames.is_empty():
		return 0.16
	return maxf(0.01, float(frames[clampi(index, 0, frames.size() - 1)].get("duration", 0.16)))

static func motion_duration(character_id: String, motion: String) -> float:
	var total := 0.0
	for i in range(count(character_id, motion)):
		total += duration(character_id, motion, i)
	return total

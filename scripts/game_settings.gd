extends RefCounted
## Player settings other than sound (sound lives in music.gd): how fast story text types out, and full screen.
## Saved in user://game_settings.json. QA scripts (started with --script) read and write only a path they set themselves, so the player's real file is never touched.
const SPEEDS := ["느리게", "보통", "빠르게", "즉시"]
## Multiplier on the time a page of text takes to type out (0 = the whole page at once).
const FACTORS := [1.6, 1.0, 0.5, 0.0]
static var path := "user://game_settings.json"
static var force := false
static var speed := 1
static var fullscreen := false

static func allowed() -> bool:
	return force or not OS.get_cmdline_args().has("--script")

static func text_factor() -> float:
	return FACTORS[clampi(speed, 0, FACTORS.size() - 1)]

static func load_settings() -> void:
	if not allowed() or not FileAccess.file_exists(path): return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		speed = clampi(int(parsed.get("text_speed", speed)), 0, SPEEDS.size() - 1)
		fullscreen = parsed.get("fullscreen", false) == true

static func save_settings() -> void:
	if not allowed(): return
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file: file.store_string(JSON.stringify({"text_speed": speed, "fullscreen": fullscreen}))

static func set_speed(index: int) -> void:
	speed = clampi(index, 0, SPEEDS.size() - 1)
	save_settings()

static func set_fullscreen(on: bool) -> void:
	fullscreen = on
	save_settings()
	apply_window()

## Only the real game changes the window: a QA script's window keeps its size.
static func apply_window() -> void:
	if not allowed(): return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)

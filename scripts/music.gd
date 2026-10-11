extends Node
## Background music: one looping track per scene, cross-faded, on a "Music" bus.
## The same track is never restarted; volume and mute are saved per player.
const DIR := "res://assets/audio/bgm/"
const TRACKS := {
	"title": "title_embers.wav", "map": "map_fog.wav", "battle": "battle_ledger.wav",
	"boss": "boss_receiver.wav", "shop": "shop_candle.wav", "story": "story_margin.wav"}
const SCREEN_TRACK := {
	"menu": "title", "character_select": "title", "arrival": "story", "map": "map", "encounter": "map",
	"reward": "map", "shop": "shop", "story_event": "story", "game_over": "story"}
const BUS := "Music"
const FADE := 1.5
const BASE_DB := -12.0
static var path := "user://audio_settings.json"

var current := ""
var players: Array[AudioStreamPlayer] = []
var active := 0
var volume := 0.8
var muted := false
var cache := {}
var resume := {}
var fades := {}

func _ready() -> void:
	if AudioServer.get_bus_index(BUS) < 0:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, BUS)
	# three players so a quick scene change never cuts a track that is still fading out
	for i in 3:
		var player := AudioStreamPlayer.new()
		player.bus = BUS
		player.volume_db = -80.0
		add_child(player)
		players.append(player)
	for id in TRACKS: stream_for(id)
	_load_settings()
	_apply_bus()

func stream_for(id: String) -> AudioStream:
	if cache.has(id): return cache[id]
	if not TRACKS.has(id): return null
	var file: String = DIR + TRACKS[id]
	if not ResourceLoader.exists(file): return null
	var stream := load(file) as AudioStreamWAV
	if stream == null: return null
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	var frame_bytes := 2 * (2 if stream.stereo else 1)
	stream.loop_end = stream.data.size() / frame_bytes
	cache[id] = stream
	return stream

func for_screen(screen_name: String) -> void:
	if SCREEN_TRACK.has(screen_name): play(SCREEN_TRACK[screen_name])

func _fade(player: AudioStreamPlayer, to_db: float, stop_after: bool) -> void:
	if fades.has(player) and fades[player].is_valid(): fades[player].kill()
	var tween := create_tween()
	tween.tween_property(player, "volume_db", to_db, FADE)
	if stop_after: tween.tween_callback(player.stop)
	fades[player] = tween

## Cross-fades to a track. Asking for the track that is already playing does nothing, and a track
## that was left earlier picks up where it stopped instead of starting over.
func play(id: String) -> void:
	if id == current or not is_inside_tree(): return
	var next := stream_for(id)
	if next == null: return
	var outgoing := players[active]
	if current != "" and outgoing.playing: resume[current] = outgoing.get_playback_position()
	var incoming: AudioStreamPlayer = null
	for player in players:
		if player != outgoing and not player.playing: incoming = player
	if incoming == null:
		for player in players:
			if player != outgoing and (incoming == null or player.volume_db < incoming.volume_db): incoming = player
	if fades.has(incoming) and fades[incoming].is_valid(): fades[incoming].kill()
	current = id
	active = players.find(incoming)
	incoming.stream = next
	incoming.volume_db = -80.0
	incoming.play(float(resume.get(id, 0.0)))
	_fade(incoming, 0.0, false)
	for player in players:
		if player != incoming and player.playing: _fade(player, -80.0, true)

func set_volume(value: float) -> void:
	volume = clampf(value, 0.0, 1.0)
	_apply_bus()
	_save_settings()

func set_muted(value: bool) -> void:
	muted = value
	_apply_bus()
	_save_settings()

func _apply_bus() -> void:
	var bus := AudioServer.get_bus_index(BUS)
	if bus < 0: return
	AudioServer.set_bus_mute(bus, muted or volume <= 0.001)
	AudioServer.set_bus_volume_db(bus, BASE_DB + linear_to_db(maxf(volume, 0.001)))

func _load_settings() -> void:
	if not FileAccess.file_exists(path): return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		volume = clampf(float(parsed.get("music_volume", volume)), 0.0, 1.0)
		muted = parsed.get("music_muted", false) == true

func _save_settings() -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file: file.store_string(JSON.stringify({"music_volume": volume, "music_muted": muted}))

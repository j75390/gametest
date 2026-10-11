extends SceneTree
## Background music: every track loads and loops, each scene picks its track, the same track is never
## restarted, bosses get their own piece, and the volume/mute settings reach the Music bus.
const D = preload("res://scripts/codex_discovery.gd")
const M = preload("res://scripts/music.gd")
const T = preload("res://scripts/timeline.gd")
var failures: Array[String] = []

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func _initialize(): run.call_deferred()

func run():
	var stamp: int = Time.get_ticks_usec()
	D.path = "user://bgm_dex_%d.json" % stamp
	T.path = "user://bgm_tl_%d.json" % stamp
	M.path = "user://bgm_audio_%d.json" % stamp
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var music = main.music
	check(music != null and AudioServer.get_bus_index("Music") >= 0, "Music node and bus exist")
	for id in M.TRACKS:
		var stream: AudioStreamWAV = music.stream_for(id)
		check(stream != null, "Track loads: " + id)
		if stream == null: continue
		check(stream.loop_mode == AudioStreamWAV.LOOP_FORWARD and stream.loop_begin == 0, "Track loops: " + id)
		check(stream.loop_end == stream.data.size() / 4, "Loop covers whole track: " + id)
		check(stream.get_length() > 30.0, "Track is a full piece: " + id)
	check(music.current == "title", "Menu plays the title theme: " + music.current)
	main.choose_character(main.characters[0])
	check(music.current == "title" or music.current == "story" or music.current == "map", "Character start picks a calm theme: " + music.current)
	main._generate_map()
	main.expedition.current_id = 1
	main.arrival_pending = false
	main.show_map()
	check(music.current == "map", "Map plays the map theme: " + music.current)
	var before_player = music.players[music.active]
	main.show_map()
	check(music.players[music.active] == before_player and before_player.playing, "Same track is not restarted")
	main.show_shop()
	check(music.current == "shop", "Shop plays the shop theme: " + music.current)
	main.show_map()
	main.start_battle("전투")
	check(music.current == "battle", "Battle plays the battle theme: " + music.current)
	main.start_battle("보스")
	check(music.current == "boss", "Boss plays the boss theme: " + music.current)
	# a track left earlier resumes instead of restarting
	main.show_map()
	await create_timer(1.6).timeout
	var map_before: float = music.players[music.active].get_playback_position()
	main.start_battle("전투")
	await create_timer(1.6).timeout
	main.show_map()
	await create_timer(0.3).timeout
	var map_after: float = music.players[music.active].get_playback_position()
	check(music.current == "map" and map_after > map_before - 0.2 and map_after < map_before + 1.5, "Map theme resumes after a battle: %.1f -> %.1f" % [map_before, map_after])
	main.start_battle("보스")
	main.show_codex_hub()
	check(music.current == "story", "Codex plays the story theme: " + music.current)
	main.get_node("CodexHub").closed.emit()
	await process_frame
	check(music.current == main.music.SCREEN_TRACK.get(main.screen, music.current), "Closing the codex restores the scene theme: " + music.current)
	await create_timer(1.8).timeout
	var audible: Array = music.players.filter(func(p): return p.playing)
	check(audible.size() == 1 and music.players.size() == 3, "Only one track keeps playing after the fade: %d" % audible.size())
	var bus := AudioServer.get_bus_index("Music")
	music.set_volume(0.5)
	check(absf(AudioServer.get_bus_volume_db(bus) - (M.BASE_DB + linear_to_db(0.5))) < 0.01, "Volume reaches the bus")
	music.set_muted(true)
	check(AudioServer.is_bus_mute(bus), "Mute reaches the bus")
	music.set_muted(false)
	music.set_volume(1.0)
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(M.path))
	check(is_equal_approx(float(saved.music_volume), 1.0) and saved.music_muted == false, "Settings are saved")
	main.show_settings()
	check(main.content.find_child("MusicVolume", true, false) != null and main.content.find_child("MusicMute", true, false) != null, "Settings screen has volume and mute")
	for file in [D.path, T.path, T.path + ".bak", T.path + ".tmp", M.path]:
		if FileAccess.file_exists(file): DirAccess.remove_absolute(file)
	print("BGM_QA failures=%d" % failures.size())
	quit(1 if failures.size() > 0 else 0)

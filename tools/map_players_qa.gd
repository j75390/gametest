extends SceneTree
var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	for character in main.characters:
		main.choose_character(character)
		main.take_arrival_reward(0)
		main.finish_arrival()
		await process_frame
		await process_frame
		var view = main.content.get_node("ExpeditionScroll/RouteMap")
		check(view.player_markers.size()==1,"Missing solo face: "+character.id)
		check(view.player_markers.local.mouse_filter==Control.MOUSE_FILTER_IGNORE,"Marker blocks route input")
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/map-position-%s.png"%character.id)
	main.choose_character(main.characters[0])
	main.take_arrival_reward(0)
	main.finish_arrival()
	await process_frame
	await process_frame
	var view = main.content.get_node("ExpeditionScroll/RouteMap")
	var players: Array = []
	var colors := ["e5bd72","e988a4","91bde7","ae90ef"]
	for i in range(4):
		players.append({"player_id":str(i+1),"slot":i+1,"character_id":main.characters[i].id,"node_id":main.expedition.current_id,"is_local":i==0,"color":colors[i]})
	var discovered: Array = main.expedition.discovered.duplicate()
	view.set_players(players)
	await process_frame
	check(view.player_markers.size()==4,"Co-located players missing")
	var markers: Array = view.player_markers.values()
	for i in range(markers.size()):
		for j in range(i+1,markers.size()):
			check(not markers[i].get_rect().intersects(markers[j].get_rect()),"Party portraits overlap")
	main.footer.text = "4인 위치 표시 검수 · 네트워크 연결 아님"
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/map-party-position-preview.png")
	players[1].node_id = main.expedition.available()[0]
	players[2].node_id = main.expedition.nodes.size()-1
	players.append({"player_id":"bad","character_id":"mira","node_id":-1})
	view.set_players(players)
	await process_frame
	check(view.player_markers.size()==3,"Hidden or invalid player location leaked")
	check(view.player_markers["2"].get_meta("node_id")==players[1].node_id,"Separate player position lost")
	check(view.player_markers["4"].player_label=="P4","Hidden peer renumbered player slots")
	check(main.expedition.discovered==discovered,"Party marker revealed map")
	check(view.buttons.size()==main.expedition.visible().size(),"Party markers changed path controls")
	view.set_players([])
	await process_frame
	check(view.player_markers.is_empty(),"Stale player markers after removal")
	print("MAP_PLAYERS_QA solo=4 party=4 failures=",failures.size())
	main.queue_free()
	await process_frame
	await process_frame
	quit(0 if failures.is_empty() else 1)

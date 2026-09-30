extends Control
signal node_selected(id: int)
const Graph = preload("res://scripts/expedition_map.gd")
const PAPER = preload("res://assets/map/expedition-parchment-v2.png")
const ICONS := {"출발": "camp", "전투": "battle", "엘리트": "elite", "보스": "boss", "상점": "shop", "휴식": "rest", "보물": "treasure", "이벤트": "event"}
var graph: RefCounted
const Assets = preload("res://scripts/character_assets.gd")
const PlayerMarker = preload("res://scripts/map_player_marker.gd")
var player_markers: Dictionary = {}
var marker_groups: Dictionary = {}
var current_caption: Label
var full_map := false
var shown: Array[int] = []
var buttons: Dictionary = {}
const STEP := 138.0
const TOP := 120.0
const HEIGHT := 1770.0

func setup(model: RefCounted, reveal_all: bool, players: Array = []) -> void:
	graph = model
	full_map = reveal_all
	shown = graph.visible(full_map)
	custom_minimum_size = Vector2(780, HEIGHT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_PASS
	for id in shown:
		var node: Dictionary = graph.nodes[id]
		var button := preload("res://scripts/map_node.gd").new()
		button.name = "Node_%d" % id
		button.text = ""
		button.icon = load("res://assets/map/icons/%s.png" % ICONS[node.type])
		button.expand_icon = true
		button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		button.add_theme_constant_override("icon_max_width", 56)
		button.add_theme_color_override("icon_normal_color", Color.WHITE)
		button.add_theme_color_override("icon_hover_color", Color.WHITE)
		button.add_theme_color_override("icon_pressed_color", Color.WHITE)
		button.add_theme_color_override("icon_disabled_color", Color(0.82, 0.79, 0.76, 1))
		button.add_theme_font_size_override("font_size", 16)
		button.size = Vector2(64, 64)
		button.disabled = not graph.available().has(id)
		button.tooltip_text = ("현재 위치 · " if id == graph.current_id else "") + node.type
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if not button.disabled else Control.CURSOR_ARROW
		for state in ["normal", "disabled", "hover", "pressed", "focus"]:
			button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		button.current_location = id == graph.current_id
		button.pressed.connect(func(): node_selected.emit(id))
		add_child(button)
		buttons[id] = button
	set_players(players)
	resized.connect(_arrange)
	_arrange()

func point(id: int) -> Vector2:
	var node: Dictionary = graph.nodes[id]
	var paper := paper_rect()
	return Vector2(paper.position.x + paper.size.x * (0.18 + float(node.lane) / 4.0 * 0.64), TOP + (Graph.ROWS - 1 - node.row) * STEP)

func paper_rect() -> Rect2:
	var ratio := float(PAPER.get_width()) / PAPER.get_height()
	var width := minf(size.x, size.y * ratio)
	return Rect2(Vector2((size.x - width) / 2, 0), Vector2(width, size.y))

func _arrange() -> void:
	if graph == null:
		return
	for id in buttons:
		buttons[id].position = point(id) - buttons[id].size / 2
	_arrange_players()
	queue_redraw()

func _draw() -> void:
	if graph == null:
		return
	draw_texture_rect(PAPER, paper_rect(), false)
	for id in shown:
		for target in graph.nodes[id].next:
			if not shown.has(target):
				continue
			var from := point(id) + Vector2(0, -34)
			var to := point(target) + Vector2(0, 34)
			var curve := Curve2D.new()
			curve.add_point(from, Vector2.ZERO, Vector2(0, -38))
			curve.add_point(to, Vector2(0, 38), Vector2.ZERO)
			var travelled: bool = graph.visited.has(id) and graph.visited.has(target)
			var distance := 0.0
			while distance < curve.get_baked_length():
				draw_circle(curve.sample_baked(distance), 1.6, Color("7c3b36") if travelled else Color("514539"), true, -1, true)
				distance += 10.0
	for node_id in marker_groups:
		var at := point(node_id)
		draw_colored_polygon(PackedVector2Array([at+Vector2(-8,-33),at+Vector2(8,-33),at+Vector2(0,-23)]),Color("e5bd72"))
	# Concealed nodes have no controls, hit targets, labels or paths in this view.
	if not full_map:
		var highest := HEIGHT
		for id in shown:
			highest = minf(highest, point(id).y)
		var boundary := highest - 70
		if boundary > 0:
			for layer in range(12):
				var fog := PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0)])
				for x in range(int(size.x), -13, -12):
					fog.append(Vector2(maxi(0, x), boundary + 25 - layer * 5 + sin(x * .018) * 9 + cos(x * .043) * 5))
				draw_colored_polygon(fog, Color(0.04, 0.025, 0.055, 0.2 if layer < 11 else 1.0))

## Each entry: player_id, character_id, node_id, display_name, color, is_local.
## Presentation only: movement authority/visibility always stays with the graph.
func set_players(players: Array) -> void:
	for marker in player_markers.values():
		remove_child(marker)
		marker.queue_free()
	player_markers.clear()
	marker_groups.clear()
	if is_instance_valid(current_caption):
		remove_child(current_caption)
		current_caption.queue_free()
	current_caption = null
	if graph == null:
		return
	for player in players:
		var id := str(player.get("player_id", ""))
		var node_id := int(player.get("node_id", graph.current_id))
		if id.is_empty() or player_markers.has(id) or not shown.has(node_id):
			continue
		var profile := Assets.profile(str(player.get("character_id", "")))
		var path: String = profile.get("map_portrait", "")
		if path.is_empty() or not ResourceLoader.exists(path):
			continue
		var marker := PlayerMarker.new()
		marker.name = "Player_" + id.validate_node_name()
		marker.set_meta("node_id",node_id)
		marker.set_meta("is_local",bool(player.get("is_local",false)))
		marker.setup(load(path),Color.from_string(str(player.get("color","e5bd72")),Color("e5bd72")),"P"+str(int(player.get("slot",players.find(player)+1))) if players.size()>1 else "",bool(player.get("is_local",false)))
		add_child(marker)
		player_markers[id] = marker
		if not marker_groups.has(node_id):
			marker_groups[node_id] = []
		marker_groups[node_id].append(marker)
	current_caption = Label.new()
	current_caption.text = "현재 위치" if player_markers.size()==1 else "내 위치"
	current_caption.add_theme_font_size_override("font_size",17)
	current_caption.add_theme_color_override("font_color",Color("fff0cb"))
	current_caption.add_theme_color_override("font_outline_color",Color("231225"))
	current_caption.add_theme_constant_override("outline_size",6)
	current_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	current_caption.visible = false
	add_child(current_caption)
	_arrange_players()
	queue_redraw()

func _arrange_players() -> void:
	for node_id in marker_groups:
		var group: Array = marker_groups[node_id]
		var span := group.size()*74.0-6.0
		var origin := point(node_id)+Vector2(-span/2.0,-105)
		origin.x = clampf(origin.x,4,maxf(4,size.x-span-4))
		for index in range(group.size()):
			var marker: Control = group[index]
			marker.position = origin+Vector2(index*74,0)
			if marker.get_meta("is_local") and is_instance_valid(current_caption):
				current_caption.visible = true
				current_caption.text = "원정대 위치" if group.size()>1 else "현재 위치"
				current_caption.position = origin+Vector2(span+9,21)
				if current_caption.position.x+100>size.x:
					current_caption.position.x = origin.x-105

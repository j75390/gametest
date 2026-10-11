extends Control
## Campfire rest stop: the hero sits by an animated fire and picks "rest" or "upgrade" from two big panels.
## Pure view: main.gd owns hp and the deck and applies the choice when `rested` / `upgraded` fire.
signal rested
signal upgraded(deck_index: int)

const Data = preload("res://scripts/game_data.gd")
const UiFont = preload("res://scripts/ui_font.gd")
const BattleCard = preload("res://scripts/battle_card.gd")
const CharacterAssets = preload("res://scripts/character_assets.gd")
const BACKGROUND := "res://assets/backgrounds/battle_cathedral_v1.png"
const CAMPFIRE_ART := "res://assets/rest/campfire_scene_v2.png"
const GOLD := Color("d8b47a")
const FIRE := Vector2(720, 608)
const MAX_PARTY := 4

var canvas := Control.new()
var deck: Array = []
var char_id := "mira"
var party_ids: Array[String] = []
var seated: Array = []  # [{view, frames, clock, index}] one entry per party member
var rest_amount := 0
var hp := 0
var max_hp := 0
var upgradable: Array[int] = []
var glow: TextureRect
var warm: Array[CanvasItem] = []
var speech: Label
var picker: Control
var preview_holder: Control
var preview_text: Label
var busy := false
var flare := 0.0
var clock := 0.0

func setup(info: Dictionary, deck_ref: Array) -> void:
	name = "RestView"
	char_id = str(info.get("character", "mira"))
	for id in info.get("party", [char_id]):
		if party_ids.size() < MAX_PARTY: party_ids.append(str(id))
	if party_ids.is_empty(): party_ids.append(char_id)
	rest_amount = int(info.get("rest_amount", 0))
	hp = int(info.get("hp", 0))
	max_hp = int(info.get("max_hp", 1))
	deck = deck_ref
	for i in range(deck.size()):
		if not deck[i].get("upgraded", false): upgradable.append(i)

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := ColorRect.new()
	backdrop.color = Color("070509")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	add_child(canvas)
	canvas.size = Vector2(1440, 900)
	_build_scene()
	_build_hud()
	_build_options()
	resized.connect(_fit)
	_fit()
	say("불씨가 아직 살아 있어. 잠깐 쉬어 가자.")

func _fit() -> void:
	var ratio := minf(size.x / 1440.0, size.y / 900.0)
	canvas.scale = Vector2.ONE * ratio
	canvas.position = (size - Vector2(1440, 900) * ratio) / 2.0

func _process(delta: float) -> void:
	clock += delta
	flare = maxf(0.0, flare - delta * 1.6)
	var flicker := 0.82 + 0.10 * sin(clock * 9.0) + 0.06 * sin(clock * 17.3 + 1.0) + flare
	if glow != null:
		glow.modulate.a = clampf(flicker, 0.0, 1.4)
		glow.scale = Vector2.ONE * (1.0 + 0.05 * sin(clock * 6.0) + flare * 0.25)
	for item in warm:
		item.modulate = Color(0.78 + 0.22 * flicker, 0.70 + 0.16 * flicker, 0.66 + 0.10 * flicker)
	flame_clock += delta
	if flame_clock > 0.11 and not flame_frames.is_empty():
		flame_clock = 0.0
		flame_index = (flame_index + 1) % flame_frames.size()
		flame_view.texture = flame_frames[flame_index]
		flame_view.scale = Vector2.ONE * (1.0 + flare * 0.35)
	spark_clock += delta
	if spark_clock > 0.22 - minf(flare, 1.0) * 0.17:
		spark_clock = 0.0
		_spawn_spark()
	for member in seated:
		var frames: Array = member.frames
		if frames.size() < 2: continue
		member.clock += delta
		if member.clock >= frames[member.index].duration:
			member.clock = 0.0
			member.index = (member.index + 1) % frames.size()
			member.view.texture = frames[member.index].texture

# ------------------------------------------------------------------ scene (pixel art, drawn in code)

const PIXEL := 4
const GROUND_Y := 140
const FIRE_PX := Vector2i(240, 150)
const SEATED_SCALE := 3.0
const FLAME_DIR := "res://assets/rest/"

func _build_scene() -> void:
	var backdrop := TextureRect.new()
	backdrop.name = "PixelBackdrop"
	backdrop.texture = load(CAMPFIRE_ART) if ResourceLoader.exists(CAMPFIRE_ART) else _pixel_backdrop()
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_SCALE
	backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	backdrop.size = Vector2(1440, 900)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(backdrop)
	glow = TextureRect.new()
	glow.name = "FireGlow"
	glow.texture = _radial(Color(1.0, 0.55, 0.2, 0.30), Color(1.0, 0.35, 0.1, 0.0), 1.0)
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.size = Vector2(900, 700)
	glow.position = FIRE - glow.size / 2 + Vector2(0, -90)
	glow.pivot_offset = glow.size / 2
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = additive
	canvas.add_child(glow)
	_build_party(true)
	_build_flame()
	_build_party(false)

## 360x225 low-res picture scaled 4x with nearest filtering: night sky, ruined arches, a stone floor and the firelit ring.
func _pixel_backdrop() -> ImageTexture:
	var w := 360
	var h := 225
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var top := Color("0f0820")
	var bottom := Color("33204f")
	for y in range(GROUND_Y):
		var band := floorf(float(y) / GROUND_Y * 7.0) / 7.0
		for x in range(w): img.set_pixel(x, y, top.lerp(bottom, band))
	for i in range(55):
		var star := Color("e9ddff") if rng.randf() < 0.3 else Color("8d7ab8")
		img.set_pixel(rng.randi_range(0, w - 1), rng.randi_range(2, 100), star)
	_disc(img, Vector2i(117, 34), 11, Color("e6dcff"))
	_disc(img, Vector2i(121, 31), 10, Color("241640"))
	var ruin := Color("0b0614")
	var rim := Color("1d1230")
	for arch in [[58, 44, 58], [172, 40, 66], [300, 46, 50]]:
		var cx: int = arch[0]
		var half: int = arch[1]
		var base: int = arch[2]
		for x in range(cx - half, cx + half + 1):
			for y in range(GROUND_Y - 112, GROUND_Y):
				if x >= 0 and x < w: img.set_pixel(x, y, ruin)
		var inner := half - 9
		for x in range(cx - inner, cx + inner + 1):
			var edge := float(absi(x - cx)) / float(inner)
			var arch_top := int(GROUND_Y - 112 + 18 + edge * edge * 52.0)
			for y in range(arch_top, GROUND_Y):
				if x >= 0 and x < w: img.set_pixel(x, y, top.lerp(bottom, float(y) / GROUND_Y * 0.9))
		for y in range(GROUND_Y - 112, GROUND_Y, 14):
			for x in range(cx - half, cx - inner): img.set_pixel(clampi(x, 0, w - 1), y, rim)
			for x in range(cx + inner, cx + half + 1): img.set_pixel(clampi(x, 0, w - 1), y, rim)
		for x in [cx - 2, cx + 1]:
			for y in range(base - 8, base + 6): img.set_pixel(clampi(x, 0, w - 1), y, Color("6a43a8") if y % 3 != 0 else Color("3b2468"))
	var floor_a := Color("241833")
	var floor_b := Color("1b1226")
	for y in range(GROUND_Y, h):
		for x in range(w):
			var tile := ((x + (y / 14) * 9) / 22 + y / 14) % 2
			img.set_pixel(x, y, floor_a if tile == 0 else floor_b)
		if (y - GROUND_Y) % 14 == 0:
			for x in range(w): img.set_pixel(x, y, Color("120b1c"))
	var warm_tint := Color("ff9a3c")
	for y in range(GROUND_Y - 30, h):
		for x in range(w):
			var d := Vector2(float(x - FIRE_PX.x) / 1.7, float(y - FIRE_PX.y)).length()
			var strength := 0.0
			if d < 24: strength = 0.42
			elif d < 40: strength = 0.26
			elif d < 58: strength = 0.14
			elif d < 78: strength = 0.06
			if strength > 0.0 and (x + y) % 2 == 0 and d > 20: strength *= 0.55
			if strength > 0.0: img.set_pixel(x, y, img.get_pixel(x, y).lerp(warm_tint, strength))
	for i in range(11):
		var angle := PI + float(i) * PI / 10.0 * 2.0
		var stone := Vector2i(FIRE_PX.x + int(cos(angle) * 21.0), FIRE_PX.y + 7 + int(sin(angle) * 7.0))
		_disc(img, stone, 3, Color("4a4358") if i % 2 == 0 else Color("39334a"))
		img.set_pixel(stone.x - 1, stone.y - 2, Color("6d6580"))
	for spec in [[-10, 5, -22.0], [10, 5, 22.0]]:
		for step in range(-14, 15):
			var px: int = FIRE_PX.x + spec[0] + step
			var py: int = FIRE_PX.y + spec[1] + int(float(step) * tan(deg_to_rad(spec[2])) * 0.35)
			for t in range(-2, 3):
				img.set_pixel(clampi(px, 0, w - 1), clampi(py + t, 0, h - 1), Color("5b3820") if t < 1 else Color("3a2214"))
		_disc(img, Vector2i(FIRE_PX.x + spec[0] + (14 if spec[2] > 0 else -14), FIRE_PX.y + spec[1] + int(14.0 * absf(tan(deg_to_rad(spec[2]))) * 0.35 * (1 if spec[2] > 0 else -1))), 3, Color("c98a4a"))
	for i in range(12):
		img.set_pixel(FIRE_PX.x + rng.randi_range(-12, 12), FIRE_PX.y + rng.randi_range(2, 8), Color("ff7a24") if i % 2 == 0 else Color("ffc65a"))
	return ImageTexture.create_from_image(img)

func _disc(img: Image, center: Vector2i, radius: int, color: Color) -> void:
	for y in range(-radius, radius + 1):
		for x in range(-radius, radius + 1):
			if x * x + y * y > radius * radius: continue
			var p := center + Vector2i(x, y)
			if p.x >= 0 and p.y >= 0 and p.x < img.get_width() and p.y < img.get_height(): img.set_pixel(p.x, p.y, color)

var flame_frames: Array[Texture2D] = []
var flame_view: TextureRect
var flame_clock := 0.0
var flame_index := 0
var spark_clock := 0.0

## Seats around the fire for 1..4 party members: {x offset from the fire, back row?, faces left?}.
## One member sits left of the fire; more fill the right side, then a back row behind the flames.
const SEATS := {
	1: [[-275.0, false, false]],
	2: [[-275.0, false, false], [275.0, false, true]],
	3: [[-290.0, false, false], [290.0, false, true], [125.0, true, true]],
	4: [[-300.0, false, false], [300.0, false, true], [-115.0, true, false], [115.0, true, true]],
}

## Draws the back row (behind the fire) or the front row (beside it) of seated party members.
func _build_party(back_row: bool) -> void:
	var layout: Array = SEATS[party_ids.size()]
	for i in range(party_ids.size()):
		var seat: Array = layout[i]
		if bool(seat[1]) != back_row: continue
		_seat_member(party_ids[i], FIRE.x + float(seat[0]), bool(seat[1]), bool(seat[2]), i)

func _seat_member(id: String, x: float, back: bool, face_left: bool, order: int) -> void:
	var profile: Dictionary = CharacterAssets.profile(id)
	var seated_art: Array = profile.get("rest_frames", [])
	var motions: Array = seated_art if not seated_art.is_empty() else profile.get("pixel_motions_backup", profile.get("motions", {})).get("idle", [])
	var frames: Array = []
	for item in motions:
		var texture := load(str(item.path)) as Texture2D
		if texture == null: continue
		var img := texture.get_image()
		# a big painted sprite is shrunk with the nearest filter so it reads as chunky pixels
		if img.get_width() > 600: img.resize(int(img.get_width() / 3.0), int(img.get_height() / 3.0), Image.INTERPOLATE_NEAREST)
		frames.append({"texture": ImageTexture.create_from_image(img), "duration": float(item.get("duration", 0.2))})
	if frames.is_empty():
		# no motion set yet: the standing full-body picture stands in until that character gets seated art
		var full := CharacterAssets.picture(id, "full")
		if full == null: return
		var still := full.get_image()
		still.resize(int(still.get_width() / 3.0), int(still.get_height() / 3.0), Image.INTERPOLATE_NEAREST)
		frames.append({"texture": ImageTexture.create_from_image(still), "duration": 1.0})
	var first: Texture2D = frames[0].texture
	var crowd := party_ids.size() >= 3
	var shown := 1.0
	var feet_pad := 0.0
	if not seated_art.is_empty():
		shown = (2.5 if crowd else SEATED_SCALE)
	else:
		# characters without seated art keep their standing sprite, sized to the same height as a seated one
		shown = (2.0 if first.get_width() == 320 else clampf(300.0 / float(first.get_height()), 0.4, 1.0))
		if first.get_width() == 320: feet_pad = 24.0
	if back: shown *= 0.85
	var view := TextureRect.new()
	view.name = "RestHero_%s" % id
	view.texture = first
	view.flip_h = face_left
	view.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	view.size = first.get_size() * shown
	var ground := GROUND_Y * PIXEL + 70 + feet_pad - (58.0 if back else 0.0)
	view.position = Vector2(x, ground) - Vector2(view.size.x / 2, view.size.y)
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(view)
	warm.append(view)
	var hop := create_tween().set_loops()
	hop.tween_property(view, "position:y", view.position.y - 4.0, 1.2 + 0.15 * order).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	hop.tween_property(view, "position:y", view.position.y, 1.2 + 0.15 * order).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# stagger the doze cycle so everyone does not nod off on the same beat
	seated.append({"view": view, "frames": frames, "clock": 0.6 * float(order), "index": order % frames.size()})
	view.texture = frames[order % frames.size()].texture

## Four hand-built pixel flames (28x40) played in a loop, plus rising square sparks.
func _build_flame() -> void:
	for frame in range(4):
		var delivered := "%sflame_%d.png" % [FLAME_DIR, frame + 1]
		if ResourceLoader.exists(delivered): flame_frames.append(load(delivered))
		else: flame_frames.append(ImageTexture.create_from_image(_flame_image(frame)))
	var logs_path := FLAME_DIR + "campfire_logs_v1.png"
	if ResourceLoader.exists(logs_path):
		var logs := TextureRect.new()
		logs.name = "CampfireLogs"
		logs.texture = load(logs_path)
		logs.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		logs.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		logs.size = Vector2(64, 24) * 4.0
		logs.position = Vector2(FIRE.x - logs.size.x / 2, FIRE.y - logs.size.y + 22)
		logs.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(logs)
	flame_view = TextureRect.new()
	flame_view.name = "Flame"
	flame_view.texture = flame_frames[0]
	flame_view.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	flame_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	flame_view.stretch_mode = TextureRect.STRETCH_SCALE
	flame_view.size = Vector2(28, 40) * 6.0
	flame_view.pivot_offset = Vector2(flame_view.size.x / 2, flame_view.size.y)
	flame_view.position = Vector2(FIRE.x - flame_view.size.x / 2, FIRE.y + 4 - flame_view.size.y)
	flame_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(flame_view)

func _flame_image(frame: int) -> Image:
	var img := Image.create(28, 40, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 100 + frame
	var sway: int = [0, 1, 0, -1][frame]
	for y in range(40):
		var t := float(y) / 39.0
		var half := 12.0 * pow(t, 0.75) * (1.0 - 0.08 * t)
		var shift: int = int(round(sin(float(y) * 0.35 + float(frame) * 1.6) * 2.5 * (1.0 - t))) + (sway if t < 0.5 else 0)
		var jitter := rng.randi_range(-1, 1)
		var lo: int = 14 + shift - int(half) + jitter
		var hi: int = 14 + shift + int(half) - jitter
		for x in range(maxi(0, lo), mini(27, hi) + 1):
			var d := absf(float(x - (14 + shift))) / maxf(1.0, half)
			var color := Color("d9381a")
			if t < 0.2: color = Color("b02a1c")
			elif d < 0.34 and t > 0.42: color = Color("fff1a6")
			elif d < 0.62 and t > 0.28: color = Color("ffbd32")
			elif d < 0.85: color = Color("f2701c")
			img.set_pixel(x, y, color)
	# a small second tongue that jumps between frames
	var tongue_x: int = [8, 19, 11, 17][frame]
	for y in range(6, 22):
		for x in range(tongue_x - 1, tongue_x + 2 - (y - 6) / 9):
			if img.get_pixel(x, y).a == 0.0: img.set_pixel(x, y, Color("f2701c") if y > 12 else Color("ffbd32"))
	return img

func _spawn_spark() -> void:
	var spark := ColorRect.new()
	var size_px := PIXEL * (1 + randi() % 2)
	spark.size = Vector2(size_px, size_px)
	spark.color = [Color("ffe08a"), Color("ff9a3c"), Color("ff6a28")].pick_random()
	spark.position = FIRE + Vector2(randf_range(-26, 26), -randf_range(40, 120))
	spark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(spark)
	var rise := randf_range(110, 220)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(spark, "position:y", spark.position.y - rise, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(spark, "position:x", spark.position.x + randf_range(-60, 60), 1.6)
	tween.tween_property(spark, "modulate:a", 0.0, 0.7).set_delay(0.9)
	tween.chain().tween_callback(spark.queue_free)

func _radial(inner: Color, outer: Color, reach: float) -> GradientTexture2D:
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([inner, outer])
	var texture := GradientTexture2D.new()
	texture.gradient = ramp
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5 + 0.5 * reach, 0.5)
	texture.width = 256
	texture.height = 256
	return texture

# ------------------------------------------------------------------ HUD, bubble and options

func _label(value: String, rect: Rect2, font_size: int, tint: Color, parent: Control, align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var item := Label.new()
	item.text = value
	item.position = rect.position
	item.size = rect.size
	item.horizontal_alignment = align
	item.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.add_theme_font_size_override("font_size", font_size)
	item.add_theme_font_override("font", UiFont.serif())
	item.add_theme_color_override("font_color", tint)
	item.add_theme_color_override("font_outline_color", Color("120a18"))
	item.add_theme_constant_override("outline_size", 5)
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(item)
	return item

func _box(fill: Color, border: Color, radius := 14, width := 2) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(radius)
	return box

func _build_hud() -> void:
	_label("야영지", Rect2(0, 28, 1440, 60), 46, Color("e8c171"), canvas)
	_label("꺼지지 않는 불 곁에서 숨을 고른다", Rect2(0, 86, 1440, 34), 22, Color("c9b8d6"), canvas)
	var plate := Panel.new()
	plate.name = "RestHp"
	plate.position = Vector2(24, 24)
	plate.size = Vector2(250, 56)
	plate.add_theme_stylebox_override("panel", _box(Color(0.08, 0.05, 0.11, 0.85), Color("ad8953"), 12))
	canvas.add_child(plate)
	_label("HP  %d / %d" % [hp, max_hp], Rect2(0, 0, 250, 56), 28, Color("f0707e"), plate)
	var bubble := Panel.new()
	bubble.name = "RestBubble"
	bubble.position = Vector2(290, 150)
	bubble.size = Vector2(420, 70)
	bubble.add_theme_stylebox_override("panel", _box(Color(0.10, 0.07, 0.15, 0.92), Color("bba0d1"), 14))
	canvas.add_child(bubble)
	speech = _label("", Rect2(14, 4, 392, 62), 21, Color("f1e6d6"), bubble)

func say(line: String) -> void:
	if is_instance_valid(speech): speech.text = line

func _build_options() -> void:
	var healed := mini(max_hp, hp + rest_amount)
	_option("Rest", Rect2(430, 712, 280, 150), "res://assets/rest/icon_rest_v1.png", "휴식",
		"HP를 %d 회복합니다.\n%d → %d" % [healed - hp, hp, healed], "몸을 누이고 상처를 돌본다. 한숨 자면 한결 나아질 거야.", true, _choose_rest)
	var can_upgrade := not upgradable.is_empty()
	_option("Upgrade", Rect2(730, 712, 280, 150), "res://assets/rest/icon_upgrade_v1.png", "강화",
		("카드 1장을 강화합니다.\n(강화 가능 %d장)" % upgradable.size()) if can_upgrade else "강화할 카드가 없습니다.", "도구를 손보듯 카드를 다듬는다. 어느 쪽을 벼릴까.", can_upgrade, _open_picker)

func _option(id: String, rect: Rect2, icon_path: String, heading: String, body: String, line: String, enabled: bool, action: Callable) -> void:
	var panel := Panel.new()
	panel.name = "Option" + id
	panel.position = rect.position
	panel.size = rect.size
	panel.pivot_offset = rect.size / 2
	var border := Color("ad8953") if enabled else Color(0.4, 0.35, 0.3, 0.6)
	panel.add_theme_stylebox_override("panel", _box(Color(0.10, 0.07, 0.14, 0.94), border, 16, 3))
	canvas.add_child(panel)
	if ResourceLoader.exists(icon_path):
		var icon := TextureRect.new()
		icon.texture = load(icon_path)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		icon.position = Vector2(18, 16)
		icon.size = Vector2(58, 58)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.modulate = Color.WHITE if enabled else Color(1, 1, 1, 0.4)
		panel.add_child(icon)
	_label(heading, Rect2(86, 14, 180, 60), 34, GOLD if enabled else Color("8a7d70"), panel, HORIZONTAL_ALIGNMENT_LEFT)
	_label(body, Rect2(18, 78, 244, 66), 20, Color("e7dccd") if enabled else Color("8a7d70"), panel, HORIZONTAL_ALIGNMENT_LEFT)
	if not enabled: return
	var hit := Button.new()
	hit.name = "Hit"
	hit.size = rect.size
	hit.focus_mode = Control.FOCUS_NONE
	var clear := StyleBoxEmpty.new()
	for state in ["normal", "pressed", "disabled", "focus", "hover"]:
		hit.add_theme_stylebox_override(state, clear)
	panel.add_child(hit)
	hit.mouse_entered.connect(func():
		if busy: return
		say(line)
		panel.add_theme_stylebox_override("panel", _box(Color(0.17, 0.11, 0.22, 0.97), Color("f2cf72"), 16, 4))
		create_tween().tween_property(panel, "scale", Vector2.ONE * 1.05, 0.12))
	hit.mouse_exited.connect(func():
		panel.add_theme_stylebox_override("panel", _box(Color(0.10, 0.07, 0.14, 0.94), border, 16, 3))
		create_tween().tween_property(panel, "scale", Vector2.ONE, 0.12))
	hit.pressed.connect(func():
		if not busy: action.call())

# ------------------------------------------------------------------ choices

func _choose_rest() -> void:
	busy = true
	flare = 1.2
	say("…따뜻하다. 상처가 천천히 아문다.")
	_float(Vector2(340, 250), "HP +%d" % (mini(max_hp, hp + rest_amount) - hp), Color("8cedb0"))
	get_tree().create_timer(1.3).timeout.connect(func(): rested.emit())

func _float(at: Vector2, value: String, tint: Color) -> void:
	var item := _label(value, Rect2(at, Vector2(320, 60)), 42, tint, canvas)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(item, "position:y", at.y - 90, 1.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(item, "modulate:a", 0.0, 0.4).set_delay(0.8)

func _open_picker() -> void:
	if is_instance_valid(picker) or upgradable.is_empty(): return
	picker = Control.new()
	picker.name = "UpgradePicker"
	picker.size = Vector2(1440, 900)
	canvas.add_child(picker)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.05, 0.94)
	dim.size = Vector2(1440, 900)
	picker.add_child(dim)
	_label("강화할 카드를 고르세요", Rect2(0, 20, 1440, 50), 34, GOLD, picker)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(40, 84)
	scroll.size = Vector2(900, 700)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	picker.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)
	var scale := 0.62
	for index in upgradable:
		var cell := Control.new()
		cell.custom_minimum_size = BattleCard.CARD_SIZE * scale
		grid.add_child(cell)
		var view := BattleCard.new()
		view.setup(deck[index])
		view.scale = Vector2.ONE * scale
		view.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(view)
		var hit := Button.new()
		hit.size = cell.custom_minimum_size
		hit.focus_mode = Control.FOCUS_NONE
		var hover := _box(Color(0.6, 0.45, 0.8, 0.12), Color("f2cf72"), 10, 3)
		var clear := StyleBoxEmpty.new()
		for state in ["normal", "pressed", "disabled", "focus"]:
			hit.add_theme_stylebox_override(state, clear)
		hit.add_theme_stylebox_override("hover", hover)
		cell.add_child(hit)
		hit.mouse_entered.connect(func(): _preview(index))
		hit.pressed.connect(func(): _pick_upgrade(index))
	var side := Panel.new()
	side.position = Vector2(980, 90)
	side.size = Vector2(420, 690)
	side.add_theme_stylebox_override("panel", _box(Color(0.08, 0.06, 0.12, 0.9), Color("ad8953"), 16, 2))
	picker.add_child(side)
	_label("강화 후", Rect2(0, 12, 420, 40), 28, GOLD, side)
	preview_holder = Control.new()
	preview_holder.position = Vector2(100, 62)
	side.add_child(preview_holder)
	preview_text = _label("카드 위에 마우스를 올리면\n강화된 모습을 볼 수 있습니다.", Rect2(20, 420, 380, 250), 22, Color("e7dccd"), side)
	var cancel := Button.new()
	cancel.text = "취소"
	cancel.position = Vector2(570, 806)
	cancel.size = Vector2(300, 60)
	cancel.add_theme_font_size_override("font_size", 24)
	cancel.add_theme_font_override("font", UiFont.serif())
	cancel.pressed.connect(func():
		picker.queue_free()
		picker = null)
	picker.add_child(cancel)
	_preview(upgradable[0])

func _preview(index: int) -> void:
	for child in preview_holder.get_children(): child.queue_free()
	var after := Data.upgraded(deck[index])
	var view := BattleCard.new()
	view.setup(after)
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_holder.add_child(view)
	preview_text.text = "%s\n%s\n↓\n%s" % [deck[index].name, Data.effect_text(deck[index]), Data.effect_text(after)]

func _pick_upgrade(index: int) -> void:
	busy = true
	if is_instance_valid(picker):
		picker.queue_free()
		picker = null
	flare = 1.4
	say("불꽃이 카드를 달군다… 한층 단단해졌어.")
	var after := Data.upgraded(deck[index])
	var view := BattleCard.new()
	view.setup(after)
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.position = Vector2(FIRE.x - 110, 130)
	view.modulate.a = 0.0
	view.scale = Vector2.ONE * 0.8
	canvas.add_child(view)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(view, "modulate:a", 1.0, 0.35)
	tween.tween_property(view, "scale", Vector2.ONE * 1.1, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_float(Vector2(FIRE.x - 160, 96), "강화!", Color("f2cf72"))
	get_tree().create_timer(1.5).timeout.connect(func(): upgraded.emit(index))

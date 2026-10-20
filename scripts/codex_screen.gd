extends Control
## Shared shell for the codex hub and its sub-screens: dark backdrop, a 1440x900 canvas that scales
## to any window, a back button, and small drawing helpers. Sub-screens override build().
signal closed

const UiFont = preload("res://scripts/ui_font.gd")
const CardView = preload("res://scripts/battle_card.gd")
const GOLD := Color("d8b47a")
const INK := Color("0b080f")
const MUTED := Color("a99ea9")
const PARCHMENT := Color("e6d8c4")
const PANEL := Color("17121d")
const EDGE := Color("5b4a3a")
const HIDDEN_BLUR := """shader_type canvas_item;
uniform float radius = 0.045;
void fragment() {
	vec4 sum = vec4(0.0);
	for (int x = -3; x <= 3; x++) {
		for (int y = -3; y <= 3; y++) {
			sum += texture(TEXTURE, UV + vec2(float(x), float(y)) * radius / 3.0);
		}
	}
	COLOR = vec4((sum / 49.0).rgb * vec3(0.72, 0.68, 0.85), 1.0) * COLOR;
}"""

var canvas := Control.new()
var story_flags: Dictionary = {}
var card_character := ""
var popup: Control
var _blur_material: ShaderMaterial
var _tint_materials := {}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var base := ColorRect.new()
	base.color = INK
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(base)
	var backdrop := TextureRect.new()
	backdrop.texture = load("res://assets/backgrounds/selection_ruins_v2.png")
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.modulate = Color(0.24, 0.22, 0.28, 0.4)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	add_child(canvas)
	canvas.size = Vector2(1440, 900)
	resized.connect(_fit)
	_fit()
	build()
	_add_back_button()

func build() -> void:
	pass

func _fit() -> void:
	var ratio := minf(size.x / 1440.0, size.y / 900.0)
	canvas.scale = Vector2.ONE * ratio
	canvas.position = (size - Vector2(1440, 900) * ratio) * 0.5

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		if is_instance_valid(popup): close_popup()
		else: closed.emit()

func _add_back_button() -> void:
	var back := Button.new()
	back.name = "BackButton"
	back.text = "◀  돌아가기"
	back.position = Vector2(0, 806)
	back.size = Vector2(190, 52)
	back.add_theme_font_size_override("font_size", 22)
	back.add_theme_font_override("font", UiFont.serif())
	back.add_theme_color_override("font_color", PARCHMENT)
	var normal := box(Color("5a1f27"), Color("a85a4a"), 2, 0)
	normal.corner_radius_top_right = 14
	normal.corner_radius_bottom_right = 14
	var hover := box(Color("7a2a35"), GOLD, 2, 0)
	hover.corner_radius_top_right = 14
	hover.corner_radius_bottom_right = 14
	back.add_theme_stylebox_override("normal", normal)
	back.add_theme_stylebox_override("hover", hover)
	back.add_theme_stylebox_override("pressed", hover)
	back.add_theme_stylebox_override("focus", hover)
	back.pressed.connect(func(): closed.emit())
	canvas.add_child(back)

## Flat rounded box with an optional border.
func box(fill: Color, border: Color = Color.TRANSPARENT, width: int = 0, radius: int = 10) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	return style

func make_panel(parent: Node, rect: Rect2, fill: Color = Color(0.09, 0.07, 0.12, 0.94), border: Color = EDGE, radius: int = 12) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.add_theme_stylebox_override("panel", box(fill, border, 2, radius))
	parent.add_child(panel)
	return panel

func make_label(parent: Node, value: String, rect: Rect2, font_size: int = 20, tint: Color = PARCHMENT, bold: bool = false, align: int = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var item := Label.new()
	# Wrap mode and width must be fixed before the text is set, or the label grows to one long line.
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.custom_minimum_size = Vector2(rect.size.x, 0)
	item.text = value
	item.position = rect.position
	item.size = rect.size
	item.horizontal_alignment = align
	item.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	item.add_theme_font_size_override("font_size", font_size)
	item.add_theme_font_override("font", UiFont.serif(bold))
	item.add_theme_color_override("font_color", tint)
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(item)
	return item

func make_texture(parent: Node, path: String, rect: Rect2, mode: int = TextureRect.STRETCH_KEEP_ASPECT_COVERED) -> TextureRect:
	var pic := TextureRect.new()
	if ResourceLoader.exists(path): pic.texture = load(path)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = mode
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	pic.position = rect.position
	pic.size = rect.size
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(pic)
	return pic

## Transparent click area that draws a border on hover/focus.
func click_area(parent: Node, rect: Rect2, radius: int = 12) -> Button:
	var item := Button.new()
	item.position = rect.position
	item.size = rect.size
	item.focus_mode = Control.FOCUS_ALL
	var hover := box(Color(0.6, 0.45, 0.8, 0.1), Color("bba0d1"), 3, radius)
	var clear := StyleBoxEmpty.new()
	for state in ["normal", "pressed", "disabled"]:
		item.add_theme_stylebox_override(state, clear)
	item.add_theme_stylebox_override("hover", hover)
	item.add_theme_stylebox_override("focus", hover)
	parent.add_child(item)
	return item

## Modal layer over the screen. Returns the inner area to fill; clicking outside or pressing Esc closes it.
func open_popup(size_px: Vector2) -> Control:
	close_popup()
	popup = Control.new()
	popup.size = Vector2(1440, 900)
	canvas.add_child(popup)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.05, 0.88)
	dim.size = Vector2(1440, 900)
	popup.add_child(dim)
	var outside := click_area(popup, Rect2(Vector2.ZERO, Vector2(1440, 900)), 0)
	outside.pressed.connect(close_popup)
	var inner := make_panel(popup, Rect2((Vector2(1440, 900) - size_px) * 0.5, size_px), Color(0.1, 0.08, 0.14, 0.98), GOLD, 14)
	var shield := Button.new()
	shield.flat = true
	shield.focus_mode = Control.FOCUS_NONE
	shield.size = size_px
	shield.mouse_default_cursor_shape = Control.CURSOR_ARROW
	inner.add_child(shield)
	return inner

func close_popup() -> void:
	if is_instance_valid(popup):
		popup.queue_free()
		popup = null

const FRAME_TINT := """shader_type canvas_item;
uniform float hue = 0.0;
uniform float sat = 1.0;
uniform float val = 1.0;
vec3 rgb2hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}
vec3 hsv2rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}
void fragment() {
	vec4 t = texture(TEXTURE, UV);
	vec3 h = rgb2hsv(t.rgb);
	h.x = fract(h.x + hue);
	h.y = clamp(h.y * sat, 0.0, 1.0);
	h.z = clamp(h.z * val, 0.0, 1.0);
	COLOR = vec4(hsv2rgb(h), t.a) * COLOR;
}"""
## owner -> [hue shift, saturation, value] relative to the purple Mira frame
const OWNER_TINT := {
	"mira": [0.0, 1.0, 1.0], "kalian": [0.24, 1.0, 1.0], "sera": [0.82, 0.95, 1.0], "severin": [0.24, 1.0, 1.0], "calamo": [0.5, 0.8, 1.0], "esca": [0.36, 1.0, 1.1],
	"lucian": [0.36, 0.85, 1.12], "common": [0.0, 0.12, 0.95]}

## One card as the codex shows it. `state` is found / hidden / locked; hidden and locked cards keep their
## frame but blur the art and read "미지 / ???". The frame is tinted per owner until each character
## has its own frame art.
func card_view(record: Dictionary, owner: String, state: String) -> Control:
	if _blur_material == null:
		var blur_shader := Shader.new()
		blur_shader.code = HIDDEN_BLUR
		_blur_material = ShaderMaterial.new()
		_blur_material.shader = blur_shader
		var tint_shader := Shader.new()
		tint_shader.code = FRAME_TINT
		for key in OWNER_TINT:
			var mat := ShaderMaterial.new()
			mat.shader = tint_shader
			mat.set_shader_parameter("hue", OWNER_TINT[key][0])
			mat.set_shader_parameter("sat", OWNER_TINT[key][1])
			mat.set_shader_parameter("val", OWNER_TINT[key][2])
			_tint_materials[key] = mat
	var card: Control = CardView.new()
	var def := record.duplicate(true)
	if state != "found": def["name"] = "미지"
	if str(def.get("art", "")).is_empty(): def["art"] = "res://assets/ui/selection/codex_card_back.svg"
	card.setup(def)
	var frame := card.get_node_or_null("CharacterFrame")
	if frame and _tint_materials.has(owner): frame.material = _tint_materials[owner]
	if state != "found":
		var art := card.get_node_or_null("ArtWindow/Illustration")
		if art: art.material = _blur_material
		var effect: Label = card.get("effect_label")
		if effect: effect.text = "???"
		var energy := card.get_node_or_null("Energy")
		if energy: energy.text = "?" if state == "hidden" else "—"
		if state == "locked": card.modulate = Color(0.6, 0.65, 0.72)
	return card

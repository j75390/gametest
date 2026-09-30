extends Control
## A newly generated portrait asset, framed only for player location (not map nodes).
var accent := Color("e5bd72")
var local_player := false
var player_label := ""

func setup(texture: Texture2D, color: Color, label_text: String, is_local: bool) -> void:
	accent = color
	local_player = is_local
	player_label = label_text
	size = Vector2(68,68)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var portrait := TextureRect.new()
	portrait.position = Vector2(5,5)
	portrait.size = Vector2(58,58)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	portrait.texture = texture
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; void fragment(){vec4 c=texture(TEXTURE,UV); c.a*=1.0-smoothstep(0.48,0.5,length(UV-vec2(0.5))); COLOR=c;}"
	var material := ShaderMaterial.new()
	material.shader = shader
	portrait.material = material
	add_child(portrait)
	if not player_label.is_empty():
		var label := Label.new()
		label.text = player_label
		label.position = Vector2(41,48)
		label.size = Vector2(30,22)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size",14)
		label.add_theme_color_override("font_color",Color("fff3d6"))
		label.add_theme_color_override("font_outline_color",Color("120c16"))
		label.add_theme_constant_override("outline_size",5)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(label)
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2(34,36),35,Color(0,0,0,0.65),true,-1,true)
	draw_circle(Vector2(34,34),33,accent,true,-1,true)
	draw_circle(Vector2(34,34),29.5,Color("160e20"),true,-1,true)
	if local_player:
		draw_arc(Vector2(34,34),35,-PI*0.85,PI*0.2,40,Color("fff0c2"),2,true)

extends Control
## Small padlock glyph for locked codex entries (no font dependency).
var tint := Color("8fa3ad")

func _draw() -> void:
	var w := size.x
	var h := size.y
	var body := Rect2(w * 0.2, h * 0.46, w * 0.6, h * 0.42)
	draw_arc(Vector2(w * 0.5, h * 0.46), w * 0.19, PI, TAU, 24, tint, maxf(2.0, w * 0.07))
	draw_line(Vector2(w * 0.31, h * 0.46), Vector2(w * 0.31, h * 0.52), tint, maxf(2.0, w * 0.07))
	draw_line(Vector2(w * 0.69, h * 0.46), Vector2(w * 0.69, h * 0.52), tint, maxf(2.0, w * 0.07))
	draw_rect(body, tint)
	draw_circle(Vector2(w * 0.5, h * 0.62), w * 0.065, Color("1b2226"))
	draw_rect(Rect2(w * 0.475, h * 0.62, w * 0.05, h * 0.14), Color("1b2226"))

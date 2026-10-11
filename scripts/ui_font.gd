extends RefCounted
## One serif face for HUD numbers and titles, matching the card text (battle_card.gd).
static var _cache := {}

static func serif(bold := true) -> Font:
	if _cache.has(bold): return _cache[bold]
	var base := SystemFont.new()
	base.font_names = PackedStringArray(["Batang", "Noto Serif CJK KR", "serif"])
	base.font_weight = 700 if bold else 400
	var face := FontVariation.new()
	face.base_font = base
	face.variation_embolden = 0.8 if bold else 0.3
	_cache[bold] = face
	return face

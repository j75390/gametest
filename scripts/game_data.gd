extends RefCounted
## Single runtime catalog shared by the archive, combat, shops and rewards.
static var cache: Dictionary = {}

static func read(key: String) -> Variant:
	if not cache.has(key):
		cache[key] = JSON.parse_string(FileAccess.get_file_as_string("res://data/" + key + ".json"))
	return cache[key]

static func cards() -> Dictionary:
	var pools: Dictionary = read("cards")
	for owner in pools:
		for card in pools[owner]:
			card.text = effect_text(card)
	return pools

static func effect_text(effect: Dictionary) -> String:
	var parts: Array[String] = []
	for pair in [["damage", "피해"], ["block", "방어도"], ["heal", "HP 회복"], ["bleed", "출혈"], ["next_attack", "다음 공격 추가 피해"]]:
		if effect.get(pair[0], 0) > 0:
			parts.append("%s %d" % [pair[1], effect[pair[0]]])
	if effect.get("venom_turns", 0) > 0:
		parts.append("맹독 %d턴 · 적 턴 시작 시 최대 HP의 %d%% 피해" % [effect.venom_turns, roundi(effect.venom_rate * 100)])
	return ". ".join(parts) + "." if not parts.is_empty() else effect.get("effect", "효과 없음")

static func upgraded(card: Dictionary) -> Dictionary:
	var result := card.duplicate(true)
	result.merge(card.get("upgrade", {}), true)
	result["upgraded"] = true
	result.name = card.name + "+"
	result.text = effect_text(result)
	return result

static func find_record(key: String, id: String) -> Dictionary:
	for item in read(key):
		if item.id == id:
			return item
	return {}

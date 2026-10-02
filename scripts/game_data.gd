extends RefCounted
## Single runtime catalog shared by the archive, combat, shops and rewards.
static var cache: Dictionary = {}
const CONTENT_KEYS := ["cards", "relics", "potions", "enchantments", "powers", "monsters", "events"]
const CATALOG := "res://data/content_tool/catalog.json"

static func read(key: String) -> Variant:
	if not cache.has(key) and key in CONTENT_KEYS and FileAccess.file_exists(CATALOG):
		var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CATALOG))
		for kind in CONTENT_KEYS:
			cache[kind] = catalog[kind]
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
	if effect.get("poison", 0) > 0:
		parts.append("독 %d중첩 · 적 턴 시작 시 중첩만큼 피해, 이후 1중첩 감소" % effect.poison)
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

static func starting_relic(character_id: String) -> Dictionary:
	for relic in read("relics"):
		if relic.get("starter_character", "") == character_id:
			return relic
	return {}

static func relic_text(relic: Dictionary) -> String:
	if relic.has("battle_start_block"):
		return "매 전투 시작 시 방어도 %d을 얻습니다." % int(relic.battle_start_block)
	return relic.get("effect", "")

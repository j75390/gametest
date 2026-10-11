extends RefCounted
## Single runtime catalog shared by the archive, combat, shops and rewards.
static var cache: Dictionary = {}
const CONTENT_KEYS := ["cards", "relics", "potions", "enchantments", "powers", "monsters", "events", "regions", "lore", "_library"]
const CATALOG := "res://data/content_tool/catalog.json"

static func read(key: String) -> Variant:
	if not cache.has(key) and key in CONTENT_KEYS and FileAccess.file_exists(CATALOG):
		var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CATALOG))
		for kind in CONTENT_KEYS:
			cache[kind] = catalog.get(kind, {} if kind == "_library" else [])
	if not cache.has(key):
		cache[key] = JSON.parse_string(FileAccess.get_file_as_string("res://data/" + key + ".json"))
	return cache[key]

static func cards(character_id: String = "") -> Dictionary:
	var pools: Dictionary = read("cards").duplicate(true)
	for owner in pools:
		for card in pools[owner]:
			var variants: Dictionary = card.get("character_art", {})
			if variants.has(character_id):
				card.art = variants[character_id]
				card.visual_character = character_id
			card.text = effect_text(card)
	return pools

static func effect_text(effect: Dictionary) -> String:
	var parts: Array[String] = []
	if effect.get("hp_cost", 0) > 0: parts.append("HP를 %d 잃습니다" % effect.hp_cost)
	for pair in [["damage", "피해를 %d 줍니다"], ["block", "방어도를 %d 얻습니다"], ["heal", "HP를 %d 회복합니다"], ["bleed", "출혈을 %d 부여합니다"], ["next_attack", "다음 공격의 피해가 %d 증가합니다"]]:
		if effect.get(pair[0], 0) > 0:
			parts.append(pair[1] % effect[pair[0]])
	if effect.get("per_potion_damage", 0) > 0:
		parts.append("벨트의 포션 1개마다 피해를 %d 더 줍니다" % effect.per_potion_damage)
	if effect.get("weak", 0) > 0:
		parts.append("약화를 %d 부여합니다" % effect.weak)
	if effect.get("vulnerable", 0) > 0:
		parts.append("취약을 %d 부여합니다" % effect.vulnerable)
	if effect.get("venom_turns", 0) > 0:
		parts.append("맹독을 %d턴 부여합니다" % effect.venom_turns)
	if effect.get("venom_extend", 0) > 0:
		parts.append("맹독을 %d턴 늘립니다" % effect.venom_extend)
	if effect.get("poison", 0) > 0:
		parts.append("중독을 %d 부여합니다" % effect.poison)
	if effect.get("poison_mult", 0) > 1:
		parts.append("적의 중독을 %d배로 만듭니다" % effect.poison_mult)
	if effect.get("poison_burst", false):
		parts.append("적의 중독 수치만큼 피해를 줍니다")
	if effect.get("counter", 0) > 0:
		parts.append("반격을 %d 얻습니다" % effect.counter)
	if effect.get("barrier", 0) > 0:
		parts.append("방어막을 %d 얻습니다" % effect.barrier)
	if effect.get("draw", 0) > 0:
		parts.append("카드를 %d장 뽑습니다" % effect.draw)
	if effect.get("energy", 0) > 0:
		parts.append("에너지를 %d 얻습니다" % effect.energy)
	if effect.get("brew", false):
		parts.append("무작위 포션을 1개 조제합니다")
	if effect.get("drink_potion", false):
		parts.append("벨트의 첫 포션을 마십니다")
	if effect.get("drink_all", false):
		parts.append("벨트의 모든 포션을 마십니다")
	if effect.get("side_effect", 0) > 0:
		parts.append("부작용 %d장을 버린 더미에 넣습니다" % effect.side_effect)
	if effect.get("power_text", "") != "":
		parts.append(str(effect.power_text))
	if effect.get("extra_text", "") != "":
		parts.append(str(effect.extra_text))
	if effect.get("retain", false):
		parts.append("유지")
	if effect.get("ethereal", false):
		parts.append("휘발")
	if effect.get("exhaust", false):
		parts.append("소모")
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

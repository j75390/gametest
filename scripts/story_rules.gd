extends RefCounted
## Pure eligibility checks for story-event choices, reused for button state and immediately before payment.

## Choices limited to one character (`character_only`) are not shown to the others.
static func visible_choices(choices: Array, character: String) -> Array:
	return choices.filter(func(choice): return str(choice.get("character_only", character)) == character)

## Owned, non-starting relics of the rarity named by `alt_cost` that could be paid instead of gold.
static func alt_relics(choice: Dictionary, relics: Array, relic_db: Array) -> Array:
	var alt: Dictionary = choice.get("alt_cost", {})
	if alt.is_empty(): return []
	var found: Array = []
	for record in relic_db:
		if relics.has(record.id) and str(record.get("rarity", "")) == str(alt.get("relic_rarity", "")) \
				and str(record.get("starter_character", "")).is_empty():
			found.append(str(record.id))
	return found

static func can_pay_alt(choice: Dictionary, relics: Array, relic_db: Array) -> bool:
	var alt: Dictionary = choice.get("alt_cost", {})
	return not alt.is_empty() and alt_relics(choice, relics, relic_db).size() >= int(alt.get("count", 1))

static func unavailable(choice: Dictionary, hp: int, gold: int, relics: Array, flags: Dictionary, relic_db: Array = []) -> String:
	if hp <= int(choice.get("hp_cost", 0)): return "HP가 부족합니다"
	if gold < int(choice.get("gold_cost", 0)) and not can_pay_alt(choice, relics, relic_db):
		return "골드가 부족합니다"
	if choice.has("relic") and relics.has(choice.relic): return "이미 가진 유물입니다"
	for flag in choice.get("requires_flags", []):
		if not flags.has(flag): return "아직 필요한 기록이 없습니다"
	var any_flags: Array = choice.get("condition_any_flags", [])
	if not any_flags.is_empty() and not any_flags.any(func(flag): return flags.has(flag)):
		return "아직 필요한 기록이 없습니다"
	return ""

## One-line, always-visible effects of an event choice or outcome, so no result is a surprise
## (costs first, then gains). Hidden outcomes are listed with their odds.
static func effect_summary(choice: Dictionary, relic_db: Array = []) -> String:
	var parts: Array[String] = []
	var hp_lost := int(choice.get("hp_cost", 0)) + int(choice.get("hp_loss", 0))
	if hp_lost > 0: parts.append("HP %d 잃음" % hp_lost)
	var gold_paid := int(choice.get("gold_cost", 0)) + int(choice.get("gold_loss", 0))
	if gold_paid > 0: parts.append("골드 %d 지불" % gold_paid)
	if int(choice.get("curse_add", 0)) > 0: parts.append("부작용 카드 %d장 추가" % int(choice.curse_add))
	if int(choice.get("card_remove", 0)) > 0: parts.append("기본 카드 %d장 제거" % int(choice.card_remove))
	if int(choice.get("gold_gain", 0)) > 0: parts.append("골드 %d 획득" % int(choice.gold_gain))
	if int(choice.get("heal", 0)) > 0: parts.append("HP %d 회복" % int(choice.heal))
	if int(choice.get("heal_pct", 0)) > 0: parts.append("최대 HP의 %d%% 회복" % int(choice.heal_pct))
	if int(choice.get("max_hp_gain", 0)) > 0: parts.append("최대 HP +%d" % int(choice.max_hp_gain))
	if int(choice.get("card_upgrade", 0)) > 0: parts.append("무작위 카드 %d장 강화" % int(choice.card_upgrade))
	if choice.has("card_add"): parts.append("직업 카드 1장 획득")
	if choice.has("relic"):
		var relic_name := str(choice.relic)
		for record in relic_db:
			if str(record.get("id", "")) == relic_name: relic_name = str(record.get("name", relic_name))
		parts.append("유물 ‘%s’ 획득" % relic_name)
	if choice.has("battle"): parts.append("엘리트 전투" if str(choice.battle) == "엘리트" else "전투 발생")
	var pending := {"next_battle_first_turn_block_minus_3": "다음 전투 첫 턴 방어도 -3"}
	if choice.has("pending_effect"): parts.append(str(pending.get(str(choice.pending_effect), "다음 전투에 영향")))
	var outcomes: Array = choice.get("outcomes", [])
	if not outcomes.is_empty():
		var total := 0
		for outcome in outcomes: total += maxi(1, int(outcome.get("weight", 1)))
		var chances: Array[String] = []
		for outcome in outcomes:
			var inner := effect_summary(outcome, relic_db)
			chances.append("%d%% %s" % [roundi(100.0 * maxi(1, int(outcome.get("weight", 1))) / total), inner if not inner.is_empty() else "변화 없음"])
		parts.append("무작위: " + " / ".join(chances))
	return " · ".join(parts)

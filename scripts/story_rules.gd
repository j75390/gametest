extends RefCounted
## Pure eligibility check, reused for button state and immediately before payment.
static func unavailable(choice: Dictionary, hp: int, gold: int, relics: Array, flags: Dictionary) -> String:
	if hp <= int(choice.get("hp_cost", 0)): return "HP가 부족합니다"
	if gold < int(choice.get("gold_cost", 0)): return "골드가 부족합니다"
	if choice.has("relic") and relics.has(choice.relic): return "이미 가진 유물입니다"
	for flag in choice.get("requires_flags", []):
		if not flags.has(flag): return "아직 필요한 기록이 없습니다"
	return ""

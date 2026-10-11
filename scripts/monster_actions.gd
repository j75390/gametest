extends RefCounted
## What a monster does in one turn. An action may combine: `damage` (with `hits`), `block`, `heal`,
## `buff` (statuses on itself), `apply_statuses` (statuses on the player) or just rest (`rest`).
const Data = preload("res://scripts/game_data.gd")

## The enemy's move for a turn. `opener` is a list of scripted first moves; `phases` is a list of
## {"below_pct": n, "pattern": [...]} - the last phase whose HP line has been crossed replaces the pattern.
static func pick(enemy: Dictionary, turn: int, hp: int, max_hp: int) -> Dictionary:
	var opener: Array = enemy.get("opener", [])
	if turn < opener.size(): return opener[turn]
	var pattern: Array = enemy.pattern
	for phase in enemy.get("phases", []):
		if max_hp > 0 and hp * 100 <= int(phase.below_pct) * max_hp and not phase.get("pattern", []).is_empty():
			pattern = phase.pattern
	return pattern[(turn - opener.size()) % pattern.size()]

## Name of the phase the enemy is in ("" for the base pattern), for the codex and the battle log.
static func phase_name(enemy: Dictionary, hp: int, max_hp: int) -> String:
	var found := ""
	for phase in enemy.get("phases", []):
		if max_hp > 0 and hp * 100 <= int(phase.below_pct) * max_hp: found = str(phase.get("name", ""))
	return found

static func kind(action: Dictionary) -> String:
	if int(action.get("damage", 0)) > 0: return "attack"
	if int(action.get("block", 0)) > 0: return "defend"
	if not action.get("buff", []).is_empty() or int(action.get("heal", 0)) > 0 or int(action.get("cleanse", 0)) > 0: return "buff"
	if not action.get("apply_statuses", []).is_empty() or int(action.get("side_effect", 0)) > 0: return "debuff"
	return "unknown"

## The icons shown next to the main one, e.g. an attack that also weakens.
static func extras(action: Dictionary) -> Array:
	var main := kind(action)
	var found: Array = []
	if int(action.get("block", 0)) > 0 and main != "defend": found.append("defend")
	if (not action.get("buff", []).is_empty() or int(action.get("heal", 0)) > 0 or int(action.get("cleanse", 0)) > 0) and main != "buff": found.append("buff")
	if (not action.get("apply_statuses", []).is_empty() or int(action.get("side_effect", 0)) > 0) and main != "debuff": found.append("debuff")
	return found

static func status_text(item) -> String:
	var id := str(item) if item is String else str(item.get("id", ""))
	var amount := 1 if item is String else int(item.get("amount", 1))
	var record := Data.find_record("powers", id)
	return "%s %d" % [str(record.get("name", id)), amount]

## One short line per effect, joined with " · ". `strength` and `vulnerable` change the shown attack only in battle.
static func text(action: Dictionary, bonus := 0) -> String:
	var parts: Array[String] = []
	var damage := int(action.get("damage", 0))
	if damage > 0:
		var hits := maxi(1, int(action.get("hits", 1)))
		parts.append("피해 %d×%d" % [damage + bonus, hits] if hits > 1 else "피해 %d" % (damage + bonus))
	if int(action.get("block", 0)) > 0: parts.append("방어도 +%d" % int(action.block))
	if int(action.get("heal", 0)) > 0: parts.append("회복 %d" % int(action.heal))
	if int(action.get("cleanse", 0)) > 0: parts.append("자신의 중독 %d 정화" % int(action.cleanse))
	for item in action.get("buff", []): parts.append("자신에게 " + status_text(item))
	for item in action.get("apply_statuses", []): parts.append("플레이어에게 " + status_text(item))
	if int(action.get("side_effect", 0)) > 0: parts.append("부작용 카드 %d장을 버린 더미에 섞음" % int(action.side_effect))
	if parts.is_empty(): parts.append("아무것도 하지 않음")
	return " · ".join(parts)

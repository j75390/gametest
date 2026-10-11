extends RefCounted
## Plain data model for the new codex screens. States:
##   found   - already obtained or met
##   hidden  - in the pool but not met yet (blurred, "미지")
##   locked  - not yet unlocked by a story entry; absent from the pool (padlock)
## Locked applies to records that carry an `unlock_entry` that the story timeline has not opened yet.
const Data = preload("res://scripts/game_data.gd")
const Discovery = preload("res://scripts/codex_discovery.gd")
const Timeline = preload("res://scripts/timeline.gd")
const RARITY_ORDER := ["시작", "일반", "고급", "희귀", "영웅", "전설", "고대"]
const RARITY_COLORS := {
	"시작": Color("9aa0aa"), "일반": Color("b9b3a5"), "고급": Color("62b87a"), "희귀": Color("5d9be6"),
	"영웅": Color("b974e8"), "전설": Color("e8b04a"), "고대": Color("d65a5a")}
const OWNER_ORDER := ["common", "mira", "kalian", "sera", "lucian"]

static func state(kind: String, record: Dictionary) -> String:
	var gate := str(record.get("unlock_entry", ""))
	if not gate.is_empty() and not Timeline.unlocked().has(gate): return "locked"
	return "found" if Discovery.has(kind, str(record.id)) else "hidden"

static func owner_name(id: String) -> String:
	for ch in Data.read("characters"):
		if ch.id == id: return ch.name
	return "공용"

static func cards(character: String) -> Array:
	var rows: Array = []
	var pools: Dictionary = Data.cards(character)
	for owner in OWNER_ORDER:
		for card in pools.get(owner, []):
			rows.append({"record": card, "owner": owner, "state": state("카드", card)})
	for owner in pools:
		if not OWNER_ORDER.has(owner):
			for card in pools[owner]:
				rows.append({"record": card, "owner": owner, "state": state("카드", card)})
	return rows

static func collectibles(kind: String) -> Array:
	var rows: Array = []
	for item in Data.read("relics" if kind == "유물" else "potions"):
		var section := "일반"
		if kind == "유물" and not str(item.get("starter_character", "")).is_empty(): section = "시작"
		else: section = str(item.get("rarity", "일반"))
		rows.append({"record": item, "section": section, "state": state(kind, item)})
	return rows

static func monsters() -> Array:
	var rows: Array = []
	for item in Data.read("monsters"):
		rows.append({"record": item, "state": state("몬스터", item)})
	return rows

## [found, total] across the four collectible kinds.
static func progress() -> Array:
	var found := 0
	var total := 0
	for row in cards(""):
		total += 1
		if row.state == "found": found += 1
	for kind in ["유물", "포션"]:
		for row in collectibles(kind):
			total += 1
			if row.state == "found": found += 1
	for row in monsters():
		total += 1
		if row.state == "found": found += 1
	return [found, total]

## ---------------------------------------------------------------- investigation notes

static func act_title(act: int) -> String:
	for region in Data.read("regions"):
		if int(region.get("act", 0)) == act: return "ACT %d · %s" % [act, region.name]
	return "ACT %d" % act

## Flags seen in this run plus every flag ever settled into the permanent story progress.
static func known_flags(run_flags: Dictionary) -> Dictionary:
	var seen := {}
	for flag in run_flags:
		if run_flags[flag] == true: seen[flag] = true
	var permanent: Dictionary = Timeline.load_state().flags_seen
	for flag in permanent:
		if permanent[flag] == true: seen[flag] = true
	return seen

## Notes grouped for the reader: {"조사 기록": [...], "이야기": [...], "지역": [...]} plus counts.
## Only records whose flag/relic condition is met are listed; their titles never leak otherwise.
static func notes(run_flags: Dictionary) -> Dictionary:
	var seen := known_flags(run_flags)
	var out := {"조사 기록": [], "이야기": [], "지역": [], "total": {"조사 기록": 0, "이야기": 0, "지역": 0}}
	for item in Data.read("lore"):
		out.total["조사 기록"] += 1
		var flag := str(item.get("requires_flag", ""))
		if flag.is_empty() or seen.has(flag):
			out["조사 기록"].append({"id": item.id, "name": item.name, "subtitle": act_title(int(item.get("act", 1))),
				"act": int(item.get("act", 1)), "description": str(item.get("description", item.get("effect", ""))), "art": str(item.get("art", ""))})
	for item in Data.read("story_records"):
		out.total["이야기"] += 1
		var flag := str(item.get("requires_flag", ""))
		if flag.is_empty() or seen.has(flag):
			out["이야기"].append({"id": item.id, "name": item.name, "subtitle": str(item.get("subtitle", "")),
				"act": 0, "description": str(item.description), "art": str(item.get("art", ""))})
	for item in Data.read("narrative_records"):
		var group := "지역" if str(item.kind) == "지역" else "이야기"
		out.total[group] += 1
		var flag := str(item.get("requires_flag", ""))
		var relic := str(item.get("requires_relic", ""))
		if (flag.is_empty() or seen.has(flag)) and (relic.is_empty() or Discovery.has("유물", relic)):
			out[group].append({"id": item.id, "name": item.name, "subtitle": str(item.get("subtitle", "")),
				"act": 0, "description": str(item.description), "art": str(item.get("art", ""))})
	out.total["지역"] += 1
	out["지역"].append({"id": "basin_atlas", "name": "잿빛 분지", "subtitle": "분지의 지형", "act": 0, "map": true,
		"description": "북쪽과 동서쪽의 능선이 분지를 둘러싸고, 물길은 남쪽 마을로 흘러간다. 성당은 서쪽 언덕, 운하는 낮은 땅에 있다. 동쪽 단구의 온실 너머로 오래된 회랑이 이어진다.\n\n이 지도는 땅의 모습을 보여 준다. 실제로 통과할 수 있는 길과 조사한 흔적은 원정 중 성당 지도에 기록한다.",
		"art": "res://assets/map/region_atlas_v1.png"})
	for item in Data.read("regions"):
		out.total["지역"] += 1
		var flag := str(item.get("requires_flag", ""))
		if flag.is_empty() or seen.has(flag):
			out["지역"].append({"id": item.id, "name": item.name, "subtitle": act_title(int(item.get("act", 1))),
				"act": 0, "description": str(item.get("description", "")), "art": str(item.get("art", ""))})
	return out

## Title of the note a flag unlocks, for the timeline's clue line ("???" until it is known).
static func clue_title(flag: String, run_flags: Dictionary) -> String:
	var known := known_flags(run_flags).has(flag)
	for key in ["story_records", "lore", "narrative_records"]:
		for item in Data.read(key):
			if str(item.get("requires_flag", "")) == flag:
				var relic := str(item.get("requires_relic", ""))
				var open: bool = known and (relic.is_empty() or Discovery.has("유물", relic))
				return str(item.name) if open else "???"
			if key == "story_records" and str(item.id) == flag:
				return str(item.name) if known else "???"
	return str(flag) if known else "???"

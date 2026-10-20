extends RefCounted
## Permanent story/unlock progress ("재의 연대기"). Separate from the codex discovery file.
## A run is logged while it is played and settled exactly once when it ends (clear / death / abandon).
## Settling awards points, evaluates every visible entry, unlocks the ones whose condition holds and
## reveals the entries they expand.
const Discovery = preload("res://scripts/codex_discovery.gd")
const DATA_PATH := "res://data/timeline.json"
const SCHEMA := 1
const FIRST_POINTS := {"전투": 10, "엘리트": 25, "보스": 60}
const REPEAT_POINTS := {"전투": 2, "엘리트": 5, "보스": 10}
const REPEAT_BUDGET := 40
const DISCOVERY_POINTS := 3
const DISCOVERY_CAP := 30
const FIRST_CLEAR_POINTS := 100
const REPEAT_CLEAR_POINTS := 30
const ENDING_IDS := ["kept_fire", "long_night", "own_lamps"]
## Story flag set by the ACT V ending scene -> the ending it records.
const ENDING_FLAGS := {"ending_remaining_fire": "kept_fire", "ending_long_night": "long_night", "ending_separate_lamps": "own_lamps"}
const CHARACTERS := ["mira", "severin", "calamo", "esca"]

## Scripts run with --script (the QA suite) never touch the player's real progress file.
static func _default_path() -> String:
	return "user://timeline_progress_script.json" if OS.get_cmdline_args().has("--script") else "user://timeline_progress.json"

## Tests may point this at their own scratch file.
static var path := _default_path()
static var _data: Dictionary = {}

static func data() -> Dictionary:
	if _data.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH)) if FileAccess.file_exists(DATA_PATH) else null
		_data = parsed if parsed is Dictionary else {"entries": [], "epochs": []}
	return _data

static func entries() -> Array:
	return data().get("entries", [])

static func entry(id: String) -> Dictionary:
	for item in entries():
		if item.id == id: return item
	return {}

# ---------------------------------------------------------------- storage

static func _blank() -> Dictionary:
	return {
		"schema": SCHEMA, "points": 0, "unlocked": [], "visible": [], "new_entries": [], "played": [],
		"cleared": {}, "flags_seen": {}, "monsters_seen": [], "boss_acts": [], "endings": [],
		"max_act": 1, "dex_percent": 0, "settled": [],
		"counters": {"runs": 0, "wins": 0, "elites": 0, "bosses": 0, "deaths": 0}, "kills": {}}

static func _read(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path): return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(file_path))
	if parsed is Dictionary and int(parsed.get("schema", 0)) == SCHEMA: return parsed
	return {}

## Falls back to the previous save when the current one is damaged, then to a fresh state.
static func load_state() -> Dictionary:
	var state := _read(path)
	if state.is_empty(): state = _read(path + ".bak")
	var blank := _blank()
	for key in blank:
		if not state.has(key): state[key] = blank[key]
	# damaged or hand-edited saves: coerce every field back to the expected type
	for key in blank:
		if not _same_kind(state[key], blank[key]): state[key] = blank[key]
	for key in ["points", "max_act", "dex_percent"]: state[key] = int(state[key])
	for key in blank.counters:
		if not state.counters.has(key): state.counters[key] = 0
	_start_entries(state)
	return state

## JSON turns whole numbers into floats, so numbers count as one kind.
static func _same_kind(a: Variant, b: Variant) -> bool:
	var numeric := [TYPE_INT, TYPE_FLOAT]
	if numeric.has(typeof(a)) and numeric.has(typeof(b)): return true
	return typeof(a) == typeof(b)

## Writes a temporary file, keeps the last *valid* save as .bak, then swaps it in.
## A damaged current file never overwrites a good backup. Returns false (and keeps the old save)
## if any step fails.
static func save_state(state: Dictionary) -> bool:
	var temp := path + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		push_warning("timeline: cannot write " + temp)
		return false
	file.store_string(JSON.stringify(state))
	file.close()
	if FileAccess.file_exists(path):
		if not _read(path).is_empty() and DirAccess.copy_absolute(path, path + ".bak") != OK:
			push_warning("timeline: cannot back up " + path)
			DirAccess.remove_absolute(temp)
			return false
		if DirAccess.rename_absolute(temp, path) != OK:
			# Some platforms refuse to replace an existing file: remove it, swap, and restore on failure.
			DirAccess.remove_absolute(path)
			if DirAccess.rename_absolute(temp, path) != OK:
				if FileAccess.file_exists(path + ".bak"): DirAccess.copy_absolute(path + ".bak", path)
				push_warning("timeline: cannot replace " + path)
				return false
		return true
	return DirAccess.rename_absolute(temp, path) == OK

static func _start_entries(state: Dictionary) -> void:
	for item in entries():
		if item.get("start_visible", false) and not state.visible.has(item.id): state.visible.append(item.id)
		if item.condition.type == "START" and not state.unlocked.has(item.id): state.unlocked.append(item.id)
		if state.unlocked.has(item.id):
			for target in item.get("expands", []):
				if not state.visible.has(target): state.visible.append(target)

static func unlocked() -> Array:
	return load_state().unlocked

static func is_unlocked(id: String) -> bool:
	return unlocked().has(id)

## Content gate: a card/relic/potion with `unlock_entry` only enters pools once that entry is open.
static func available(record: Dictionary) -> bool:
	var gate := str(record.get("unlock_entry", ""))
	return gate.is_empty() or unlocked().has(gate)

static func new_count() -> int:
	return load_state().new_entries.size()

static func clear_new() -> void:
	var state := load_state()
	if state.new_entries.is_empty(): return
	state.new_entries = []
	save_state(state)

# ---------------------------------------------------------------- runs

static func _discovery_count() -> int:
	var total := 0
	for kind in Discovery.read_all():
		total += Discovery.read_all()[kind].size()
	return total

static func new_run(character: String, act: int = 1) -> Dictionary:
	return {"id": "%d_%d" % [Time.get_unix_time_from_system(), randi()], "character": character,
		"act_reached": act, "act_start": act, "wins": [], "settled": false, "discover_start": _discovery_count()}

static func log_win(run: Dictionary, enemy: Dictionary) -> void:
	if run.is_empty() or run.get("settled", false): return
	run.wins.append({"id": str(enemy.get("id", "")), "type": str(enemy.get("type", "일반")), "act": int(run.get("act_reached", 1))})

static func _kind(type: String) -> String:
	if type == "엘리트": return "elite"
	if type == "보스": return "boss"
	return "normal"

## Settles a run once. Returns {} when there was nothing to settle.
static func settle(run: Dictionary, outcome: String, run_flags: Array, dex_percent: int) -> Dictionary:
	if run.is_empty() or run.get("settled", false): return {}
	var state := load_state()
	if state.settled.has(run.id):
		run.settled = true
		return {}
	var character := str(run.character)
	var gained := 0
	state.counters.runs += 1
	if not state.played.has(character): state.played.append(character)
	var repeat_left := REPEAT_BUDGET
	for win in run.wins:
		var type := str(win.type)
		var first: bool = not state.monsters_seen.has(win.id)
		if first:
			gained += int(FIRST_POINTS.get(type, 10))
			state.monsters_seen.append(win.id)
		else:
			var take := mini(int(REPEAT_POINTS.get(type, 2)), repeat_left)
			gained += take
			repeat_left -= take
		state.counters.wins += 1
		var kind := _kind(type)
		if kind == "elite":
			state.counters.elites += 1
			state.kills[character + ".elite"] = int(state.kills.get(character + ".elite", 0)) + 1
		elif kind == "boss":
			state.counters.bosses += 1
			state.kills[character + ".boss"] = int(state.kills.get(character + ".boss", 0)) + 1
			var win_act := int(win.get("act", run.act_reached))
			if not state.boss_acts.has(win_act): state.boss_acts.append(win_act)
	state.max_act = maxi(int(state.max_act), int(run.act_reached))
	if outcome == "clear":
		var done: Array = state.cleared.get(character, [])
		var first_clear := not done.has(int(run.act_reached))
		for act_number in range(int(run.get("act_start", 1)), int(run.act_reached) + 1):
			if not done.has(act_number): done.append(act_number)
		state.cleared[character] = done
		gained += FIRST_CLEAR_POINTS if first_clear else REPEAT_CLEAR_POINTS
	elif outcome == "death":
		state.counters.deaths += 1
	var found := maxi(0, _discovery_count() - int(run.discover_start))
	gained += mini(DISCOVERY_CAP, found * DISCOVERY_POINTS)
	# an ending only counts once the run is cleared; leaving during the epilogue keeps it out of the chronicle
	for flag in run_flags:
		if outcome != "clear" and str(flag).begins_with("ending_"): continue
		state.flags_seen[str(flag)] = true
	# the way a cleared ACT V ended is kept for good (the ending flags are set by the last scene)
	if outcome == "clear":
		var endings: Array = state.get("endings", [])
		for flag in run_flags:
			var ending_id := str(ENDING_FLAGS.get(str(flag), ""))
			if not ending_id.is_empty() and not endings.has(ending_id): endings.append(ending_id)
		state.endings = endings
	state.dex_percent = dex_percent
	state.points += gained
	var opened := _resolve(state)
	for id in opened:
		if not state.new_entries.has(id): state.new_entries.append(id)
	state.settled.append(run.id)
	while state.settled.size() > 20: state.settled.pop_front()
	if not save_state(state):
		push_warning("timeline: run could not be saved and stays unsettled")
		return {}
	run.settled = true
	return {"points": gained, "total": state.points, "opened": opened, "outcome": outcome}

## Unlocks every visible entry whose condition now holds, then reveals what those entries expand.
## Repeats until nothing changes. Returns the ids opened this time.
static func _resolve(state: Dictionary) -> Array:
	var opened: Array = []
	var changed := true
	var guard := 0
	while changed and guard < 30:
		changed = false
		guard += 1
		for item in entries():
			if state.unlocked.has(item.id) or not state.visible.has(item.id): continue
			if not met(item.condition, state): continue
			state.unlocked.append(item.id)
			opened.append(item.id)
			changed = true
			for target in item.get("expands", []):
				if not state.visible.has(target): state.visible.append(target)
	return opened

static func met(cond: Dictionary, state: Dictionary) -> bool:
	match str(cond.get("type", "")):
		"START": return true
		"POINTS": return int(state.points) >= int(cond.value)
		"PLAY":
			var who := str(cond.get("character", "any"))
			return not state.played.is_empty() if who == "any" else state.played.has(who)
		"PLAY_ALL":
			return CHARACTERS.all(func(c): return state.played.has(c))
		"CLEAR_ACT":
			var who2 := str(cond.get("character", "any"))
			var act := int(cond.act)
			if who2 == "any":
				for c in state.cleared:
					if state.cleared[c].has(act): return true
				return false
			return state.cleared.get(who2, []).has(act)
		"KILLS":
			var kind := str(cond.kind)
			var who3 := str(cond.get("character", "any"))
			if kind != "elite" and kind != "boss": return false
			var key := "elites" if kind == "elite" else "bosses"
			if who3 == "any": return int(state.counters[key]) >= int(cond.count)
			return int(state.kills.get(who3 + "." + kind, 0)) >= int(cond.count)
		"FLAG": return state.flags_seen.get(str(cond.flag), false) == true
		"FLAG_ANY": return cond.flags.any(func(f): return state.flags_seen.get(str(f), false) == true)
		"DEX": return int(state.dex_percent) >= int(cond.percent)
		"FIRST_DEATH": return int(state.counters.deaths) >= 1
		"ACT_REACHED": return int(state.max_act) >= int(cond.act)
		"BOSS_ACT": return state.boss_acts.has(int(cond.act))
		"ENDING":
			if str(cond.id) == "all": return ENDING_IDS.all(func(e): return state.endings.has(e))
			return state.endings.has(str(cond.id))
	return false

## One line shown for a visible-but-locked entry. Exact goals appear only after the entry opens.
static func hint(item: Dictionary) -> String:
	if not str(item.get("hint", "")).is_empty(): return str(item.hint)
	match str(item.condition.get("type", "")):
		"POINTS": return "점수를 쌓으면 열립니다."
		"PLAY", "PLAY_ALL": return "원정을 떠나 보면 열립니다."
		"CLEAR_ACT": return "끝까지 나아가면 열립니다."
		"KILLS", "BOSS_ACT": return "강한 적을 쓰러뜨리면 열립니다."
		"DEX": return "도감을 채우면 열립니다."
		"FIRST_DEATH": return "쓰러져 본 뒤에 열립니다."
		"ENDING": return "끝에 닿으면 열립니다."
	return "아직 열리지 않았습니다."

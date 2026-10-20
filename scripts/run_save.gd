extends RefCounted
## One automatic save of the expedition in progress. It is written whenever the map is shown (between rooms, never in the middle of a fight
## or an event) and removed when the run ends. `restore` puts the saved state back into the game node; the caller then shows the map.
## Values are stored with Godot's own variant encoding, so integers stay integers and floats stay floats.
const VERSION := 1
const Data = preload("res://scripts/game_data.gd")
const FrameTint = preload("res://scripts/frame_tint.gd")
static var path := "user://run_save.dat"
## QA scripts (started with --script) never touch the player's real save unless a test sets `force` and its own `path`.
static var force := false

static func allowed() -> bool:
	return force or not OS.get_cmdline_args().has("--script")

## What main.gd calls: the same as write/clear but only for the real game.
static func autosave(m) -> void:
	if allowed(): write(m)

static func autoclear() -> void:
	if allowed(): clear()

static func has_save() -> bool:
	return not read().is_empty()

static func clear() -> void:
	if FileAccess.file_exists(path): DirAccess.remove_absolute(path)

## What a loaded game needs to know about a save, for a menu line ("미라 · ACT II · HP 41/72") without restoring it.
static func summary() -> Dictionary:
	var data := read()
	if data.is_empty(): return {}
	return {"character": str(data.character), "act": int(data.act), "hp": int(data.hp), "max_hp": int(data.max_hp), "gold": int(data.gold)}

static func snapshot(m) -> Dictionary:
	var map = m.expedition
	return {
		"version": VERSION,
		"character": str(m.selected_character.get("id", "")),
		"act": m.current_act,
		"hp": m.hp, "max_hp": m.max_hp, "gold": m.gold,
		"deck": m.deck.duplicate(true),
		"relics": Array(m.owned_relics),
		"potions": m.potions.duplicate(true),
		"flags": m.story_flags.duplicate(true),
		"pending_effects": Array(m.pending_effects),
		"block_penalty": m.block_penalty,
		"removal_count": m.removal_count,
		"has_full_map": m.has_full_map,
		"last_enemy_id": m.last_enemy_id,
		"ending_seen": m.ending_seen,
		"reward_pity": m.reward_pity,
		"run_log": m.run_log.duplicate(true),
		"last_settlement": m.last_settlement.duplicate(true),
		"relic_run": m.relics.run.duplicate(true),
		"map": {"run_seed": map.run_seed, "act": map.act, "nodes": map.nodes.duplicate(true), "current_id": map.current_id,
			"visited": Array(map.visited), "discovered": Array(map.discovered), "completed": map.completed, "fixed": map.fixed.duplicate(true)},
	}

static func write(m) -> bool:
	# written beside the old save and swapped in, so a crash while writing never costs the last good save
	var temp := path + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null: return false
	file.store_var(snapshot(m), false)
	var failed := file.get_error() != OK
	file.close()
	if failed:
		DirAccess.remove_absolute(temp)
		return false
	var done := DirAccess.rename_absolute(temp, path) == OK
	if not done: DirAccess.remove_absolute(temp)
	return done

## The saved dictionary, or {} when there is no usable save (missing, unreadable, another version or missing parts).
static func read() -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return {}
	if file.get_length() < 8:
		file.close()
		return {}
	var data = file.get_var(false)
	file.close()
	if typeof(data) != TYPE_DICTIONARY or int(data.get("version", 0)) != VERSION: return {}
	var shapes := {"character": TYPE_STRING, "act": TYPE_INT, "hp": TYPE_INT, "max_hp": TYPE_INT, "gold": TYPE_INT, "deck": TYPE_ARRAY,
		"relics": TYPE_ARRAY, "potions": TYPE_ARRAY, "flags": TYPE_DICTIONARY, "run_log": TYPE_DICTIONARY, "map": TYPE_DICTIONARY}
	for key in shapes:
		if not data.has(key) or typeof(data[key]) != shapes[key]: return {}
	var map: Dictionary = data.map
	var map_shapes := {"run_seed": TYPE_INT, "act": TYPE_INT, "nodes": TYPE_ARRAY, "current_id": TYPE_INT, "visited": TYPE_ARRAY, "discovered": TYPE_ARRAY, "completed": TYPE_BOOL}
	for key in map_shapes:
		if not map.has(key) or typeof(map[key]) != map_shapes[key]: return {}
	var nodes: Array = map.nodes
	if nodes.is_empty() or int(map.current_id) < 0 or int(map.current_id) >= nodes.size(): return {}
	for node in nodes:
		if typeof(node) != TYPE_DICTIONARY or not node.has_all(["id", "row", "lane", "type", "next"]) or typeof(node.next) != TYPE_ARRAY: return {}
		for target in node.next:
			if typeof(target) != TYPE_INT or target < 0 or target >= nodes.size(): return {}
	for card in data.deck:
		if typeof(card) != TYPE_DICTIONARY: return {}
	return data

## The saved cards carry their own copy of the card data; a game update may have changed them since (shorter texts, new numbers, new effects).
## Each saved card is rebuilt from the current definition (the upgraded form for upgraded cards), so the face text and what the card does never disagree.
## The only things a run changes on a card are its upgrade (kept) and an altar enchantment (its damage bonus is added again).
static func _refresh_texts(m) -> void:
	var latest := {}
	for group in m.card_db:
		var list = m.card_db[group]
		if not (list is Array): continue
		for card in list:
			if card is Dictionary and not latest.has(str(card.get("id", ""))): latest[str(card.get("id", ""))] = card
	for i in m.deck.size():
		var card: Dictionary = m.deck[i]
		var fresh: Dictionary = latest.get(str(card.get("id", "")), {})
		if fresh.is_empty(): continue
		var was_upgraded: bool = card.get("upgraded", false)
		# a definition that no longer has an upgrade cannot be rebuilt as the upgraded card: the saved one stays as it is
		if was_upgraded and fresh.get("upgrade", {}).is_empty(): continue
		# the card keeps its own copy: the catalog's dictionaries must not be shared (the enchantment bonus below is added in place)
		var rebuilt: Dictionary = (Data.upgraded(fresh) if was_upgraded else fresh).duplicate(true)
		if card.has("enchantment"):
			var bonus := int(Data.find_record("enchantments", str(card.enchantment)).get("damage", 0))
			rebuilt["enchantment"] = card.enchantment
			rebuilt["damage"] = int(rebuilt.get("damage", 0)) + bonus
			if rebuilt.get("upgrade", {}).has("damage"): rebuilt.upgrade["damage"] = int(rebuilt.upgrade.damage) + bonus
		m.deck[i] = rebuilt

## Puts the saved run into `m` (the game node). Returns false, changing nothing, when the character is unknown.
static func restore(m, data: Dictionary) -> bool:
	var character := {}
	for c in m.characters:
		if str(c.get("id", "")) == str(data.get("character", "")): character = c
	if character.is_empty() or data.is_empty(): return false
	m.selected_character = character
	FrameTint.hero = str(character.get("id", ""))
	m.card_db = Data.cards(character.id)
	m.current_act = int(data.act)
	m.hp = int(data.hp)
	m.max_hp = int(data.max_hp)
	m.gold = int(data.gold)
	m.deck = (data.deck as Array).duplicate(true)
	_refresh_texts(m)
	m.owned_relics.assign(data.relics)
	m.potions = (data.potions as Array).duplicate(true)
	m.story_flags = (data.flags as Dictionary).duplicate(true)
	m.pending_effects.assign(data.get("pending_effects", []))
	m.block_penalty = int(data.get("block_penalty", 0))
	m.removal_count = int(data.get("removal_count", 0))
	m.has_full_map = bool(data.get("has_full_map", false))
	m.last_enemy_id = str(data.get("last_enemy_id", ""))
	m.ending_seen = bool(data.get("ending_seen", false))
	m.reward_pity = int(data.get("reward_pity", 0))
	m.run_log = (data.run_log as Dictionary).duplicate(true)
	m.relics.reset_run()
	m.relics.run = (data.get("relic_run", m.relics.run) as Dictionary).duplicate(true)
	var map = m.expedition
	var saved: Dictionary = data.map
	map.run_seed = int(saved.run_seed)
	map.act = int(saved.act)
	map.nodes.assign(saved.nodes)
	map.current_id = int(saved.current_id)
	map.visited.assign(saved.visited)
	map.discovered.assign(saved.discovered)
	map.completed = bool(saved.completed)
	map.fixed = (saved.get("fixed", {}) as Dictionary).duplicate(true)
	map.pending = false
	# nothing from an unfinished room carries over
	m.story_event.clear()
	m.story_choice_taken = false
	m.story_follow_up = ""
	m.story_pending_battle = ""
	m.arrival_pending = false
	m.shop_visit_node = -1
	m.shop_stock.clear()
	m.last_settlement = (data.get("last_settlement", {}) as Dictionary).duplicate(true)
	return true

extends RefCounted
## Data-driven relic effects. A relic may carry an `effects` list; every entry is
##   {"on": trigger, "if": {conditions}, "limit": "battle"|"turn"|"run"|"shop", "times": n, ...operations}
## `fire(trigger, ctx)` runs the entries for an event and returns the summed operations for the caller
## to apply (block, heal, energy, draw, gold, poison_enemy, max_hp, cleanse_poison). `modify(trigger, ctx)`
## sums the `add` values of entries that adjust a number (damage, draw, healing...). Both honour limits.
## Relics without `effects` keep working through the old single-field bonuses in main.gd.
const Data = preload("res://scripts/game_data.gd")
const OPS := ["block", "heal", "energy", "draw", "gold", "poison_enemy", "max_hp", "cleanse_poison", "upgrade_random", "heal_pct", "hp_loss", "survive"]

var battle := {}
var turn := {}
var shop := {}
var run := {}
var lines: Array[String] = []
## Names of the relics that fired in the most recent `fire` call (for on-screen notices).
var last_fired: Array[String] = []
var lookup: Callable = func(id: String) -> Dictionary: return Data.find_record("relics", id)

func _init() -> void:
	reset_run()

func reset_run() -> void:
	run = {"used": {}, "bank": 0, "carry": {}}
	battle = {"used": {}, "first_attack_bonus": 0, "next_turn": {}, "flags": {}, "counters": {}}
	turn = {"used": {}, "cards": 0, "types": [], "block_gained": 0, "block_cards": 0, "costs": [], "names": []}
	shop = {"used": {}}
	lines.clear()

func begin_battle() -> void:
	battle = {"used": {}, "first_attack_bonus": 0, "next_turn": {}, "flags": {}, "counters": {}}
	turn = {}
	lines.clear()
	begin_turn()

func begin_turn() -> void:
	battle["prev_hp_lost"] = bool(turn.get("hp_lost", false))
	turn = {"used": {}, "cards": 0, "types": [], "block_gained": 0, "block_cards": 0, "costs": [], "names": []}

func begin_shop() -> void:
	shop = {"used": {}}

func note_card(card: Dictionary, block_gained: int) -> void:
	turn.cards += 1
	turn.types.append(str(card.get("type", "")))
	turn.block_gained += block_gained
	if block_gained > 0: turn.block_cards += 1
	turn.costs.append(int(card.get("cost", 0)))
	if not turn.names.has(str(card.get("name", ""))): turn.names.append(str(card.get("name", "")))

func bank() -> int:
	return int(run.get("bank", 0))

func _entries(trigger: String, owned: Array) -> Array:
	var found: Array = []
	for id in owned:
		var record: Dictionary = lookup.call(str(id))
		var list: Array = record.get("effects", [])
		for i in list.size():
			if str(list[i].get("on", "")) == trigger: found.append({"relic": record, "index": i, "effect": list[i]})
	return found

func _scope(limit: String) -> Dictionary:
	match limit:
		"battle": return battle.used
		"turn": return turn.used
		"shop": return shop.used
		"run": return run.used
	return {}

func _available(entry: Dictionary) -> bool:
	var limit := str(entry.effect.get("limit", ""))
	if limit.is_empty(): return true
	return int(_scope(limit).get(_key(entry), 0)) < int(entry.effect.get("times", 1))

func _key(entry: Dictionary) -> String:
	return "%s:%d" % [entry.relic.id, entry.index]

func _spend(entry: Dictionary) -> void:
	var limit := str(entry.effect.get("limit", ""))
	if limit.is_empty(): return
	var used := _scope(limit)
	used[_key(entry)] = int(used.get(_key(entry), 0)) + 1

## ctx keys: turn, hp, max_hp, kind, enemy_hp, enemy_max_hp, enemy_poison, enemy_venom, self_poison,
## card, dot_kill, new_enemy, no_curse
func conditions_met(cond: Dictionary, ctx: Dictionary) -> bool:
	for key in cond:
		var want = cond[key]
		var card: Dictionary = ctx.get("card", {})
		match key:
			"turn": if int(ctx.get("turn", 0)) != int(want): return false
			"turn_every": if int(ctx.get("turn", 0)) % int(want) != 0: return false
			"hp_ratio_max": if float(ctx.get("hp", 0)) > float(ctx.get("max_hp", 1)) * float(want): return false
			"hp_max": if int(ctx.get("hp", 0)) > int(want): return false
			"kind": if str(ctx.get("kind", "")) != str(want): return false
			"enemy_poison": if (int(ctx.get("enemy_poison", 0)) > 0) != bool(want): return false
			"enemy_venom": if (int(ctx.get("enemy_venom", 0)) > 0) != bool(want): return false
			"enemy_full_hp": if (int(ctx.get("enemy_hp", 0)) >= int(ctx.get("enemy_max_hp", 1))) != bool(want): return false
			"self_poison": if (int(ctx.get("self_poison", 0)) > 0) != bool(want): return false
			"card_cost_min": if int(card.get("cost", 0)) < int(want): return false
			"card_heal": if (int(card.get("heal", 0)) > 0) != bool(want): return false
			"card_type": if str(card.get("type", "")) != str(want): return false
			"cards_played": if int(turn.cards) != int(want): return false
			"cards_min": if int(turn.cards) < int(want): return false
			"all_skills": if (not turn.types.is_empty() and turn.types.all(func(t): return t == "스킬")) != bool(want): return false
			"no_block_gained": if (int(turn.block_gained) == 0) != bool(want): return false
			"dot_kill": if bool(ctx.get("dot_kill", false)) != bool(want): return false
			"new_enemy": if bool(ctx.get("new_enemy", false)) != bool(want): return false
			"no_curse": if bool(ctx.get("no_curse", true)) != bool(want): return false
			"deck_no_heal": if bool(ctx.get("deck_no_heal", false)) != bool(want): return false
			"skills_played": if turn.types.count("스킬") != int(want): return false
			"block_cards_min": if int(turn.block_cards) < int(want): return false
			"turn_cost_mix": if (turn.costs.has(0) and turn.costs.any(func(c): return c >= 2)) != bool(want): return false
			"distinct_cards_min": if turn.names.size() < int(want): return false
			"attacks_played": if turn.types.count("공격") != int(want): return false
			"flag": if not battle.flags.has(str(want)): return false
			"energy_left": if (int(ctx.get("energy", 0)) > 0) != bool(want): return false
			"turn_min": if int(ctx.get("turn", 0)) < int(want): return false
			"prev_turn_hp_lost": if bool(battle.get("prev_hp_lost", false)) != bool(want): return false
			"upgraded_cards_min": if int(ctx.get("upgraded_cards", 0)) < int(want): return false
			"card_upgraded": if bool(card.get("upgraded", false)) != bool(want): return false
			_: return false
	return true

func fire(trigger: String, ctx: Dictionary, owned: Array) -> Dictionary:
	var result := {}
	last_fired.clear()
	if trigger == "hp_lost": turn["hp_lost"] = true
	for entry in _entries(trigger, owned):
		var effect: Dictionary = entry.effect
		if not _available(entry) or not conditions_met(effect.get("if", {}), ctx): continue
		var payouts := 1
		if effect.has("accumulate"):
			# loss builds up toward payouts: every `accumulate` points pays once, up to the remaining uses
			var key := _key(entry)
			battle.counters[key] = int(battle.counters.get(key, 0)) + int(ctx.get("damage", 0))
			var earned := int(battle.counters[key]) / int(effect.accumulate)
			if earned <= 0: continue
			var remaining := int(effect.get("times", 1)) - int(_scope(str(effect.get("limit", ""))).get(key, 0))
			payouts = mini(earned, remaining) if str(effect.get("limit", "")) != "" else earned
			battle.counters[key] = int(battle.counters[key]) - payouts * int(effect.accumulate)
		for i in payouts: _spend(entry)
		for op in OPS:
			if effect.has(op): result[op] = int(result.get(op, 0)) + int(effect[op]) * payouts
		if effect.has("set_flag"): battle.flags[str(effect.set_flag)] = true
		if effect.has("heal_ratio_damage"):
			result.heal = int(result.get("heal", 0)) + ceili(float(ctx.get("damage", 0)) * float(effect.heal_ratio_damage))
		if effect.has("gold_pct"):
			result.gold = int(result.get("gold", 0)) + ceili(float(ctx.get("reward_gold", 0)) * float(effect.gold_pct) / 100.0)
		if effect.has("next_attack"): battle.first_attack_bonus = int(battle.first_attack_bonus) + int(effect.next_attack)
		if effect.has("carry_energy"):
			var kept := mini(int(ctx.get("energy", 0)), int(effect.carry_energy))
			if kept > 0: battle.next_turn["energy"] = int(battle.next_turn.get("energy", 0)) + kept
		if effect.has("bank_add"): run.bank = int(run.bank) + int(effect.bank_add)
		if effect.has("bank_pay"):
			var paid := mini(int(run.bank), int(effect.bank_pay))
			result.heal = int(result.get("heal", 0)) + paid
			run.bank = 0
		var later: Dictionary = effect.get("next_battle", {})
		for op in later: run.carry[op] = int(run.carry.get(op, 0)) + int(later[op])
		var soon: Dictionary = effect.get("next_turn", {})
		for op in soon: battle.next_turn[op] = int(battle.next_turn.get(op, 0)) + int(soon[op])
		lines.append("%s" % entry.relic.name)
		if not last_fired.has(str(entry.relic.name)): last_fired.append(str(entry.relic.name))
	return result

## Effects stored by earlier events: next-battle carry (consumed) and next-turn carry (consumed).
func take_carry(scope_name: String) -> Dictionary:
	last_fired.clear()
	var source: Dictionary = run.carry if scope_name == "battle" else battle.next_turn
	var result := {}
	for op in source:
		if op == "first_attack_bonus": battle.first_attack_bonus = int(battle.first_attack_bonus) + int(source[op])
		else: result[op] = int(source[op])
	source.clear()
	return result

func modify(trigger: String, ctx: Dictionary, owned: Array) -> int:
	var total := 0
	for entry in _entries(trigger, owned):
		var effect: Dictionary = entry.effect
		if not _available(entry) or not conditions_met(effect.get("if", {}), ctx): continue
		_spend(entry)
		if effect.has("pct_max_hp"):
			total += ceili(float(ctx.get("max_hp", 0)) * float(effect.pct_max_hp) / 100.0)
		else:
			total += int(effect.get("add", 0))
		lines.append("%s" % entry.relic.name)
	return total

## Looks at what a trigger would give without using up any limit (for prices shown before the choice).
## Returns {"add": sum of `add`, "free": true when a `free` entry is still available}.
func preview(trigger: String, ctx: Dictionary, owned: Array) -> Dictionary:
	var result := {"add": 0, "free": false}
	for entry in _entries(trigger, owned):
		var effect: Dictionary = entry.effect
		if not _available(entry) or not conditions_met(effect.get("if", {}), ctx): continue
		result.add += int(effect.get("add", 0))
		if effect.get("free", false): result.free = true
	return result

## The first attack after a rest is carried in battle.first_attack_bonus; it is spent by the first attack.
func take_first_attack_bonus() -> int:
	var bonus := int(battle.first_attack_bonus)
	battle.first_attack_bonus = 0
	return bonus

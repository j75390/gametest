extends RefCounted
## A run owns one immutable graph. Only traversal/visibility changes while moving.
const ROWS := 12
var nodes: Array[Dictionary] = []
var run_seed: int = 0
var current_id := 0
var visited: Array[int] = [0]
var discovered: Array[int] = [0]
var pending := false
var completed := false
## ACT number and rows whose room is a fixed story event ({row: event id}); every node of such a row is that event.
var act := 1
const FIXED_ROWS := {2: {3: "act2_cargo_scale", 8: "act2_bypass_sluice"}, 3: {3: "act3_tea", 8: "act3_formula_room"}, 4: {3: "act4_restore_order", 8: "act4_ian_slip"}}
var fixed: Dictionary = {}

func generate(seed_value: int, act_number: int = 1) -> void:
	run_seed = seed_value
	act = act_number
	fixed = FIXED_ROWS.get(act_number, {})
	nodes.clear()
	current_id = 0
	visited = [0]
	discovered = [0]
	pending = false
	completed = false
	var rng := RandomNumberGenerator.new()
	rng.seed = run_seed
	var previous: Array[int] = [_add(0, 2.0, "출발")]
	for row in range(1, ROWS):
		var next: Array[int] = []
		var count := 1 if row == ROWS - 1 else rng.randi_range(2, 4)
		for col in range(count):
			var lane := 2.0 if count == 1 else lerpf(0.3, 3.7, float(col) / (count - 1)) + rng.randf_range(-0.22, 0.22)
			var kind := "보스" if row == ROWS - 1 else "전투"
			next.append(_add(row, lane, kind))
		# Monotone zipper: no crossing, orphan nodes or dead ends; branches and merges.
		var a := 0
		var b := 0
		while true:
			nodes[previous[a]].next.append(next[b])
			if a == previous.size() - 1 and b == next.size() - 1:
				break
			if a == previous.size() - 1:
				b += 1
			elif b == next.size() - 1:
				a += 1
			else:
				var step := rng.randi_range(0, 2)
				a += 1 if step != 1 else 0
				b += 1 if step != 0 else 0
		previous = next
	_assign_kinds(rng)
	visible()

func _add(row: int, lane: float, kind: String) -> int:
	var id := nodes.size()
	nodes.append({"id": id, "row": row, "lane": lane, "type": kind, "next": [], "cleared": row == 0})
	return id

func available() -> Array:
	return [] if nodes.is_empty() or pending or completed else nodes[current_id].next

func enter(id: int) -> bool:
	if not available().has(id):
		return false
	current_id = id
	visited.append(id)
	pending = true
	visible()
	return true

func resolve() -> void:
	if not pending:
		return
	nodes[current_id].cleared = true
	pending = false
	completed = nodes[current_id].type == "보스"

func visible(full_map: bool = false) -> Array[int]:
	var result: Array[int] = discovered.duplicate()
	if full_map:
		result.clear()
		for node in nodes:
			result.append(node.id)
		return result
	var frontier: Array[int] = [current_id]
	for depth in range(2):
		var next: Array[int] = []
		for id in frontier:
			for target in nodes[id].next:
				if not result.has(target):
					result.append(target)
				if not next.has(target):
					next.append(target)
		frontier = next
	discovered = result.duplicate()
	return result

## Room types are drawn after the paths exist so the rules can look at neighbours: no repeating a
## special room back to back, no third fight in a row, elites and shops only once the run is under way,
## and every run is guaranteed a few of each special room somewhere on the map.
const MIDDLE_FIRST := 2
const WEIGHTS := {"전투": 40, "이벤트": 22, "휴식": 10, "상점": 9, "엘리트": 11, "보물": 6}
const FIRST_ROW := {"엘리트": 4, "상점": 3, "휴식": 4, "보물": 4, "이벤트": 1}
const LAST_ROW := {"휴식": 8, "보물": 8}
const MINIMUM := {"상점": 1, "보물": 1, "엘리트": 2, "휴식": 1, "이벤트": 3}

func _parents(id: int) -> Array:
	return nodes.filter(func(n): return n.next.has(id))

func _allowed(id: int, kind: String) -> bool:
	var row: int = nodes[id].row
	if row < int(FIRST_ROW.get(kind, 0)) or row > int(LAST_ROW.get(kind, ROWS - 3)): return false
	var near: Array = _parents(id).map(func(n): return n.type) + nodes[id].next.map(func(n): return nodes[n].type)
	if kind != "전투" and near.has(kind): return false
	if kind == "전투":
		for parent in _parents(id):
			if parent.type == "전투" and _parents(parent.id).any(func(g): return g.type == "전투"): return false
	return true

func _assign_kinds(rng: RandomNumberGenerator) -> void:
	for node in nodes:
		if node.row == 0 or node.row >= ROWS - 1: continue
		node.type = "휴식" if node.row == ROWS - 2 else "전투"
	for node in nodes:
		if fixed.has(node.row):
			node.type = "이벤트"
			node["fixed_event"] = fixed[node.row]
	var row_one: Array = nodes.filter(func(n): return n.row == 1)
	for node in row_one:
		if rng.randf() < 0.3 and row_one.any(func(o): return o.id != node.id and o.type == "전투"): node.type = "이벤트"
	for row in range(MIDDLE_FIRST, ROWS - 2):
		if fixed.has(row): continue
		var members: Array = nodes.filter(func(n): return n.row == row)
		for node in members:
			var pool: Array = []
			for kind in WEIGHTS:
				if _allowed(node.id, kind):
					for i in int(WEIGHTS[kind]): pool.append(kind)
			node.type = pool[rng.randi_range(0, pool.size() - 1)] if not pool.is_empty() else "전투"
		# a row of all the same room feels like no choice: swap one for a different kind
		if members.size() > 1 and members.all(func(n): return n.type == members[0].type):
			var swap: Dictionary = members[rng.randi_range(0, members.size() - 1)]
			for kind in ["이벤트", "전투", "상점", "휴식"]:
				if kind != swap.type and _allowed(swap.id, kind):
					swap.type = kind
					break
	for kind in MINIMUM:
		var have := nodes.filter(func(n): return n.type == kind).size()
		var tries := 0
		while have < int(MINIMUM[kind]) and tries < 40:
			tries += 1
			var fights: Array = nodes.filter(func(n): return n.type == "전투" and n.row >= MIDDLE_FIRST and n.row < ROWS - 2 and not fixed.has(n.row) and _allowed(n.id, kind))
			if fights.is_empty(): break
			fights[rng.randi_range(0, fights.size() - 1)].type = kind
			have += 1

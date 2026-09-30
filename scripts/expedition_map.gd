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

func generate(seed_value: int) -> void:
	run_seed = seed_value
	nodes.clear()
	current_id = 0
	visited = [0]
	discovered = [0]
	pending = false
	completed = false
	var rng := RandomNumberGenerator.new()
	rng.seed = run_seed
	var previous: Array[int] = [_add(0, 2.0, "출발")]
	var kinds := ["전투", "전투", "전투", "이벤트", "상점", "휴식", "보물", "엘리트"]
	for row in range(1, ROWS):
		var next: Array[int] = []
		var count := 1 if row == ROWS - 1 else rng.randi_range(2, 4)
		for col in range(count):
			var lane := 2.0 if count == 1 else lerpf(0.3, 3.7, float(col) / (count - 1)) + rng.randf_range(-0.22, 0.22)
			var kind: String = kinds[rng.randi_range(0, kinds.size() - 1)]
			if row == 1:
				kind = "전투"
			elif row == ROWS - 2:
				kind = "휴식"
			elif row == ROWS - 1:
				kind = "보스"
			elif col == 0 and row in [3, 5, 7]:
				kind = {3: "상점", 5: "보물", 7: "엘리트"}[row]
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

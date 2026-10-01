extends RefCounted
const Data = preload("res://scripts/game_data.gd")
var entries: Dictionary = {}

func amount(id: String) -> int:
	return int(entries.get(id, {}).get("amount", 0))

func set_amount(id: String, value: int) -> void:
	if value <= 0:
		entries.erase(id)
		return
	var record := Data.find_record("powers", id)
	if record.is_empty():
		push_error("Unknown status: " + id)
		return
	var maximum := int(record.get("max_stack", 0))
	var entry: Dictionary = entries.get(id, {})
	entry["amount"] = mini(value, maximum) if maximum > 0 else value
	entries[id] = entry

func apply(items: Array) -> void:
	for item in items:
		var id: String = item if item is String else str(item.get("id", ""))
		var value: int = 1 if item is String else int(item.get("amount", 1))
		set_amount(id, amount(id) + value)
		if item is Dictionary and item.has("rate") and entries.has(id):
			entries[id]["rate"] = float(item.rate)

func tick(max_hp: int) -> int:
	var damage := 0
	for receipt in tick_details(max_hp): damage += receipt.damage
	return damage

func tick_details(max_hp: int) -> Array:
	var receipts: Array = []
	for id in entries.keys():
		var definition := Data.find_record("powers", id)
		var damage := 0
		match definition.get("behavior", ""):
			"dot_flat": damage = amount(id)
			"dot_percent": damage = maxi(1, ceili(max_hp * float(entries[id].get("rate", definition.get("rate", 0.08)))))
		if damage > 0:
			receipts.append({"id": id, "damage": damage})
			set_amount(id, amount(id) - 1)
	return receipts

func consume_attack() -> int:
	var bonus := 0
	for id in entries.keys():
		if Data.find_record("powers", id).get("behavior") == "next_attack":
			bonus += amount(id)
			entries.erase(id)
	return bonus

extends RefCounted
## Only records actually acquired/encountered are revealed. Separate from run state.
static var path := "user://discovered_codex.json"
static func read_all() -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var value = JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary else {}
static func has(kind: String, id: String) -> bool:
	return read_all().get(kind, []).has(id)
static func record(kind: String, id: String) -> void:
	if id.is_empty(): return
	var entries := read_all()
	var ids: Array = entries.get(kind, [])
	if ids.has(id): return
	ids.append(id)
	entries[kind] = ids
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file: file.store_string(JSON.stringify(entries))

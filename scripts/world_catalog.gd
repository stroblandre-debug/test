extends RefCounted
## A plan entry is never treated as a playable level.

const PATH: String = "res://data/worlds.json"
const WORLD_COUNT: int = 33

static func entries(path: String = PATH) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not FileAccess.file_exists(path):
		return result
	var parser: JSON = JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK or not parser.data is Array:
		return result
	var values: Array = parser.data
	if values.size() != WORLD_COUNT:
		return result
	var ids: Dictionary = {}
	for value in values:
		if not value is Dictionary:
			return []
		var world_id: Variant = value.get("id")
		if not (world_id is int or world_id is float) or float(world_id) != floorf(float(world_id)):
			return []
		var index: int = int(world_id)
		if index < 1 or index > WORLD_COUNT or ids.has(index):
			return []
		if value.get("act") != act_for(index):
			return []
		if not value.get("title") is String or not value.get("scene") is String:
			return []
		if value.get("status") not in ["playable", "planned"]:
			return []
		if value.get("status") == "playable" and (str(value["title"]).is_empty() or str(value["scene"]).is_empty() or not str(value["scene"]).begins_with("res://worlds/")):
			return []
		ids[index] = true
		result.append(value.duplicate(true))
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["id"]) < int(b["id"]))
	return result

static func find(world_id: int) -> Dictionary:
	for entry in entries():
		if int(entry["id"]) == world_id:
			return entry
	return {}

static func is_playable(world_id: int) -> bool:
	var entry: Dictionary = find(world_id)
	return not entry.is_empty() and entry["status"] == "playable" and ResourceLoader.exists(str(entry["scene"]), "PackedScene")

static func act_for(world_id: int) -> int:
	return int((world_id - 1) / 11.0) + 1 if world_id >= 1 and world_id <= WORLD_COUNT else 0

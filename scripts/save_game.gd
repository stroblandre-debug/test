extends RefCounted
## Version 2 stores a separate quest snapshot for every visited world.
## The returned active-world view keeps gameplay independent of disk layout.

const SAVE_PATH: String = "user://veil_save.json"
const VERSION: int = 2
const MAX_WORLDS: int = 33

static func fresh() -> Dictionary:
	return {"version": VERSION, "current_world": 1, "worlds": {}, "unlocked": false, "seals": [false, false, false], "defeated": [], "completed": false}

static func read_save(path: String = SAVE_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	if file.get_length() > 128000:
		file.close()
		return {}
	var parser: JSON = JSON.new()
	var parse_result: Error = parser.parse(file.get_as_text())
	file.close()
	if parse_result != OK:
		return {}
	var decoded: Variant = parser.data
	if not decoded is Dictionary:
		return {}
	if decoded.get("version") == 1:
		var legacy: Dictionary = _validated_world(decoded, 1)
		if legacy.is_empty():
			return {}
		return _active_view(1, {"1": legacy})
	if decoded.get("version") != VERSION or not _valid_id(decoded.get("current_world")):
		return {}
	var worlds: Dictionary = _validated_worlds(decoded.get("worlds"))
	var active_id: int = int(decoded["current_world"])
	if not worlds.has(str(active_id)):
		return {}
	return _active_view(active_id, worlds)

static func _valid_id(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floorf(float(value)) and value >= 1 and value <= MAX_WORLDS

static func _validated_worlds(value: Variant) -> Dictionary:
	if not value is Dictionary or value.is_empty() or value.size() > MAX_WORLDS:
		return {}
	var result: Dictionary = {}
	for key in value:
		if not key is String or not key.is_valid_int() or str(int(key)) != key or not _valid_id(int(key)):
			return {}
		var snapshot: Dictionary = _validated_world(value[key], int(key))
		if snapshot.is_empty():
			return {}
		result[key] = snapshot
	return result

static func _validated_world(value: Variant, world_id: int) -> Dictionary:
	if not value is Dictionary or not value.get("unlocked") is bool or not value.get("completed") is bool:
		return {}
	var seals: Variant = value.get("seals")
	if not seals is Array or seals.size() > 16 or (world_id == 1 and seals.size() != 3):
		return {}
	for seal in seals:
		if not seal is bool:
			return {}
	var defeated: Variant = value.get("defeated")
	var enemy_limit: int = 5 if world_id == 1 else 128
	if not defeated is Array or defeated.size() > enemy_limit:
		return {}
	var ids: Array[int] = []
	for enemy_value in defeated:
		if not (enemy_value is int or enemy_value is float) or not is_finite(float(enemy_value)) or float(enemy_value) != floorf(float(enemy_value)):
			return {}
		var enemy_id: int = int(enemy_value)
		if enemy_id < 0 or enemy_id >= enemy_limit or enemy_id in ids:
			return {}
		ids.append(enemy_id)
	var result: Dictionary = {"unlocked": value["unlocked"], "seals": seals.duplicate(), "defeated": ids, "completed": value["completed"]}
	# Reject impossible progress rather than silently enabling a broken quest.
	if not result["unlocked"] and (true in seals or not ids.is_empty() or result["completed"]):
		return {}
	if result["completed"] and false in seals:
		return {}
	return result

static func _active_view(world_id: int, worlds: Dictionary) -> Dictionary:
	var result: Dictionary = worlds[str(world_id)].duplicate(true)
	result["version"] = VERSION
	result["current_world"] = world_id
	result["worlds"] = worlds.duplicate(true)
	return result

static func for_world(data: Dictionary, world_id: int) -> Dictionary:
	if not _valid_id(world_id):
		return {}
	var document: Dictionary = _document(data)
	if document.is_empty():
		return {}
	var worlds: Dictionary = document["worlds"]
	if not worlds.has(str(world_id)):
		worlds[str(world_id)] = {"unlocked": false, "seals": [false, false, false], "defeated": [], "completed": false}
	return _active_view(world_id, worlds)

static func _document(data: Dictionary) -> Dictionary:
	var world_id: Variant = data.get("current_world", 1)
	if not _valid_id(world_id) or not data.get("worlds", {}) is Dictionary:
		return {}
	var active: Dictionary = _validated_world(data, int(world_id))
	if active.is_empty():
		return {}
	var worlds: Dictionary = data.get("worlds", {}).duplicate(true)
	worlds[str(int(world_id))] = active
	worlds = _validated_worlds(worlds)
	if worlds.is_empty():
		return {}
	return {"version": VERSION, "current_world": int(world_id), "worlds": worlds}

static func write_save(data: Dictionary, path: String = SAVE_PATH) -> bool:
	var document: Dictionary = _document(data)
	if document.is_empty():
		return false
	# A migrated 0.1 file is preserved once before the first version-2 write.
	if FileAccess.file_exists(path) and not FileAccess.file_exists(path + ".v1.bak"):
		var parser: JSON = JSON.new()
		if parser.parse(FileAccess.get_file_as_string(path)) == OK and parser.data is Dictionary and parser.data.get("version") == 1:
			var backup: FileAccess = FileAccess.open(path + ".v1.bak", FileAccess.WRITE)
			if backup == null:
				return false
			backup.store_buffer(FileAccess.get_file_as_bytes(path))
			var backup_error: Error = backup.get_error()
			backup.close()
			if backup_error != OK:
				return false
	var temp_path: String = path + ".tmp"
	var file: FileAccess = FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(document))
	file.flush()
	var error: Error = file.get_error()
	file.close()
	if error != OK:
		return false
	return DirAccess.rename_absolute(temp_path, path) == OK

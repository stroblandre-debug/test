extends Node2D
## Instantiates only implemented catalog scenes and owns their lifetime.

signal world_loaded(world_id: int)
const Catalog = preload("res://scripts/world_catalog.gd")
var active_world: Node2D
var current_id: int = 0
var last_error: String = ""

func load_world(world_id: int) -> bool:
	last_error = ""
	if not Catalog.is_playable(world_id):
		last_error = "Diese Welt ist noch nicht begehbar."
		return false
	var entry: Dictionary = Catalog.find(world_id)
	var packed: PackedScene = load(str(entry["scene"])) as PackedScene
	if packed == null:
		last_error = "Die Welt konnte nicht geladen werden."
		return false
	var candidate: Node = packed.instantiate()
	if not candidate is Node2D or not candidate.has_method("has_valid_layout"):
		candidate.free()
		last_error = "Die Welt hat keine gültige Spielgrundlage."
		return false
	add_child(candidate)
	if not candidate.has_valid_layout() or candidate.world_id != world_id:
		remove_child(candidate)
		candidate.queue_free()
		last_error = "Der Startpunkt der Welt ist nicht begehbar."
		return false
	if is_instance_valid(active_world):
		remove_child(active_world)
		active_world.queue_free()
	active_world = candidate
	current_id = world_id
	world_loaded.emit(world_id)
	return true

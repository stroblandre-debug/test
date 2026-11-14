extends Node2D
## Shared world contract: movement, realm changes, collision and checkpoints.
## New worlds provide a scene, a layout, and their own drawing/quest logic.

@export var world_id: int = 1
var cell_size: int = 48
var world_size: Vector2 = Vector2(1920, 1344)
var spawn_point: Vector2 = Vector2.ZERO
var keeper_position: Vector2 = Vector2.INF
var gate_position: Vector2 = Vector2.INF
var portal_position: Vector2 = Vector2.INF
var campfire_position: Vector2 = Vector2.INF
var shrine_positions: Array[Vector2] = []
var shrine_titles: Array[String] = []
var enemy_positions: Array[Vector2] = []
var veil: bool = false
var gate_open: bool = false
var seals: Array[bool] = []
var tiles: Dictionary = {}

func tile_at(point: Vector2) -> String:
	return str(tiles.get(Vector2i(floori(point.x / cell_size), floori(point.y / cell_size)), "wall"))

func can_stand(point: Vector2, radius: float = 11.0, realm: int = -1) -> bool:
	var in_veil: bool = veil if realm == -1 else realm == 1
	for offset in [Vector2(-radius, -radius), Vector2(radius, -radius), Vector2(-radius, radius), Vector2(radius, radius)]:
		var kind: String = tile_at(point + offset)
		if kind in ["wall", "tree", "rock", "water"]:
			return false
		if kind == "gate" and not gate_open:
			return false
		if kind == "spirit_bridge" and not in_veil:
			return false
	return true

func move_actor(point: Vector2, movement: Vector2, radius: float = 11.0) -> Vector2:
	var steps: int = maxi(1, ceili(movement.length() / 6.0))
	var step_delta: Vector2 = movement / float(steps)
	var result: Vector2 = point
	for step in range(steps):
		if can_stand(result + Vector2(step_delta.x, 0), radius):
			result.x += step_delta.x
		if can_stand(result + Vector2(0, step_delta.y), radius):
			result.y += step_delta.y
	return result

func set_realm(value: bool) -> void:
	veil = value
	queue_redraw()

func set_seals(values: Array[bool]) -> void:
	seals = values.duplicate()
	gate_open = not seals.is_empty() and seals.all(func(value: bool) -> bool: return value)
	queue_redraw()

func has_valid_layout() -> bool:
	return world_id > 0 and world_size.x > 0 and world_size.y > 0 and not tiles.is_empty() and can_stand(spawn_point)

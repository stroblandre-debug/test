extends SceneTree
## Integration suite; test saves never touch the player's actual save file.

const GameScript = preload("res://scripts/game.gd")
const WorldScript = preload("res://scripts/world.gd")
const SaveScript = preload("res://scripts/save_game.gd")
const TEST_SAVE: String = "user://veil_integration_test.json"
const INVALID_SAVE: String = "user://veil_invalid_test.json"
var checks: int = 0
var failures: Array[String] = []
var game: Node2D

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		printerr("FAIL: " + message)

func _run() -> void:
	DirAccess.remove_absolute(TEST_SAVE)
	DirAccess.remove_absolute(INVALID_SAVE)
	game = GameScript.new()
	game.save_path = TEST_SAVE
	root.add_child(game)
	game.sound.sound_enabled = false
	await process_frame
	_check(game.state == "menu", "title screen opens")
	_check(game.ui.size.x >= 1100, "HUD uses the configured viewport")
	game.start_game(false)
	await process_frame
	_check(game.state == "playing", "new game starts")
	_check(game.player.health == 5, "player starts with five hearts")
	_check(not game.save_failed, "first local save succeeds")
	_check(not game.change_veil(), "realm change is locked before meeting the keeper")
	_check(not game._complete_chapter(), "chapter cannot complete before the gate opens")
	_test_map()
	_test_touch()
	# The real dialogue drives the unlock and leaves no moving input behind.
	game.player.position = WorldScript.KEEPER + Vector2(0, 44)
	game.interact()
	_check(game.state == "dialogue", "keeper interaction starts dialogue")
	_check(game.player.locked, "dialogue freezes movement and combat")
	_check(not game.player.attack(), "cannot attack during dialogue")
	for line in range(5):
		game.advance_dialog()
	_check(game.progress["unlocked"], "finishing the keeper conversation unlocks the veil")
	_check(game.state == "playing", "dialogue returns to gameplay")
	_check(SaveScript.read_save(TEST_SAVE)["unlocked"], "unlock is persisted")
	_check(game.change_veil(), "veil can be entered on solid ground")
	_check(game.world.veil, "world changes to spirit realm")
	game.player.position = Vector2(1200, 504)
	_check(not game.change_veil(), "cannot leave the spirit realm over its bridge")
	_check(game.world.veil, "rejected transition preserves the current realm")
	game.player.position = WorldScript.SPAWN
	_check(game.change_veil(), "can leave veil after reaching solid ground")
	_check(not game.world.veil, "returns to material realm")
	# Combat uses the same attack signal and cooldown as real input.
	game.change_veil()
	for shade in get_nodes_in_group("shades"):
		shade.set_physics_process(false)
	var enemy: Node2D = get_nodes_in_group("shades")[0]
	game.player.position = WorldScript.SPAWN
	enemy.position = game.player.position + Vector2(44, 0)
	game.player.facing = Vector2.LEFT
	game.player.cooldown = 0
	_check(game.player.attack(), "first sword swing begins")
	_check(enemy.health == 2, "sword does not hit an enemy behind the player")
	_check(not game.player.attack(), "attack cooldown prevents instant repeated hits")
	for frame in range(25):
		await physics_frame
	game.player.facing = Vector2.RIGHT
	game.player.attack()
	_check(enemy.health == 1, "facing an enemy deals sword damage")
	for frame in range(25):
		await physics_frame
	game.player.attack()
	await process_frame
	_check(0 in game.progress["defeated"], "defeated enemy updates quest save")
	_check(get_nodes_in_group("shades").size() == 4, "defeated enemy disappears")
	game.player.invulnerable = 0
	_check(game.player.take_damage(1, game.player.position + Vector2.RIGHT * 30), "enemy hit damages the player")
	_check(game.player.health == 4, "damage removes one heart")
	_check(not game.player.take_damage(1, game.player.position), "invulnerability prevents repeated contact damage")
	game._pause()
	_check(game.state == "paused" and game.player.locked, "pause freezes gameplay")
	_check(game.touch.movement == Vector2.ZERO, "pause clears joystick input")
	game._resume()
	_check(game.state == "playing", "pause resumes correctly")
	# All shrines require both proximity and the spirit realm.
	game.player.position = WorldScript.SPAWN
	_check(not game.activate_seal(0), "distant shrine cannot be activated")
	game.change_veil()
	game.player.position = WorldScript.SHRINES[0]
	_check(not game.activate_seal(0), "material realm cannot activate a shrine")
	game.change_veil()
	for index in range(3):
		game.player.position = WorldScript.SHRINES[index] + Vector2(0, 28)
		_check(game.activate_seal(index), "shrine %d activates in the veil" % index)
		_check(not game.activate_seal(index), "shrine %d cannot activate twice" % index)
		_check(game.player.health == 5, "awakening a shrine heals")
	_check(game.world.gate_open, "three seals open the temple gate")
	_check(game.world.can_stand(WorldScript.GATE), "the opened gate is passable")
	game.player.position = WorldScript.PORTAL
	_check(game._complete_chapter(), "portal finishes the chapter after the three seals")
	_check(game.state == "complete", "chapter ending is displayed")
	var saved: Dictionary = SaveScript.read_save(TEST_SAVE)
	_check(saved["completed"] and saved["seals"].count(true) == 3, "completed chapter is persisted")
	game.start_game(true)
	await process_frame
	_check(game.world.gate_open, "load restores the gate")
	_check(game.player.position.distance_to(WorldScript.SPAWN) < 2, "load begins at a safe checkpoint")
	_check(not game.world.veil, "load begins in the material realm")
	_check(get_nodes_in_group("shades").size() == 4, "load does not respawn a defeated enemy")
	game.player.invulnerable = 0
	game.player.take_damage(5, WorldScript.KEEPER)
	_check(game.state == "fallen", "lethal hit opens recovery screen")
	game._respawn()
	_check(game.player.health == 5 and game.world.gate_open, "respawn heals and preserves the seals")
	_test_invalid_saves()
	game.queue_free()
	await process_frame
	for path in [TEST_SAVE, INVALID_SAVE, TEST_SAVE + ".tmp", INVALID_SAVE + ".tmp"]:
		DirAccess.remove_absolute(path)
	if failures.is_empty():
		print("PASS: %d integration checks" % checks)
		quit(0)
	else:
		printerr("FAILED: %d of %d checks" % [failures.size(), checks])
		quit(1)

func _test_map() -> void:
	var world: Node2D = game.world
	_check(world.can_stand(WorldScript.SPAWN), "spawn is on walkable ground")
	_check(not world.can_stand(Vector2(0, 0)), "world boundaries block movement")
	_check(not world.can_stand(Vector2(1200, 700)), "river blocks movement")
	_check(not world.can_stand(Vector2(1200, 504), 11, 0), "spirit bridge is absent in material realm")
	_check(world.can_stand(Vector2(1200, 504), 11, 1), "spirit bridge supports the player in the veil")
	_check(world.can_stand(Vector2(1200, 1032), 11, 0), "southern bridge works in the material realm")
	_check(not world.can_stand(WorldScript.GATE), "sealed gate blocks passage")
	var stopped: Vector2 = world.move_actor(Vector2(120, 300), Vector2(-1000, 0))
	_check(stopped.x >= 107, "substep collision prevents high-speed tunnelling")
	var reachable: Dictionary = _reachable_cells(world)
	for point in WorldScript.SHRINES + [WorldScript.KEEPER]:
		_check(reachable.has(Vector2i(point / world.TILE)), "quest location has a walkable material-world route: " + str(point))
	_check(not reachable.has(Vector2i(WorldScript.PORTAL / world.TILE)), "sealed temple cannot be bypassed")

func _reachable_cells(world: Node2D) -> Dictionary:
	var start: Vector2i = Vector2i(WorldScript.SPAWN / world.TILE)
	var queue: Array[Vector2i] = [start]
	var visited: Dictionary = {start: true}
	var cursor: int = 0
	while cursor < queue.size():
		var cell: Vector2i = queue[cursor]
		cursor += 1
		for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var candidate: Vector2i = cell + direction
			var center: Vector2 = Vector2(candidate) * world.TILE + Vector2.ONE * world.TILE / 2
			if not visited.has(candidate) and world.can_stand(center, 11, 0):
				visited[candidate] = true
				queue.append(candidate)
	return visited

func _test_touch() -> void:
	var touch: Control = game.touch
	touch.touch_visible = true
	touch.enabled = true
	var center: Vector2 = touch.stick_center
	touch._handle_touch(5, center + Vector2(64, 0), true)
	_check(touch.movement.x > 0.9, "touch joystick moves right")
	var attack_point: Vector2 = touch.actions["attack"]["point"]
	touch._handle_touch(9, attack_point, true)
	_check(touch.stick_id == 5 and touch.held_buttons.get(9) == "attack", "independent fingers support movement and attack")
	touch._handle_touch(9, attack_point, false)
	_check(touch.movement.x > 0.9 and touch.held_buttons.is_empty(), "releasing attack preserves joystick movement")
	touch._handle_touch(5, center, false)
	_check(touch.movement == Vector2.ZERO, "releasing joystick stops movement")
	touch._handle_touch(7, center + Vector2(40, 0), true)
	touch._notification(Control.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_check(touch.stick_id == -1 and touch.movement == Vector2.ZERO, "losing focus clears held touches")
	touch.touch_visible = false

func _test_invalid_saves() -> void:
	var file: FileAccess = FileAccess.open(INVALID_SAVE, FileAccess.WRITE)
	file.store_string("{broken json")
	file.close()
	_check(SaveScript.read_save(INVALID_SAVE).is_empty(), "corrupt save is rejected safely")
	var invalid: Dictionary = SaveScript.fresh()
	invalid["seals"] = [true]
	SaveScript.write_save(invalid, INVALID_SAVE)
	_check(SaveScript.read_save(INVALID_SAVE).is_empty(), "wrong number of seals is rejected")
	invalid = SaveScript.fresh()
	invalid["defeated"] = [1.5]
	SaveScript.write_save(invalid, INVALID_SAVE)
	_check(SaveScript.read_save(INVALID_SAVE).is_empty(), "fractional enemy identifiers are rejected")
	invalid = SaveScript.fresh()
	invalid["completed"] = true
	SaveScript.write_save(invalid, INVALID_SAVE)
	_check(SaveScript.read_save(INVALID_SAVE).is_empty(), "impossible completed state is rejected")

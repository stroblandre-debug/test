extends SceneTree
## Integration coverage for startup recovery, multiple worlds, and old saves.

const Catalog = preload("res://scripts/world_catalog.gd")
const ManagerScript = preload("res://scripts/world_manager.gd")
const BaseWorld = preload("res://scripts/base_world.gd")
const SaveScript = preload("res://scripts/save_game.gd")
const Preferences = preload("res://scripts/preferences.gd")
const GameScript = preload("res://scripts/game.gd")
const SAVE: String = "user://foundation_save_test.json"
const SETTINGS: String = "user://foundation_settings_test.cfg"
const REPORT: String = "user://foundation_startup_test.txt"
var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		printerr("FAIL: " + message)

func _clean() -> void:
	for path in [SAVE, SAVE + ".tmp", SAVE + ".v1.bak", SETTINGS, REPORT]:
		DirAccess.remove_absolute(path)

func _run() -> void:
	_clean()
	_test_catalog()
	_test_saves()
	_test_preferences()
	var manager: Node2D = ManagerScript.new()
	root.add_child(manager)
	_check(manager.load_world(1), "implemented garden scene loads")
	var original: Node2D = manager.active_world
	_check(original.has_valid_layout(), "loaded scene has a usable checkpoint")
	_check(original.can_stand(original.spawn_point), "checkpoint is on safe ground")
	_check(not manager.load_world(2), "a planned world cannot be loaded")
	_check(manager.active_world == original and manager.current_id == 1, "failed transition preserves the active world")
	_check(not manager.load_world(34), "out-of-range world cannot be loaded")
	_check(manager.active_world == original, "invalid world ID leaves scene intact")
	var empty: Node2D = BaseWorld.new()
	_check(not empty.has_valid_layout(), "an empty world is never accepted as playable")
	empty.free()
	manager.queue_free()
	await process_frame
	await process_frame
	var game: Node2D = GameScript.new()
	game.save_path = SAVE
	game.preferences_path = SETTINGS
	root.add_child(game)
	game.sound.sound_enabled = false
	_check(game.startup_ok, "game reports successful initialization")
	game._show_settings()
	_check(game.state == "settings" and game.player.locked, "title settings keep movement locked")
	var slider: HSlider = game.overlay.find_child("BrightnessSlider", true, false) as HSlider
	_check(slider != null, "brightness control is present")
	if slider != null:
		slider.value = 180
	_check(is_equal_approx(game.visual_root.modulate.r, 1.8), "brightness affects world rendering")
	game._close_settings()
	_check(game.state == "menu", "settings return to the title screen")
	_check(not FileAccess.file_exists(SAVE), "opening title settings never creates or overwrites quest progress")
	game.start_game(false)
	game.progress["unlocked"] = true
	game.progress["seals"][0] = true
	var before: Node2D = game.world
	var point: Vector2 = game.player.position
	_check(not game.enter_world(17), "planned cosmic horror world stays inaccessible")
	_check(game.world == before and game.player.position == point, "failed transition keeps scene and player position")
	_check(game.progress["seals"][0], "failed transition keeps quest progress")
	_check(game.enter_world(1), "implemented world can be re-entered")
	_check(game.world != before, "world transition really instantiates a new scene")
	_check(game.progress["seals"][0] and game.world.seals[0], "re-entry restores the world-specific quest snapshot")
	_check(game.player.world == game.world and game.minimap.world == game.world, "player and minimap follow the new world")
	_check(game.atmosphere.world == game.world, "world effects follow the new world")
	game._pause()
	game._show_settings()
	game._close_settings()
	_check(game.state == "paused", "pause settings return to pause")
	game.queue_free()
	await process_frame
	await process_frame
	var packed: PackedScene = load("res://scenes/startup.tscn") as PackedScene
	var boot: Control = packed.instantiate()
	boot.auto_start = false
	boot.report_path = REPORT
	root.add_child(boot)
	_check(boot.get_node("Center/Panel/Box/Swatches").is_visible_in_tree(), "standalone image test shows its color patches")
	boot.game_scene_path = "res://tests/fixtures/nonexistent.tscn"
	_check(not boot.start_game(), "missing main scene is caught")
	_check(not boot.last_error.is_empty() and boot.visible, "missing scene leaves a visible explanation")
	_check(boot.get_node("Center/Panel/Box/StartButton").visible, "failed startup exposes a retry button")
	boot.show_report()
	_check(boot.get_node("Center/Panel/Box/ReportPanel").visible, "startup report can be opened")
	_check(boot.report_text.contains("Godot:") and boot.report_text.contains("Renderer:"), "report contains engine and rendering information")
	_check(FileAccess.file_exists(REPORT), "startup report is saved locally")
	boot.game_scene_path = "res://tests/fixtures/empty_main.tscn"
	_check(not boot.start_game(), "main scene without its game script is caught")
	_check(boot.visible and not boot.last_error.is_empty(), "missing script leaves the fallback screen visible")
	boot.game_scene_path = "res://scenes/main.tscn"
	_check(boot.start_game(), "retry can launch the actual game")
	var launched: Node = boot.launched_game
	_check(launched != null and launched.startup_ok, "successful boot hands over to a fully initialized game")
	if launched != null:
		launched.queue_free()
	await process_frame
	await process_frame
	_clean()
	if failures.is_empty():
		print("PASS: %d foundation checks" % checks)
		quit(0)
	else:
		printerr("FAILED: %d of %d foundation checks" % [failures.size(), checks])
		quit(1)

func _test_catalog() -> void:
	var entries: Array[Dictionary] = Catalog.entries()
	_check(entries.size() == 33, "catalog reserves exactly 33 world positions")
	_check(Catalog.act_for(1) == 1 and Catalog.act_for(11) == 1, "act one spans positions 1 through 11")
	_check(Catalog.act_for(12) == 2 and Catalog.act_for(22) == 2, "act two spans positions 12 through 22")
	_check(Catalog.act_for(23) == 3 and Catalog.act_for(33) == 3, "act three spans positions 23 through 33")
	_check(Catalog.act_for(0) == 0 and Catalog.act_for(34) == 0, "invalid act positions are rejected")
	_check(Catalog.is_playable(1), "garden is implemented")
	_check(not Catalog.is_playable(2) and not Catalog.is_playable(17), "plans are not presented as finished worlds")
	_check(Catalog.find(17).get("title") == "Das Tal der erloschenen Sterne", "approved cosmic horror concept is retained")
	_check(Catalog.find(34).is_empty(), "unknown world lookup is safe")
	_check(Catalog.entries("user://does_not_exist_worlds.json").is_empty(), "missing catalog is rejected safely")

func _write_raw(value: Variant, path: String = SAVE) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(value))
	file.close()

func _test_saves() -> void:
	var first: Dictionary = SaveScript.fresh()
	first["unlocked"] = true
	first["seals"][0] = true
	first["defeated"] = [2]
	var second: Dictionary = SaveScript.for_world(first, 2)
	_check(second["current_world"] == 2 and second["seals"].count(true) == 0, "new world starts with a separate quest snapshot")
	_check(first["current_world"] == 1 and first["worlds"].is_empty(), "building another world's view does not mutate the original")
	second["unlocked"] = true
	second["seals"][1] = true
	_check(SaveScript.write_save(second, SAVE), "multi-world document writes successfully")
	var loaded: Dictionary = SaveScript.read_save(SAVE)
	_check(loaded["current_world"] == 2 and loaded["seals"][1], "multi-world load restores its active world")
	var back: Dictionary = SaveScript.for_world(loaded, 1)
	_check(back["seals"][0] and not back["seals"][1] and 2 in back["defeated"], "revisiting a world restores only that world's progress")
	_check(SaveScript.for_world(back, 2)["seals"][1], "revisiting another world preserves its own progress")
	_check(SaveScript.for_world(back, 34).is_empty(), "save helper rejects a world outside the 33-world plan")
	var good_bytes: PackedByteArray = FileAccess.get_file_as_bytes(SAVE)
	var invalid: Dictionary = back.duplicate(true)
	invalid["seals"] = "invalid"
	_check(not SaveScript.write_save(invalid, SAVE), "invalid progress cannot be written")
	_check(FileAccess.get_file_as_bytes(SAVE) == good_bytes, "failed save validation preserves the existing file")
	var legacy: Dictionary = {"version": 1, "unlocked": true, "seals": [true, false, true], "defeated": [1], "completed": false}
	_write_raw(legacy)
	var legacy_bytes: PackedByteArray = FileAccess.get_file_as_bytes(SAVE)
	var migrated: Dictionary = SaveScript.read_save(SAVE)
	_check(migrated.get("version") == 2 and migrated.get("current_world") == 1, "version-1 save migrates into the new journey format")
	_check(migrated["seals"] == [true, false, true] and migrated["defeated"] == [1], "migration preserves old seals and defeated enemies")
	_check(FileAccess.get_file_as_bytes(SAVE) == legacy_bytes, "reading a legacy save does not alter it")
	_check(SaveScript.write_save(migrated, SAVE), "migrated save can be written")
	_check(FileAccess.get_file_as_bytes(SAVE + ".v1.bak") == legacy_bytes, "first migrated write keeps an exact version-1 backup")
	_check(SaveScript.read_save(SAVE)["seals"] == [true, false, true], "new document reloads the migrated progress")
	migrated["seals"][1] = true
	SaveScript.write_save(migrated, SAVE)
	_check(FileAccess.get_file_as_bytes(SAVE + ".v1.bak") == legacy_bytes, "later writes preserve the original backup")
	_write_raw({"version": 2, "current_world": 1, "worlds": {"01": legacy}})
	_check(SaveScript.read_save(SAVE).is_empty(), "noncanonical world IDs are rejected")
	_write_raw({"version": 2, "current_world": 34, "worlds": {"1": legacy}})
	_check(SaveScript.read_save(SAVE).is_empty(), "out-of-range current world is rejected")
	DirAccess.remove_absolute(SAVE)

func _test_preferences() -> void:
	var config: RefCounted = Preferences.new()
	config.load_settings(SETTINGS)
	_check(is_equal_approx(config.brightness, 1.25), "default brightness makes the dark world more readable")
	config.brightness = 1.6
	config.sound_enabled = false
	_check(config.save_settings(SETTINGS), "display preferences can be saved")
	var reloaded: RefCounted = Preferences.new()
	reloaded.load_settings(SETTINGS)
	_check(is_equal_approx(reloaded.brightness, 1.6) and not reloaded.sound_enabled, "brightness and sound survive a settings reload")
	var file: ConfigFile = ConfigFile.new()
	file.set_value("display", "brightness", 9999)
	file.save(SETTINGS)
	reloaded.load_settings(SETTINGS)
	_check(is_equal_approx(reloaded.brightness, 1.8), "out-of-range brightness is clamped")
	file.set_value("display", "brightness", "broken")
	file.save(SETTINGS)
	var fresh: RefCounted = Preferences.new()
	fresh.load_settings(SETTINGS)
	_check(is_equal_approx(fresh.brightness, 1.25), "malformed brightness falls back to a usable default")
	DirAccess.remove_absolute(SETTINGS)

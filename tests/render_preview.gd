extends SceneTree
## Optional visual check. Requires a graphical display; writes only to build/.

const GameScript = preload("res://scripts/game.gd")
var game: Node2D

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("Use a graphical display for render_preview.gd.")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute("res://build/preview")
	var ignore: FileAccess = FileAccess.open("res://build/.gdignore", FileAccess.WRITE)
	ignore.close()
	game = GameScript.new()
	game.save_path = "user://veil_visual_check.json"
	game.preferences_path = "user://veil_visual_check.cfg"
	root.add_child(game)
	game.sound.sound_enabled = false
	await _capture("title")
	game.start_game(false)
	game.touch.touch_visible = true
	game.toast_time = 0
	game.toast_label.text = ""
	game._layout_ui()
	await _capture("garden")
	game._pause()
	game._show_settings()
	await _capture("settings")
	game._close_settings()
	game._resume()
	game.player.position = Vector2(432, 500)
	game.progress["unlocked"] = true
	game.change_veil()
	game.camera.position = game.player.position
	game.camera.reset_smoothing()
	game._refresh_hud()
	await _capture("veil")
	game.player.position = game.world.KEEPER + Vector2(0, 45)
	game.camera.position = game.player.position
	game.camera.reset_smoothing()
	game.interact()
	await _capture("dialogue")
	game.queue_free()
	await process_frame
	await process_frame
	var startup: PackedScene = load("res://scenes/startup.tscn") as PackedScene
	var boot: Control = startup.instantiate()
	boot.auto_start = false
	boot.report_path = "user://veil_visual_report.txt"
	root.add_child(boot)
	await _capture("bildtest")
	boot.game_scene_path = "res://tests/fixtures/empty_main.tscn"
	boot.start_game()
	await _capture("startfehler")
	boot.queue_free()
	await process_frame
	DirAccess.remove_absolute("user://veil_visual_check.json")
	DirAccess.remove_absolute("user://veil_visual_check.cfg")
	DirAccess.remove_absolute("user://veil_visual_report.txt")
	quit(0)

func _capture(file_name: String) -> void:
	for frame in range(4):
		await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	var error: Error = image.save_png("res://build/preview/%s.png" % file_name)
	if error != OK:
		printerr("Preview save failed: ", error)

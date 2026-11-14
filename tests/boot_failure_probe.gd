extends SceneTree
## Used by the isolated Python regression harness, including broken scripts.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed: PackedScene = load("res://scenes/startup.tscn") as PackedScene
	var boot: Control = packed.instantiate()
	boot.auto_start = false
	boot.report_path = "user://boot_regression_report.txt"
	root.add_child(boot)
	await process_frame
	var started: bool = boot.start_game()
	if not started and boot.visible and not boot.last_error.is_empty() and boot.get_node("Center/Panel/Box/StartButton").visible:
		print("EXPECTED_START_FAILURE_VISIBLE")
		boot.queue_free()
		await process_frame
		quit(0)
	else:
		printerr("FAIL: failed game did not leave a visible startup explanation")
		quit(1)

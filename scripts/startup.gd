extends Control
## Intentionally has no preloaded game scripts or imported fonts.
## The declarative scene stays visible if the game fails to compile or start.

@export var auto_start: bool = true
@export var game_scene_path: String = "res://scenes/main.tscn"
@export var report_path: String = "user://veil_startbericht.txt"
var launched_game: Node
var last_error: String = ""
var report_text: String = ""
var busy: bool = false
var report_shown: bool = false

func _ready() -> void:
	%StartButton.pressed.connect(start_game)
	%ReportButton.pressed.connect(show_report)
	%Status.text = "Die Reise wird vorbereitet …" if auto_start else "Sind Schrift, Farbfelder und das helle Quadrat sichtbar?\nDann funktioniert dieser einfache Bildtest."
	%Swatches.visible = not auto_start
	%Square.visible = not auto_start
	_update_report("Startbildschirm sichtbar.")
	if auto_start:
		%StartButton.hide()
		%ReportButton.hide()
		_start_after_first_frame()

func _start_after_first_frame() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	start_game()

func start_game() -> bool:
	if busy:
		return false
	busy = true
	last_error = ""
	if not ResourceLoader.exists(game_scene_path, "PackedScene"):
		return _failed("Die Spielszene fehlt. Bitte das vollständige ZIP neu importieren.")
	var packed: PackedScene = load(game_scene_path) as PackedScene
	if packed == null:
		return _failed("Die Spielszene konnte nicht gelesen werden. Der Startbericht hilft bei der Fehlersuche.")
	var candidate: Node = packed.instantiate()
	if candidate == null or candidate.get_script() == null:
		if candidate != null:
			candidate.free()
		return _failed("Ein Spielskript wurde nicht geladen. Bitte die erste rote Fehlermeldung in Godot fotografieren.")
	get_tree().root.add_child(candidate)
	if candidate.get("startup_ok") != true:
		get_tree().root.remove_child(candidate)
		candidate.queue_free()
		return _failed("Das Spiel hat den Start nicht abgeschlossen. Bitte die erste rote Fehlermeldung in Godot fotografieren.")
	launched_game = candidate
	_update_report("Spiel und Titelmenü erfolgreich gestartet.")
	get_tree().current_scene = candidate
	hide()
	queue_free()
	return true

func _failed(message: String) -> bool:
	busy = false
	last_error = message
	%Status.text = message
	%StartButton.text = "Erneut versuchen"
	%StartButton.show()
	%ReportButton.show()
	%Swatches.show()
	%Square.show()
	_update_report("Startfehler: " + message)
	return false

func _update_report(result: String) -> void:
	var version: Dictionary = Engine.get_version_info()
	var renderer: String = RenderingServer.get_current_rendering_method()
	report_text = "THE VEIL OF THE ÆON · STARTBERICHT 0.2\n"
	report_text += "Godot: %s\nSystem: %s\nAnzeige: %s\nRenderer: %s\n" % [str(version.get("string", "?")), OS.get_name(), DisplayServer.get_name(), renderer]
	report_text += "Fenster: %s\nStartszene vorhanden: %s\nErgebnis: %s\n" % [str(get_viewport_rect().size), str(ResourceLoader.exists(game_scene_path, "PackedScene")), result]
	report_text += "\nWenn auch der Bildtest schwarz bleibt: Im Editor den Renderer Compatibility / Kompatibilität prüfen und das Projekt neu starten. Bitte außerdem die genaue Godot-Version und die erste rote Fehlermeldung festhalten.\n"
	report_text += "Der Renderer wird bereits im Projekt auf Compatibility festgelegt. Ein Geräte- oder Editorfehler kann trotzdem außerhalb des Spielskripts liegen.\n"
	var file: FileAccess = FileAccess.open(report_path, FileAccess.WRITE)
	if file != null:
		file.store_string(report_text)
		file.close()
	%Report.text = report_text

func show_report() -> void:
	report_shown = not report_shown
	%ReportPanel.visible = report_shown
	%ReportButton.text = "Bericht schließen" if report_shown else "Startbericht anzeigen"

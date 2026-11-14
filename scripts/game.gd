extends Node2D
## Chapter I controller. UI, quest flow, and persistence orchestration.

const PlayerScript = preload("res://scripts/player.gd")
const ShadeScript = preload("res://scripts/shade.gd")
const TouchScript = preload("res://scripts/touch_controls.gd")
const SaveScript = preload("res://scripts/save_game.gd")
const AtmosphereScript = preload("res://scripts/atmosphere.gd")
const MinimapScript = preload("res://scripts/minimap.gd")
const SoundScript = preload("res://scripts/sound.gd")
const WorldManagerScript = preload("res://scripts/world_manager.gd")
const PreferencesScript = preload("res://scripts/preferences.gd")
const Catalog = preload("res://scripts/world_catalog.gd")

var world: Node2D
var player: Node2D
var entities: Node2D
var camera: Camera2D
var atmosphere: Node2D
var touch: Control
var minimap: Control
var sound: AudioStreamPlayer
var ui: Control
var hud: Control
var overlay: Control
var dialog: PanelContainer
var dialog_text: Label
var dialog_name: Label
var objective: Label
var hearts: Label
var progress_label: Label
var realm_label: Label
var prompt: Label
var toast_label: Label
var world_label: Label
var toast_time: float = 0.0
var state: String = "menu"
var progress: Dictionary = SaveScript.fresh()
var dialog_lines: Array[String] = []
var dialog_index: int = 0
var after_dialog: String = ""
var time: float = 0.0
var save_failed: bool = false
var save_path: String = SaveScript.SAVE_PATH
var serif: Font
var ready_for_notifications: bool = false
var startup_ok: bool = false
var has_started: bool = false
var visual_root: Node2D
var world_manager: Node2D
var preferences: RefCounted = PreferencesScript.new()
var preferences_path: String = PreferencesScript.PATH
var settings_return: String = "menu"

func _ready() -> void:
	setup_input()
	preferences.load_settings(preferences_path)
	var font_path: String = "res://assets/DejaVuSerif.ttf"
	serif = load(font_path) if ResourceLoader.exists(font_path) else ThemeDB.fallback_font
	visual_root = Node2D.new()
	add_child(visual_root)
	world_manager = WorldManagerScript.new()
	visual_root.add_child(world_manager)
	if not world_manager.load_world(1):
		return
	world = world_manager.active_world
	entities = Node2D.new()
	entities.y_sort_enabled = true
	visual_root.add_child(entities)
	player = PlayerScript.new()
	player.world = world
	player.position = world.spawn_point
	entities.add_child(player)
	player.attacked.connect(_on_attack)
	player.hurt.connect(_on_hurt)
	player.died.connect(_on_death)
	camera = Camera2D.new()
	camera.position = player.position
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(world.world_size.x)
	camera.limit_bottom = int(world.world_size.y)
	add_child(camera)
	atmosphere = AtmosphereScript.new()
	atmosphere.world = world
	atmosphere.z_index = 20
	visual_root.add_child(atmosphere)
	sound = SoundScript.new()
	add_child(sound)
	sound.sound_enabled = preferences.sound_enabled
	_apply_brightness(preferences.brightness)
	_build_ui()
	get_tree().auto_accept_quit = false
	ready_for_notifications = true
	_show_menu()
	if "--demo" in OS.get_cmdline_user_args():
		start_game(false)
		progress["unlocked"] = true
		world.set_realm(true)
		_spawn_enemies()
		_refresh_hud()
	startup_ok = true

func setup_input() -> void:
	var definitions: Dictionary = {
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN],
		"attack": [KEY_J, KEY_SPACE], "interact": [KEY_E, KEY_ENTER],
		"veil": [KEY_V, KEY_K], "pause_game": [KEY_ESCAPE, KEY_P],
	}
	for action in definitions:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in definitions[action]:
			var event: InputEventKey = InputEventKey.new()
			event.physical_keycode = key
			if not InputMap.action_has_event(action, event):
				InputMap.action_add_event(action, event)

func _build_ui() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	add_child(layer)
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui)
	ui.theme = _make_theme()
	hud = Control.new()
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(hud)
	var status_panel: PanelContainer = PanelContainer.new()
	status_panel.position = Vector2(22, 20)
	status_panel.custom_minimum_size = Vector2(345, 113)
	status_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.07, 0.08, 0.89)))
	hud.add_child(status_panel)
	var status: VBoxContainer = VBoxContainer.new()
	status.add_theme_constant_override("separation", 6)
	status_panel.add_child(status)
	world_label = _label("", 11, Color("b7b699"))
	status.add_child(world_label)
	var row: HBoxContainer = HBoxContainer.new()
	status.add_child(row)
	hearts = _label("", 23, Color("d6a083"))
	hearts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(hearts)
	progress_label = _label("", 14, Color("d9c18a"))
	row.add_child(progress_label)
	objective = _label("", 14, Color("e0dec9"))
	status.add_child(objective)
	realm_label = _label("", 12, Color("c1cbbb"))
	realm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hud.add_child(realm_label)
	var pause_button: Button = _button("Ⅱ", _pause)
	pause_button.name = "PauseButton"
	pause_button.custom_minimum_size = Vector2(48, 42)
	hud.add_child(pause_button)
	minimap = MinimapScript.new()
	minimap.world = world
	minimap.player = player
	minimap.size = Vector2(162, 119)
	hud.add_child(minimap)
	prompt = _label("", 16, Color("ece3c5"))
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(prompt)
	toast_label = _label("", 17, Color("f0e3b7"))
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(toast_label)
	touch = TouchScript.new()
	touch.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(touch)
	touch.action_requested.connect(_act)
	_build_dialogue()
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(overlay)
	ui.resized.connect(_layout_ui)
	_layout_ui()

func _layout_ui() -> void:
	if not is_instance_valid(ui) or not is_instance_valid(minimap):
		return
	var screen: Vector2 = ui.size
	realm_label.position = Vector2(screen.x - 362, 36)
	realm_label.size = Vector2(272, 24)
	hud.get_node("PauseButton").position = Vector2(screen.x - 70, 20)
	minimap.position = Vector2(screen.x - 184, 78)
	prompt.position = Vector2(230, screen.y - (282 if touch.touch_visible else 48))
	prompt.size = Vector2(screen.x - 460, 30)
	toast_label.position = Vector2(screen.x / 2 - 300, 145)
	toast_label.size = Vector2(600, 30)
	dialog.position = Vector2(maxf(28, screen.x / 2 - 350), screen.y - 194)
	dialog.size = Vector2(minf(700, screen.x - 56), 170)

func _build_dialogue() -> void:
	dialog = PanelContainer.new()
	dialog.add_theme_stylebox_override("panel", _panel_style(Color("0d2025")))
	ui.add_child(dialog)
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	dialog.add_child(vbox)
	dialog_name = _label("DER HÜTER", 12, Color("d5bd85"))
	vbox.add_child(dialog_name)
	dialog_text = _label("", 18, Color("e6e1ce"))
	dialog_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialog_text.custom_minimum_size = Vector2(0, 65)
	vbox.add_child(dialog_text)
	var next: Button = _button("Weiter  ›", advance_dialog)
	next.size_flags_horizontal = Control.SIZE_SHRINK_END
	vbox.add_child(next)
	dialog.hide()

func _make_theme() -> Theme:
	var theme: Theme = Theme.new()
	theme.default_font_size = 17
	theme.set_color("font_color", "Label", Color("e5dfc9"))
	for type in ["normal", "hover", "pressed", "focus"]:
		var style: StyleBoxFlat = _panel_style(Color("203b3c") if type == "hover" else Color("142d30"))
		style.border_color = Color("c7b480") if type in ["hover", "focus"] else Color("657968")
		style.content_margin_top = 10
		style.content_margin_bottom = 10
		theme.set_stylebox(type, "Button", style)
	theme.set_color("font_color", "Button", Color("e8dfc7"))
	theme.set_color("font_hover_color", "Button", Color("fff4d6"))
	return theme

func _panel_style(background: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = Color(0.66, 0.62, 0.45, 0.45)
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 13
	style.content_margin_bottom = 13
	return style

func _label(text: String, font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _button(text: String, callback: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 42)
	button.pressed.connect(callback)
	return button

func _overlay_box(width: float = 520) -> VBoxContainer:
	for child in overlay.get_children():
		overlay.remove_child(child)
		child.queue_free()
	overlay.show()
	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0.02, 0.055, 0.07, 0.83)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size.x = width
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.04, 0.105, 0.12, 0.96)))
	center.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 15)
	panel.add_child(box)
	return box

func _centered_label(text: String, font_size: int, color: Color) -> Label:
	var label: Label = _label(text, font_size, color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label

func _show_menu() -> void:
	_set_state("menu")
	hud.hide()
	dialog.hide()
	var box: VBoxContainer = _overlay_box(542)
	box.add_child(_centered_label("EIN SPIEL VON ANDRÉ  ·  PROTOTYP 0.2", 11, Color("9da995")))
	var title: Label = _centered_label("THE VEIL\nOF THE ÆON", 44, Color("e0d0a1"))
	title.add_theme_font_override("font", serif)
	box.add_child(title)
	box.add_child(_centered_label("KAPITEL I  ·  DER ERSTE SCHLEIER", 12, Color("b8c6b2")))
	box.add_child(_centered_label("Manche Tore öffnen sich erst,\nwenn du die Welt mit anderen Augen siehst.", 16, Color("c8cfbd")))
	var saved: Dictionary = SaveScript.read_save(save_path)
	if not saved.is_empty():
		box.add_child(_button("Reise fortsetzen", func() -> void: start_game(true)))
	box.add_child(_button("Neue Reise beginnen", _new_game_requested))
	box.add_child(_button("Bild & Ton", _show_settings))
	var help: Label = _centered_label("WASD / Pfeile · Bewegen     J / Leertaste · Schlagen\nE · Sprechen / Aktivieren     V · Schleier     Esc · Pause\nAuf dem Smartphone: Joystick und Aktionstasten", 13, Color("99aea2"))
	box.add_child(help)
	box.add_child(_centered_label("2D · Querformat · lokale Spielstände", 11, Color("6f9187")))

func _new_game_requested() -> void:
	if SaveScript.read_save(save_path).is_empty():
		start_game(false)
		return
	_set_state("confirm_new")
	var box: VBoxContainer = _overlay_box()
	box.add_child(_centered_label("Eine neue Reise?", 27, Color("e1d1a3")))
	box.add_child(_centered_label("Dein bisheriger lokaler Spielstand wird ersetzt.", 16, Color("c9ceba")))
	box.add_child(_button("Neu beginnen", func() -> void: start_game(false)))
	box.add_child(_button("Zurück", _show_menu))

func start_game(continue_saved: bool) -> void:
	var saved: Dictionary = SaveScript.read_save(save_path) if continue_saved else {}
	progress = saved if not saved.is_empty() else SaveScript.fresh()
	has_started = true
	var saved_world_id: int = int(progress.get("current_world", 1))
	if not Catalog.is_playable(saved_world_id):
		saved_world_id = 1
	if not enter_world(saved_world_id):
		has_started = false
		return
	overlay.hide()
	dialog.hide()
	hud.show()
	_set_state("playing")
	_save()
	_refresh_hud()
	_toast("Sprich mit dem Hüter am Lagerfeuer." if not progress["unlocked"] else "Deine Reise geht weiter. Die Siegel bleiben erhalten.")

func enter_world(world_id: int) -> bool:
	if not Catalog.is_playable(world_id):
		_toast("Der Weg in diese Welt hat sich noch nicht geöffnet.")
		return false
	var next_progress: Dictionary = SaveScript.for_world(progress, world_id)
	if next_progress.is_empty() or not world_manager.load_world(world_id):
		_toast("Die Welt konnte nicht geladen werden. Dein Fortschritt bleibt erhalten.")
		return false
	world = world_manager.active_world
	progress = next_progress
	player.world = world
	atmosphere.world = world
	atmosphere.bursts.clear()
	minimap.world = world
	camera.limit_right = int(world.world_size.x)
	camera.limit_bottom = int(world.world_size.y)
	var seals: Array[bool] = []
	for seal in progress["seals"]:
		seals.append(bool(seal))
	world.set_seals(seals)
	world.set_realm(false)
	player.respawn(world.spawn_point)
	camera.position = player.position
	camera.reset_smoothing()
	_spawn_enemies()
	_save()
	_refresh_hud()
	return true

func _spawn_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("shades"):
		enemy.remove_from_group("shades")
		enemy.queue_free()
	for index in range(world.enemy_positions.size()):
		if index in progress["defeated"]:
			continue
		var enemy: Node2D = ShadeScript.new()
		enemy.enemy_id = index
		enemy.home = world.enemy_positions[index]
		enemy.position = enemy.home
		enemy.world = world
		enemy.player = player
		enemy.locked = state != "playing"
		enemy.set_realm(world.veil)
		entities.add_child(enemy)
		enemy.add_to_group("shades")
		enemy.defeated.connect(_on_enemy_defeated)

func _set_state(value: String) -> void:
	state = value
	if is_instance_valid(player):
		player.locked = value != "playing"
		player.input_direction = Vector2.ZERO
	for enemy in get_tree().get_nodes_in_group("shades"):
		enemy.locked = value != "playing"
	if is_instance_valid(touch):
		touch.enabled = value == "playing"
		touch.reset()
	if is_instance_valid(prompt):
		prompt.visible = value == "playing"

func _physics_process(_delta: float) -> void:
	if state != "playing":
		return
	var keyboard: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	player.input_direction = (keyboard + touch.movement).limit_length(1)
	if Input.is_action_pressed("attack") or "attack" in touch.held_buttons.values():
		player.attack()

func _process(delta: float) -> void:
	time += delta
	if is_instance_valid(camera):
		camera.position = player.position
	if toast_time > 0:
		toast_time = maxf(0, toast_time - delta)
		toast_label.modulate.a = minf(1.0, toast_time)
	if state == "playing":
		_update_prompt()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game"):
		if state == "playing":
			_pause()
		elif state == "paused":
			_resume()
		elif state == "dialogue":
			advance_dialog()
		elif state == "settings":
			_close_settings()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact"):
		if state == "dialogue":
			advance_dialog()
		elif state == "playing":
			interact()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("veil") and state == "playing":
		change_veil()
		get_viewport().set_input_as_handled()

func _act(action: String) -> void:
	if state != "playing":
		return
	match action:
		"attack": player.attack()
		"interact": interact()
		"veil": change_veil()

func change_veil() -> bool:
	if state != "playing":
		return false
	if not progress["unlocked"]:
		_toast("Der Hüter kennt den Weg durch den Schleier. Sprich mit ihm.")
		return false
	var next_realm: int = 0 if world.veil else 1
	if not world.can_stand(player.position, 11, next_realm):
		_toast("Hier trägt dich nur die Geisterbrücke. Erreiche zuerst festen Boden.")
		return false
	world.set_realm(not world.veil)
	for enemy in get_tree().get_nodes_in_group("shades"):
		enemy.set_realm(world.veil)
	atmosphere.burst(player.position - Vector2(0, 12), Color("8ac8c5"))
	sound.cue(330 if world.veil else 220, 0.35, true)
	_refresh_hud()
	return true

func interact() -> void:
	if state != "playing":
		return
	if player.position.distance_to(world.keeper_position) < 85:
		player.heal()
		_refresh_hud()
		if not progress["unlocked"]:
			_open_dialog("DER HÜTER", [
				"Du bist erwacht. Dieser Garten liegt zwischen dem Sichtbaren und dem Verborgenen. Du suchst den Weg hinaus?",
				"Drei Siegel halten das nördliche Tor geschlossen: Erinnerung, Erkenntnis und Wille. Du findest sie auf der kleinen Karte.",
				"Mit V oder SCHLEIER wechselst du die Welt. Nur jenseits des Schleiers lassen sich die Siegel mit E oder AKTION wecken.",
				"Die Schatten können dich dort berühren. Schlage mit J, Leertaste oder SCHLAG. Die nördliche Brücke erscheint nur im Schleier; die südliche trägt dich immer.",
				"Kehre zu mir zurück, wenn du Heilung brauchst. Nun geh: Erkenntnis beginnt mit deinem ersten Schritt."
			], "unlock")
		else:
			_open_dialog("DER HÜTER", ["Deine Kraft ist erneuert. Aktiviere die drei Siegel im Schleier und betrete den Kreis hinter dem nördlichen Tor. Dein Fortschritt wird automatisch gespeichert."], "")
		return
	for index in range(world.shrine_positions.size()):
		if player.position.distance_to(world.shrine_positions[index]) < 78:
			activate_seal(index)
			return
	if player.position.distance_to(world.portal_position) < 72 and world.gate_open:
		_complete_chapter()
		return
	if player.position.distance_to(world.gate_position) < 105 and not world.gate_open:
		_toast("Das Tor wartet auf drei erwachte Siegel.")
	else:
		_toast("Gehe näher an den Hüter oder einen Siegelstein heran.")

func activate_seal(index: int) -> bool:
	if state != "playing" or index < 0 or index >= world.shrine_positions.size():
		return false
	if player.position.distance_to(world.shrine_positions[index]) >= 78:
		return false
	if progress["seals"][index]:
		_toast("Dieses Siegel ist bereits erwacht.")
		return false
	if not progress["unlocked"] or not world.veil:
		_toast("Der Stein bleibt stumm. Suche ihn jenseits des Schleiers auf.")
		return false
	progress["seals"][index] = true
	var values: Array[bool] = []
	for value in progress["seals"]:
		values.append(bool(value))
	world.set_seals(values)
	atmosphere.burst(world.shrine_positions[index] - Vector2(0, 24), Color("d8c68c"))
	player.heal()
	sound.cue(520 + index * 110, 0.6, true)
	_save()
	_refresh_hud()
	_toast("Drei Siegel erwacht. Das nördliche Tor ist offen!" if world.gate_open else "Siegel %s erwacht. Deine Kraft ist erneuert." % world.shrine_titles[index])
	return true

func _open_dialog(speaker: String, lines: Array[String], on_finish: String) -> void:
	_set_state("dialogue")
	dialog_lines = lines
	dialog_index = 0
	after_dialog = on_finish
	dialog_name.text = speaker
	dialog_text.text = dialog_lines[0]
	dialog.show()

func advance_dialog() -> void:
	if state != "dialogue":
		return
	dialog_index += 1
	if dialog_index < dialog_lines.size():
		dialog_text.text = dialog_lines[dialog_index]
		return
	dialog.hide()
	_set_state("playing")
	if after_dialog == "unlock":
		progress["unlocked"] = true
		_save()
		_toast("Der Schleier ist offen für dich. Drücke V oder SCHLEIER.")
	_refresh_hud()

func _on_attack(origin: Vector2, direction: Vector2) -> void:
	var hit: bool = false
	for enemy in get_tree().get_nodes_in_group("shades"):
		if enemy.take_hit(origin, direction):
			hit = true
			atmosphere.burst(enemy.position - Vector2(0, 15), Color("aacfc6"))
	sound.cue(180 if hit else 260, 0.12)

func _on_hurt() -> void:
	sound.cue(110, 0.25)
	_refresh_hud()

func _on_enemy_defeated(enemy_id: int, _point: Vector2) -> void:
	if enemy_id not in progress["defeated"]:
		progress["defeated"].append(enemy_id)
	_save()

func _on_death() -> void:
	_set_state("fallen")
	var box: VBoxContainer = _overlay_box()
	box.add_child(_centered_label("Der Schleier hält dich fest.", 28, Color("ddc69a")))
	box.add_child(_centered_label("Deine Siegel bleiben erhalten.\nDer Hüter ruft dich zurück ins Licht.", 17, Color("c2cbbd")))
	box.add_child(_button("Am Lagerfeuer erwachen", _respawn))

func _respawn() -> void:
	player.respawn(world.spawn_point)
	world.set_realm(false)
	_spawn_enemies()
	camera.position = player.position
	camera.reset_smoothing()
	overlay.hide()
	_set_state("playing")
	_refresh_hud()

func _pause() -> void:
	if state != "playing":
		return
	_set_state("paused")
	_save()
	var box: VBoxContainer = _overlay_box(460)
	box.add_child(_centered_label("Zwischen zwei Welten", 28, Color("dfcea0")))
	box.add_child(_centered_label("Dein Fortschritt ist lokal gespeichert." if not save_failed else "Speichern fehlgeschlagen. Prüfe den freien Speicher.", 15, Color("b9c6b5")))
	box.add_child(_button("Weiterreisen", _resume))
	box.add_child(_button("Bild & Ton", _show_settings))
	box.add_child(_button("Zum Titel", _show_menu))
	box.add_child(_centered_label("Gold: offene Siegel  ·  Türkis: erwachte Siegel\nDer helle Punkt auf der Karte bist du.", 13, Color("94aa9f")))

func _toggle_sound() -> void:
	sound.sound_enabled = not sound.sound_enabled
	preferences.sound_enabled = sound.sound_enabled
	preferences.save_settings(preferences_path)
	if not sound.sound_enabled:
		sound.stop()
	state = "playing"
	_pause()

func _resume() -> void:
	if state != "paused":
		return
	overlay.hide()
	_set_state("playing")

func _complete_chapter() -> bool:
	if state != "playing" or not world.gate_open or player.position.distance_to(world.portal_position) >= 72:
		return false
	progress["completed"] = true
	_save()
	_set_state("complete")
	sound.cue(660, 0.8, true)
	var box: VBoxContainer = _overlay_box(560)
	box.add_child(_centered_label("KAPITEL I VOLLENDET", 12, Color("a5c4b6")))
	var title: Label = _centered_label("Der erste Schleier fällt.", 32, Color("e2d0a0"))
	title.add_theme_font_override("font", serif)
	box.add_child(title)
	box.add_child(_centered_label("Erinnerung. Erkenntnis. Wille.\nDu erkennst das Tor als das, was es immer war:\neinen Anfang.", 18, Color("d0d7c6")))
	box.add_child(_centered_label("Danke fürs Spielen, André.\nHier endet der spielbare Prototyp 0.2.", 15, Color("a1b6a8")))
	box.add_child(_button("Garten weiter erkunden", func() -> void:
		_set_state("playing")
		overlay.hide()))
	box.add_child(_button("Zum Titel", _show_menu))
	return true

func _save() -> void:
	if not has_started:
		return
	progress["current_world"] = world_manager.current_id
	save_failed = not SaveScript.write_save(progress, save_path)
	if save_failed:
		_toast("Spielstand konnte nicht gespeichert werden.")

func _refresh_hud() -> void:
	var entry: Dictionary = Catalog.find(world.world_id)
	world_label.text = "WELT %d  ·  %s" % [world.world_id, str(entry.get("title", "")).to_upper()]
	hearts.text = "♥ ".repeat(player.health) + "♡ ".repeat(player.MAX_HEALTH - player.health)
	var count: int = progress["seals"].count(true)
	progress_label.text = "%d / 3 SIEGEL" % count
	objective.text = "Sprich mit dem Hüter am Lagerfeuer."
	if progress["unlocked"]:
		objective.text = "Wecke die drei Siegel im Schleier."
	if world.gate_open:
		objective.text = "Betritt den Kreis im nördlichen Tempel."
	realm_label.text = "◈  JENSEITS DES SCHLEIERS" if world.veil else "◇  DIE SICHTBARE WELT"
	realm_label.add_theme_color_override("font_color", Color("9ad4d0") if world.veil else Color("d9c394"))
	minimap.unlocked = progress["unlocked"]
	minimap.queue_redraw()

func _update_prompt() -> void:
	var action_key: String = "AKTION" if touch.touch_visible else "E"
	if player.position.distance_to(world.keeper_position) < 85:
		prompt.text = "[ %s ]  Mit dem Hüter sprechen / heilen" % action_key
		return
	for index in range(world.shrine_positions.size()):
		if player.position.distance_to(world.shrine_positions[index]) < 78:
			prompt.text = "[ %s ]  Siegel %s" % [action_key, world.shrine_titles[index]]
			return
	if world.gate_open and player.position.distance_to(world.portal_position) < 72:
		prompt.text = "[ %s ]  Die Schwelle überschreiten" % action_key
	elif touch.touch_visible:
		prompt.text = ""
	else:
		prompt.text = "WASD · Bewegen     J · Schlag     E · Aktion     V · Schleier"

func _toast(text: String) -> void:
	if not is_instance_valid(toast_label):
		return
	toast_label.text = text
	toast_label.modulate.a = 1
	toast_time = 5.5

func _notification(what: int) -> void:
	if not ready_for_notifications:
		return
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if has_started:
			_save()
		get_tree().quit()
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT and state == "playing":
		_pause()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if state == "playing":
			_pause()
		elif state == "paused":
			_resume()
		elif state == "settings":
			_close_settings()

func _apply_brightness(value: float) -> void:
	preferences.brightness = clampf(value, PreferencesScript.MIN_BRIGHTNESS, PreferencesScript.MAX_BRIGHTNESS)
	if is_instance_valid(visual_root):
		visual_root.modulate = Color(preferences.brightness, preferences.brightness, preferences.brightness)

func _show_settings() -> void:
	settings_return = "paused" if state == "paused" else "menu"
	_set_state("settings")
	var box: VBoxContainer = _overlay_box(540)
	box.add_child(_centered_label("Bild & Ton", 28, Color("e1d1a3")))
	box.add_child(_centered_label("Helligkeit der Spielwelt", 17, Color("d4d9c8")))
	var value_label: Label = _centered_label("%d %%" % roundi(preferences.brightness * 100), 18, Color("d8be85"))
	box.add_child(value_label)
	var brightness: HSlider = HSlider.new()
	brightness.name = "BrightnessSlider"
	brightness.min_value = PreferencesScript.MIN_BRIGHTNESS * 100
	brightness.max_value = PreferencesScript.MAX_BRIGHTNESS * 100
	brightness.step = 5
	brightness.value = preferences.brightness * 100
	brightness.custom_minimum_size.y = 46
	brightness.value_changed.connect(func(value: float) -> void:
		_apply_brightness(value / 100)
		value_label.text = "%d %%" % roundi(value))
	box.add_child(brightness)
	box.add_child(_button("Helligkeit zurücksetzen", func() -> void: brightness.value = PreferencesScript.DEFAULT_BRIGHTNESS * 100))
	var audio: CheckButton = CheckButton.new()
	audio.text = "Klänge einschalten"
	audio.custom_minimum_size.y = 44
	audio.button_pressed = sound.sound_enabled
	audio.toggled.connect(func(enabled: bool) -> void:
		sound.sound_enabled = enabled
		preferences.sound_enabled = enabled
		if not enabled:
			sound.stop())
	box.add_child(audio)
	box.add_child(_button("Bildtest öffnen", _open_image_test))
	box.add_child(_button("Zurück", _close_settings))

func _close_settings() -> void:
	preferences.save_settings(preferences_path)
	if settings_return == "paused":
		state = "playing"
		_pause()
	else:
		_show_menu()

func _open_image_test() -> void:
	preferences.save_settings(preferences_path)
	_save()
	get_tree().change_scene_to_file("res://scenes/bildtest.tscn")

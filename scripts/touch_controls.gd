extends Control
## Separate touch IDs allow walking + attacking + changing realm together.

signal action_requested(action: String)
var enabled: bool = false
var touch_visible: bool = false
var movement: Vector2 = Vector2.ZERO
var stick_id: int = -1
var stick_center: Vector2 = Vector2.ZERO
var stick_tip: Vector2 = Vector2.ZERO
var held_buttons: Dictionary = {}
var mouse_stick: bool = false
var stick_radius: float = 64.0
var actions: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	touch_visible = DisplayServer.is_touchscreen_available() or OS.has_feature("android")
	if "--touch" in OS.get_cmdline_user_args():
		touch_visible = true
	resized.connect(_layout)
	_layout()

func _layout() -> void:
	reset()
	stick_center = Vector2(112, size.y - 100)
	stick_tip = stick_center
	actions = {
		"attack": {"point": Vector2(size.x - 100, size.y - 100), "radius": 44.0, "text": "SCHLAG"},
		"interact": {"point": Vector2(size.x - 208, size.y - 76), "radius": 35.0, "text": "AKTION"},
		"veil": {"point": Vector2(size.x - 92, size.y - 208), "radius": 35.0, "text": "SCHLEIER"},
	}
	queue_redraw()

func reset() -> void:
	movement = Vector2.ZERO
	stick_id = -1
	held_buttons.clear()
	mouse_stick = false
	stick_tip = stick_center
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		reset()

func _input(event: InputEvent) -> void:
	if not enabled or not touch_visible:
		return
	if event is InputEventScreenTouch:
		_handle_touch(event.index, event.position, event.pressed)
	elif event is InputEventScreenDrag and event.index == stick_id:
		_move_stick(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_touch(-2, event.position, event.pressed)
	elif event is InputEventMouseMotion and stick_id == -2:
		_move_stick(event.position)

func _handle_touch(touch_id: int, point: Vector2, pressed: bool) -> void:
	if not pressed:
		if touch_id == stick_id:
			stick_id = -1
			movement = Vector2.ZERO
			stick_tip = stick_center
		held_buttons.erase(touch_id)
		queue_redraw()
		return
	if stick_id == -1 and point.distance_to(stick_center) < stick_radius * 1.5:
		stick_id = touch_id
		_move_stick(point)
		get_viewport().set_input_as_handled()
		return
	for action in actions:
		var data: Dictionary = actions[action]
		if point.distance_to(data["point"]) <= float(data["radius"]) + 8:
			held_buttons[touch_id] = action
			action_requested.emit(action)
			get_viewport().set_input_as_handled()
			queue_redraw()
			return

func _move_stick(point: Vector2) -> void:
	var offset: Vector2 = (point - stick_center).limit_length(stick_radius)
	stick_tip = stick_center + offset
	movement = offset / stick_radius if offset.length() > 9 else Vector2.ZERO
	queue_redraw()

func _draw() -> void:
	if not enabled or not touch_visible:
		return
	var rim: Color = Color(0.78, 0.76, 0.63, 0.38)
	draw_circle(stick_center, stick_radius + 9, Color(0.03, 0.09, 0.11, 0.55))
	draw_arc(stick_center, stick_radius, 0, TAU, 48, rim, 1.5)
	draw_circle(stick_tip, 25, Color(0.65, 0.76, 0.69, 0.28))
	draw_arc(stick_tip, 25, 0, TAU, 32, rim, 1)
	for action in actions:
		var data: Dictionary = actions[action]
		var point: Vector2 = data["point"]
		var radius: float = data["radius"]
		draw_circle(point, radius, Color(0.05, 0.13, 0.15, 0.72))
		if action in held_buttons.values():
			draw_circle(point, radius - 3, Color(0.6, 0.8, 0.7, 0.22))
		draw_arc(point, radius, 0, TAU, 40, rim, 1.5)
		var font: Font = ThemeDB.fallback_font
		var label: String = str(data["text"])
		var width: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		draw_string(font, point + Vector2(-width / 2, 4), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("e2ddc8"))

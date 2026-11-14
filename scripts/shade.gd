extends Node2D
## A telegraphed melee enemy. Logical state is independent of its drawing.

signal defeated(enemy_id: int, point: Vector2)
var enemy_id: int = 0
var world: Node2D
var player: Node2D
var home: Vector2 = Vector2.ZERO
var health: int = 2
var active: bool = false
var locked: bool = true
var state: String = "idle"
var timer: float = 0.0
var flash: float = 0.0
var time: float = 0.0
var knockback: Vector2 = Vector2.ZERO
var aim: Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
	time += delta
	flash = maxf(0.0, flash - delta)
	if locked or not active or health <= 0 or not is_instance_valid(player):
		queue_redraw()
		return
	var distance: float = position.distance_to(player.position)
	timer = maxf(0.0, timer - delta)
	match state:
		"idle", "chase":
			if distance < 48:
				state = "windup"
				timer = 0.7
				aim = player.position
			elif distance < 265:
				state = "chase"
				_move((player.position - position).normalized() * 83, delta)
			else:
				state = "idle"
				if position.distance_to(home) > 12:
					_move((home - position).normalized() * 45, delta)
		"windup":
			if timer <= 0:
				if distance < 66:
					player.take_damage(1, position)
				state = "recover"
				timer = 1.0
		"recover":
			if timer <= 0:
				state = "idle"
	if knockback.length() > 0:
		_move(knockback, delta)
		knockback = knockback.move_toward(Vector2.ZERO, 800 * delta)
	queue_redraw()

func _move(velocity: Vector2, delta: float) -> void:
	if is_instance_valid(world):
		position = world.move_actor(position, velocity * delta, 10)

func set_realm(value: bool) -> void:
	active = value
	state = "idle"
	timer = 0.0
	queue_redraw()

func take_hit(origin: Vector2, direction: Vector2) -> bool:
	if not active or health <= 0:
		return false
	var offset: Vector2 = position - origin
	if offset.length() > 78 or (offset.length() > 8 and direction.dot(offset.normalized()) < 0.05):
		return false
	health -= 1
	flash = 0.2
	knockback = offset.normalized() * 250
	state = "recover"
	timer = 0.75
	if health <= 0:
		defeated.emit(enemy_id, position)
		queue_free()
	return true

func _draw() -> void:
	if health <= 0:
		return
	var color: Color = Color("a5c5bc") if active else Color(0.5, 0.7, 0.65, 0.2)
	if flash > 0:
		color = Color("f5e7bc")
	var bob: float = sin(time * 3 + enemy_id) * 3
	if state == "windup":
		draw_arc(Vector2.ZERO, 40, 0, TAU * (1 - timer / 0.7), 32, Color("d58c75"), 3)
	draw_colored_polygon(PackedVector2Array([Vector2(-17, 8), Vector2(-12, -20 + bob), Vector2(-6, -29 + bob), Vector2(6, -29 + bob), Vector2(12, -20 + bob), Vector2(18, 8), Vector2(8, 3), Vector2(0, 10), Vector2(-8, 3)]), color.darkened(0.4))
	draw_circle(Vector2(0, -22 + bob), 9, color)
	draw_rect(Rect2(Vector2(-6, -24 + bob), Vector2(12, 6)), Color("20343a"))
	draw_circle(Vector2(-3, -22 + bob), 1.5, Color("e0b98b"))
	draw_circle(Vector2(3, -22 + bob), 1.5, Color("e0b98b"))
	if active and health < 2:
		draw_line(Vector2(-12, -39), Vector2(12, -39), Color("263d42"), 3)
		draw_line(Vector2(-12, -39), Vector2(0, -39), Color("c8b482"), 3)

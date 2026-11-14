extends Node2D

signal attacked(origin: Vector2, direction: Vector2)
signal hurt
signal died

const SPEED: float = 196.0
const MAX_HEALTH: int = 5
const ATTACK_TIME: float = 0.22
const ATTACK_COOLDOWN: float = 0.36
var world: Node2D
var input_direction: Vector2 = Vector2.ZERO
var facing: Vector2 = Vector2.DOWN
var health: int = MAX_HEALTH
var attack_time: float = 0.0
var cooldown: float = 0.0
var invulnerable: float = 0.0
var walking_time: float = 0.0
var locked: bool = true
var knockback: Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
	invulnerable = maxf(0.0, invulnerable - delta)
	cooldown = maxf(0.0, cooldown - delta)
	attack_time = maxf(0.0, attack_time - delta)
	if not locked and is_instance_valid(world):
		var direction: Vector2 = input_direction.limit_length(1.0)
		if direction.length() > 0.1 and attack_time <= 0:
			facing = direction.normalized()
			walking_time += delta * 12
		var speed_factor: float = 0.45 if attack_time > 0 else 1.0
		position = world.move_actor(position, (direction * SPEED * speed_factor + knockback) * delta)
	knockback = knockback.move_toward(Vector2.ZERO, 950 * delta)
	queue_redraw()

func attack() -> bool:
	if locked or cooldown > 0:
		return false
	cooldown = ATTACK_COOLDOWN
	attack_time = ATTACK_TIME
	attacked.emit(position, facing)
	queue_redraw()
	return true

func take_damage(amount: int, from_point: Vector2) -> bool:
	if locked or invulnerable > 0 or health <= 0:
		return false
	health = maxi(0, health - amount)
	invulnerable = 1.15
	knockback = (position - from_point).normalized() * 290
	hurt.emit()
	if health <= 0:
		died.emit()
	return true

func heal() -> void:
	health = MAX_HEALTH

func respawn(point: Vector2) -> void:
	position = point
	health = MAX_HEALTH
	invulnerable = 2.0
	knockback = Vector2.ZERO
	attack_time = 0.0
	cooldown = 0.0
	input_direction = Vector2.ZERO

func _draw() -> void:
	if invulnerable > 0 and int(invulnerable * 12) % 2 == 0:
		modulate.a = 0.45
	else:
		modulate.a = 1.0
	var moving: bool = input_direction.length() > 0.1 and not locked
	var bob: float = sin(walking_time) * 1.3 if moving else 0.0
	var stride: float = sin(walking_time) * 3 if moving else 0.0
	var cloak: Color = Color("bf7354")
	var points: PackedVector2Array = PackedVector2Array()
	for index in range(20):
		points.append(Vector2.from_angle(index * TAU / 20) * Vector2(15, 6) + Vector2(0, 7))
	draw_colored_polygon(points, Color(0, 0, 0, 0.32))
	draw_rect(Rect2(Vector2(-8, -1 + stride), Vector2(6, 10)), Color("303136"))
	draw_rect(Rect2(Vector2(2, -1 - stride), Vector2(6, 10)), Color("303136"))
	draw_colored_polygon(PackedVector2Array([Vector2(-13, 3), Vector2(-9, -22 + bob), Vector2(8, -22 + bob), Vector2(14, 3), Vector2(0, 7)]), cloak.darkened(0.15))
	draw_rect(Rect2(Vector2(-7, -19 + bob), Vector2(14, 19)), cloak)
	draw_line(Vector2(0, -18 + bob), Vector2(0, 2), cloak.lightened(0.18), 2)
	draw_circle(Vector2(0, -24 + bob), 10, cloak)
	var face_offset: Vector2 = facing * 3
	draw_rect(Rect2(Vector2(-6, -26 + bob) + face_offset, Vector2(12, 8)), Color("242b2d"))
	if facing.y >= -0.5:
		draw_line(Vector2(-3, -23 + bob) + face_offset, Vector2(3, -23 + bob) + face_offset, Color("e5d7b0"), 1)
	draw_line(Vector2(-13, -12 + bob), Vector2(-14, 1 + bob), Color("d9bf85"), 3)
	if attack_time > 0:
		var progress: float = 1.0 - attack_time / ATTACK_TIME
		var angle: float = facing.angle() - 1.2 + progress * 2.4
		var end: Vector2 = Vector2.from_angle(angle) * 54
		draw_arc(Vector2(0, -8), 47, facing.angle() - 1.25, angle, 18, Color(0.85, 0.94, 0.84, 0.75), 7)
		draw_line(Vector2(0, -8) + end * 0.32, Vector2(0, -8) + end, Color("e6ece0"), 4)
		draw_line(Vector2(0, -8) + end * 0.2, Vector2(0, -8) + end * 0.4, Color("c8ad76"), 5)

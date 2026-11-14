extends Node2D

var world: Node2D
var time: float = 0.0
var bursts: Array[Dictionary] = []

func _process(delta: float) -> void:
	time += delta
	for index in range(bursts.size() - 1, -1, -1):
		bursts[index]["life"] -= delta
		if bursts[index]["life"] <= 0:
			bursts.remove_at(index)
	queue_redraw()

func burst(point: Vector2, color: Color) -> void:
	bursts.append({"point": point, "color": color, "life": 0.7})

func _draw() -> void:
	if not is_instance_valid(world):
		return
	for index in range(45):
		var phase: float = index * 2.399
		var point: Vector2 = Vector2(140 + fmod(index * 137.7, 1630), 150 + fmod(index * 211.3, 1020))
		point += Vector2(sin(time * 0.3 + phase) * 22, cos(time * 0.5 + phase) * 12)
		var alpha: float = 0.15 + (sin(time + phase) + 1) * 0.18
		draw_circle(point, 2 if world.veil else 1.3, Color(0.6, 0.85, 0.78, alpha))
	if world.campfire_position.is_finite():
		_draw_fire()
	if world.gate_open:
		var portal: Vector2 = world.portal_position
		draw_arc(portal, 27 + sin(time * 2) * 2, time * 0.2, time * 0.2 + TAU * 0.8, 48, Color("99d9d1"), 3)
		for index in range(7):
			var offset: Vector2 = Vector2.from_angle(time + index * TAU / 7) * Vector2(19, 28)
			draw_circle(portal + offset, 2, Color("e1d5ad"))
	for burst_data in bursts:
		var progress: float = 1 - float(burst_data["life"]) / 0.7
		var color: Color = burst_data["color"]
		color.a = 1 - progress
		for index in range(10):
			var offset: Vector2 = Vector2.from_angle(index * TAU / 10) * (8 + progress * 40)
			draw_circle(burst_data["point"] + offset, 3 * (1 - progress) + 1, color)

func _draw_fire() -> void:
	var fire: Vector2 = world.campfire_position
	draw_circle(fire, 36, Color(0.9, 0.5, 0.18, 0.025))
	draw_circle(fire, 22, Color(0.9, 0.5, 0.18, 0.04))
	draw_colored_polygon(PackedVector2Array([fire + Vector2(-7, 5), fire + Vector2(-6, -9), fire + Vector2(0, -18 + sin(time * 11) * 3), fire + Vector2(7, 2)]), Color("d9a366"))
	draw_colored_polygon(PackedVector2Array([fire + Vector2(-3, 5), fire + Vector2(0, -8), fire + Vector2(4, 4)]), Color("f5d99a"))

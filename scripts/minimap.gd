extends Control

var world: Node2D
var player: Node2D
var unlocked: bool = false
var refresh_time: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	refresh_time += delta
	if refresh_time > 0.15:
		refresh_time = 0.0
		queue_redraw()

func _draw() -> void:
	if not is_instance_valid(world) or not is_instance_valid(player):
		return
	draw_style_box(_background(), Rect2(Vector2.ZERO, size))
	var origin: Vector2 = Vector2(10, 10)
	var scale_factor: float = (size.x - 20) / world.world_size.x
	for cell in world.tiles:
		var kind: String = world.tiles[cell]
		var p: Vector2 = origin + Vector2(cell) * world.cell_size * scale_factor
		var color: Color = Color("284138")
		if kind in ["water", "spirit_bridge"]:
			color = Color("30515e")
		elif kind in ["wall", "tree", "rock"]:
			color = Color("142724")
		draw_rect(Rect2(p, Vector2.ONE * (world.cell_size * scale_factor + 0.2)), color)
	if unlocked:
		for index in range(world.shrine_positions.size()):
			draw_circle(origin + world.shrine_positions[index] * scale_factor, 3, Color("7cd8c5") if world.seals[index] else Color("d7b67c"))
	draw_circle(origin + world.keeper_position * scale_factor, 2.5, Color("d3d5b0"))
	draw_circle(origin + world.portal_position * scale_factor, 3, Color("9bafce"))
	draw_circle(origin + player.position * scale_factor, 3, Color("f0e6c9"))

func _background() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.07, 0.08, 0.9)
	style.border_color = Color(0.66, 0.63, 0.48, 0.35)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	return style

extends "res://scripts/base_world.gd"
## Deterministic map and collision. All distances are world pixels.

const TILE: int = 48
const COLS: int = 40
const ROWS: int = 28
const SIZE: Vector2 = Vector2(COLS * TILE, ROWS * TILE)
const SPAWN: Vector2 = Vector2(864, 1104)
const KEEPER: Vector2 = Vector2(768, 1008)
const GATE: Vector2 = Vector2(912, 312)
const PORTAL: Vector2 = Vector2(912, 192)
const SHRINES: Array[Vector2] = [Vector2(432, 432), Vector2(1584, 432), Vector2(1488, 1056)]
const SHRINE_NAMES: Array[String] = ["ERINNERUNG", "ERKENNTNIS", "WILLE"]
const SHRINE_TITLES: Array[String] = ["der Erinnerung", "der Erkenntnis", "des Willens"]
const ENEMY_SPAWNS: Array[Vector2] = [Vector2(528, 528), Vector2(1440, 528), Vector2(1584, 960), Vector2(816, 576), Vector2(1104, 912)]

var decorations: Array[Vector3] = []

func _init() -> void:
	world_id = 1
	cell_size = TILE
	world_size = SIZE
	spawn_point = SPAWN
	keeper_position = KEEPER
	gate_position = GATE
	portal_position = PORTAL
	campfire_position = Vector2(792, 1132)
	shrine_positions = SHRINES.duplicate()
	shrine_titles = SHRINE_TITLES.duplicate()
	enemy_positions = ENEMY_SPAWNS.duplicate()
	seals = [false, false, false]

func _ready() -> void:
	z_index = -10
	build_map()
	queue_redraw()

func build_map() -> void:
	tiles.clear()
	decorations.clear()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 28112025
	for y in range(ROWS):
		for x in range(COLS):
			var tile: Vector2i = Vector2i(x, y)
			if x < 2 or y < 2 or x >= COLS - 2 or y >= ROWS - 2:
				tiles[tile] = "wall"
			elif x in [24, 25] and y >= 3 and y <= 24:
				tiles[tile] = "water"
			elif rng.randf() < 0.14 and not _protected(Vector2(x * TILE + 24, y * TILE + 24)):
				tiles[tile] = "tree" if rng.randf() < 0.8 else "rock"
			else:
				tiles[tile] = "floor"
			if tiles[tile] == "floor":
				decorations.append(Vector3(x * TILE + rng.randf_range(4, 44), y * TILE + rng.randf_range(4, 44), rng.randf()))
	# Clear reliable routes. Trees never depend on frame timing or save data.
	for y in range(7, 25):
		for x in range(17, 21):
			_set_floor(x, y)
	for y in [9, 10, 20, 21, 22]:
		for x in range(7, 35):
			if x not in [24, 25]:
				_set_floor(x, y)
	for y in range(8, 24):
		for x in [8, 9, 32, 33]:
			_set_floor(x, y)
	for center in SHRINES + [SPAWN, KEEPER] + ENEMY_SPAWNS:
		var cell: Vector2i = Vector2i(center / TILE)
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				_set_floor(cell.x + dx, cell.y + dy)
	for x in [24, 25]:
		tiles[Vector2i(x, 10)] = "spirit_bridge"
		tiles[Vector2i(x, 21)] = "bridge"
	# Temple walls and a two-tile sealed entrance.
	for y in range(2, 7):
		for x in range(15, 23):
			tiles[Vector2i(x, y)] = "wall" if (x in [15, 22] or y in [2, 6]) else "temple"
	for x in [18, 19]:
		tiles[Vector2i(x, 6)] = "gate"

func _set_floor(x: int, y: int) -> void:
	tiles[Vector2i(x, y)] = "floor"

func _protected(point: Vector2) -> bool:
	for center in SHRINES + [SPAWN, KEEPER, GATE]:
		if point.distance_to(center) < 135:
			return true
	return false

func _draw() -> void:
	var grass: Color = Color("172e30") if veil else Color("233d35")
	var stone: Color = Color("4b5c59") if veil else Color("556253")
	var gold: Color = Color("d1b781")
	draw_rect(Rect2(Vector2.ZERO, SIZE), Color("09171e"))
	for y in range(ROWS):
		for x in range(COLS):
			var p: Vector2 = Vector2(x * TILE, y * TILE)
			var kind: String = str(tiles.get(Vector2i(x, y), "wall"))
			var variation: float = float((x * 7 + y * 13) % 5) * 0.012
			draw_rect(Rect2(p, Vector2(TILE, TILE)), grass.lightened(variation))
			if kind in ["water", "bridge", "spirit_bridge"]:
				draw_rect(Rect2(p, Vector2(TILE, TILE)), Color("142a40") if veil else Color("183b43"))
				for line in range(3):
					var wave: Vector2 = p + Vector2(8 + (x + y + line) % 7, 10 + line * 13)
					draw_line(wave, wave + Vector2(17, 0), Color(0.4, 0.7, 0.7, 0.13), 1)
			if kind == "bridge" or (kind == "spirit_bridge" and veil):
				var bridge_color: Color = Color("5c888e") if kind == "spirit_bridge" else Color("817155")
				for plank in range(4):
					draw_rect(Rect2(p + Vector2(0, plank * 12 + 2), Vector2(48, 9)), bridge_color)
				draw_line(p + Vector2(4, 0), p + Vector2(4, 48), gold.darkened(0.3), 2)
				draw_line(p + Vector2(44, 0), p + Vector2(44, 48), gold.darkened(0.3), 2)
			elif kind == "temple":
				draw_rect(Rect2(p + Vector2.ONE, Vector2(46, 46)), stone.darkened(0.28))
				draw_rect(Rect2(p + Vector2(5, 5), Vector2(38, 38)), stone.darkened(0.19), false, 1)
			elif kind == "wall":
				if y >= 2 and y <= 6 and x >= 15 and x <= 22:
					draw_rect(Rect2(p + Vector2(0, 8), Vector2(48, 40)), Color("1b292b"))
					draw_rect(Rect2(p, Vector2(48, 30)), stone)
					draw_rect(Rect2(p + Vector2(2, 2), Vector2(44, 8)), stone.lightened(0.13))
					draw_line(p + Vector2(24, 12), p + Vector2(24, 28), stone.darkened(0.25), 2)
				else:
					_draw_tree(p + Vector2(24, 30), x + y, true)
			elif kind == "tree":
				_draw_tree(p + Vector2(24, 30), x + y, false)
			elif kind == "rock":
				_draw_oval(p + Vector2(24, 37), Vector2(20, 9), Color(0, 0, 0, 0.2))
				draw_colored_polygon(PackedVector2Array([p + Vector2(6, 31), p + Vector2(12, 11), p + Vector2(31, 8), p + Vector2(42, 30), p + Vector2(30, 39)]), stone.darkened(0.12))
				draw_line(p + Vector2(12, 11), p + Vector2(31, 8), stone.lightened(0.2), 2)
			elif kind == "gate":
				draw_rect(Rect2(p, Vector2(48, 48)), stone.darkened(0.3))
				if not gate_open:
					for bar in range(4):
						draw_line(p + Vector2(6 + bar * 12, 0), p + Vector2(6 + bar * 12, 48), gold, 3)
	for decoration in decorations:
		var p: Vector2 = Vector2(decoration.x, decoration.y)
		if tile_at(p) != "floor":
			continue
		if decoration.z < 0.4:
			draw_line(p, p + Vector2(2, -5), grass.lightened(0.17), 1)
			draw_line(p + Vector2(4, 0), p + Vector2(5, -3), grass.lightened(0.13), 1)
		elif decoration.z > 0.92:
			draw_circle(p, 1.5, Color("88afb4") if veil else Color("a09976"))
	# Broken processional path, shrine circles, and the temple threshold.
	for index in range(19):
		var p: Vector2 = Vector2(886 + (index % 2) * 23, 1010 - index * 34)
		draw_rect(Rect2(p, Vector2(26, 19)), stone.darkened(0.28))
	for index in range(SHRINES.size()):
		_draw_shrine(SHRINES[index], index, gold, stone)
	_draw_keeper()
	_draw_campfire()
	_draw_oval(PORTAL + Vector2(0, 12), Vector2(43, 20), Color("1a343c"))
	draw_arc(PORTAL, 42, 0, TAU, 48, gold.darkened(0.35), 2)
	draw_arc(PORTAL, 34, 0, TAU, 48, Color("76b8b3") if gate_open else Color("34474a"), 2)
	for angle_index in range(8):
		var direction: Vector2 = Vector2.from_angle(angle_index * TAU / 8)
		draw_line(PORTAL + direction * 46, PORTAL + direction * 51, gold, 2)

func _draw_tree(p: Vector2, seed_value: int, border: bool) -> void:
	var shade: Color = Color("18343d") if veil else Color("1c382e")
	if border:
		shade = shade.darkened(0.25)
	_draw_oval(p + Vector2(4, 12), Vector2(26, 11), Color(0, 0, 0, 0.24))
	draw_rect(Rect2(p + Vector2(-4, -8), Vector2(9, 26)), Color("443f35"))
	var offset: float = float(seed_value % 3) * 2
	draw_colored_polygon(PackedVector2Array([p + Vector2(-31, -7), p + Vector2(-21, -29), p + Vector2(-9, -30), p + Vector2(0, -49 - offset), p + Vector2(18, -31), p + Vector2(28, -24), p + Vector2(34, -7), p + Vector2(15, 5), p + Vector2(-12, 3)]), shade)
	draw_colored_polygon(PackedVector2Array([p + Vector2(-22, -20), p + Vector2(0, -45 - offset), p + Vector2(20, -23), p + Vector2(7, -16), p + Vector2(-4, -20)]), shade.lightened(0.07))
	draw_line(p + Vector2(-21, -10), p + Vector2(-8, -8), shade.lightened(0.11), 2)

func _draw_shrine(p: Vector2, index: int, gold: Color, stone: Color) -> void:
	_draw_oval(p + Vector2(0, 15), Vector2(47, 22), Color(0, 0, 0, 0.22))
	draw_arc(p, 52, 0, TAU, 48, gold.darkened(0.6), 1)
	for line in range(3):
		draw_rect(Rect2(p + Vector2(-25 + line * 4, 6 - line * 6), Vector2(50 - line * 8, 9)), stone.darkened(0.25 - line * 0.05))
	draw_rect(Rect2(p + Vector2(-13, -39), Vector2(26, 40)), stone)
	draw_rect(Rect2(p + Vector2(-16, -43), Vector2(32, 7)), stone.lightened(0.1))
	var rune: Color = Color("8de0d2") if seals[index] else (gold if veil else stone.darkened(0.2))
	if index == 0:
		draw_circle(p + Vector2(0, -24), 6, rune, false, 2)
	elif index == 1:
		draw_arc(p + Vector2(0, -25), 7, 0.7, 5.6, 16, rune, 2)
	else:
		draw_line(p + Vector2(0, -32), p + Vector2(0, -17), rune, 2)
		draw_line(p + Vector2(-7, -25), p + Vector2(7, -25), rune, 2)
	if seals[index]:
		draw_arc(p, 42, 0, TAU, 40, Color(0.5, 0.9, 0.8, 0.5), 2)

func _draw_keeper() -> void:
	var p: Vector2 = KEEPER
	_draw_oval(p + Vector2(0, 8), Vector2(16, 7), Color(0, 0, 0, 0.35))
	draw_colored_polygon(PackedVector2Array([p + Vector2(-13, 5), p + Vector2(-8, -21), p + Vector2(7, -21), p + Vector2(14, 5)]), Color("a49b7b"))
	draw_circle(p + Vector2(0, -22), 9, Color("d9ceb0"))
	draw_rect(Rect2(p + Vector2(-8, -25), Vector2(16, 7)), Color("263737"))
	draw_line(p + Vector2(17, 9), p + Vector2(17, -32), Color("aa8b59"), 2)
	draw_circle(p + Vector2(17, -34), 3, Color("c9e9d8"))

func _draw_campfire() -> void:
	var p: Vector2 = Vector2(792, 1140)
	_draw_oval(p, Vector2(22, 10), Color("111f21"))
	for index in range(6):
		draw_circle(p + Vector2.from_angle(index * TAU / 6) * Vector2(19, 8), 4, Color("6b705d"))
	draw_line(p + Vector2(-11, 3), p + Vector2(11, -4), Color("745746"), 5)
	draw_line(p + Vector2(-10, -4), p + Vector2(11, 3), Color("745746"), 5)

func _draw_oval(center: Vector2, radius: Vector2, color: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for index in range(24):
		points.append(center + Vector2.from_angle(index * TAU / 24) * radius)
	draw_colored_polygon(points, color)

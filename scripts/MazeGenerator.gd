extends Node2D
class_name MazeGenerator

const BASE_TILE_SIZE := 64
const ATLAS_COLUMNS := 12
const SOURCE_ID := 0
const TILESET_TEXTURE_PATH := "res://assets/tiles/zaita-tileset.png"
const ROAD_FLOOR_SHADER := preload("res://assets/shaders/road_floor_gray.gdshader")
const ROAD_MARGIN := 1
const ROAD_NORTH := 1
const ROAD_EAST := 2
const ROAD_SOUTH := 4
const ROAD_WEST := 8
const ROAD_LOOP_CHANCE := 0.18
const ROAD_FLOOR_VARIATION_CHANCE := 0.18
const HOUSE_EDGE_FLOOR_VARIATION_CHANCE := 0.72
const ROAD_FLOOR_SOURCE_INSET := 2
const ROAD_FLOOR_MARGIN := 2.0
const ROAD_DIRECTIONS := [
	{"delta": Vector2i.UP, "bit": ROAD_NORTH, "opposite": ROAD_SOUTH},
	{"delta": Vector2i.RIGHT, "bit": ROAD_EAST, "opposite": ROAD_WEST},
	{"delta": Vector2i.DOWN, "bit": ROAD_SOUTH, "opposite": ROAD_NORTH},
	{"delta": Vector2i.LEFT, "bit": ROAD_WEST, "opposite": ROAD_EAST},
]
# The PNG is a visual catalog, not a regular tile grid. The regions below map
# the selected sections into a runtime atlas and layered decorations.
const TILE_GROUP_ORDER := [
	"floors",
	"alleys",
	"small_houses",
	"medium_houses",
	"roofs",
	"walls",
	"stairs",
	"urban_objects",
	"childhood_details",
	"shadows",
]
const TILE_REGIONS := {
	# 1. CHAO - PISOS
	"floors": [
		Rect2i(25, 63, 140, 155), Rect2i(170, 63, 139, 155),
		Rect2i(315, 63, 146, 155), Rect2i(467, 63, 151, 155),
		Rect2i(624, 63, 162, 155), Rect2i(792, 63, 165, 155),
		Rect2i(963, 63, 160, 155), Rect2i(25, 225, 140, 158),
		Rect2i(170, 225, 139, 158), Rect2i(315, 225, 146, 158),
		Rect2i(467, 225, 151, 158), Rect2i(624, 225, 162, 158),
		Rect2i(792, 225, 165, 158), Rect2i(963, 225, 160, 158),
		Rect2i(25, 390, 140, 160), Rect2i(170, 390, 139, 160),
		Rect2i(315, 390, 146, 160), Rect2i(467, 390, 151, 160),
		Rect2i(624, 390, 162, 160), Rect2i(792, 390, 165, 160),
		Rect2i(963, 390, 160, 160),
	],
	# 2. BECOS - CAMINHOS
	"alleys": [
		Rect2i(1195, 63, 94, 184), Rect2i(1350, 67, 141, 295),
		Rect2i(1485, 64, 149, 183), Rect2i(1681, 63, 92, 184),
		Rect2i(1763, 63, 155, 502), Rect2i(1195, 281, 295, 285),
		Rect2i(1541, 281, 247, 284),
	],
	# 3. CASAS PEQUENAS
	"small_houses": [
		Rect2i(1998, 70, 123, 177), Rect2i(2159, 69, 137, 178),
		Rect2i(2336, 70, 147, 177), Rect2i(2525, 70, 141, 177),
		Rect2i(2708, 69, 142, 178), Rect2i(2891, 67, 151, 180),
		Rect2i(1998, 264, 123, 202), Rect2i(2156, 264, 139, 202),
		Rect2i(2336, 264, 147, 202), Rect2i(2525, 264, 159, 202),
		Rect2i(2726, 265, 168, 201), Rect2i(2930, 264, 112, 201),
	],
	# 4. CASAS MEDIAS
	"medium_houses": [
		Rect2i(29, 665, 202, 275), Rect2i(265, 665, 219, 275),
		Rect2i(520, 655, 177, 284), Rect2i(724, 641, 272, 299),
		Rect2i(28, 962, 211, 280), Rect2i(266, 962, 218, 280),
		Rect2i(522, 961, 201, 284), Rect2i(767, 959, 229, 283),
	],
	# 5. TELHADOS
	"roofs": [
		Rect2i(1080, 654, 201, 121), Rect2i(1296, 654, 201, 121),
		Rect2i(1513, 651, 196, 148), Rect2i(1729, 651, 201, 138),
		Rect2i(1080, 805, 201, 138), Rect2i(1296, 805, 201, 138),
		Rect2i(1516, 805, 196, 141), Rect2i(1729, 804, 201, 141),
		Rect2i(1080, 962, 229, 280), Rect2i(1349, 965, 256, 277),
		Rect2i(1662, 804, 258, 438),
	],
	# 6. PAREDES
	"walls": [
		Rect2i(2001, 668, 197, 105), Rect2i(2233, 668, 179, 105),
		Rect2i(2447, 666, 171, 107), Rect2i(2652, 659, 177, 113),
		Rect2i(2865, 643, 175, 129), Rect2i(2002, 793, 198, 137),
		Rect2i(2234, 808, 177, 122), Rect2i(2447, 806, 170, 124),
		Rect2i(2652, 794, 177, 136), Rect2i(2865, 791, 175, 139),
		Rect2i(2002, 949, 234, 155), Rect2i(2274, 950, 289, 150),
		Rect2i(2598, 969, 193, 131), Rect2i(2828, 948, 211, 155),
		Rect2i(2002, 1118, 320, 134), Rect2i(2365, 1136, 232, 116),
		Rect2i(2634, 1136, 173, 115), Rect2i(2850, 1116, 190, 135),
	],
	# 7. ESCADAS
	"stairs": [
		Rect2i(33, 1343, 94, 181), Rect2i(156, 1341, 96, 181),
		Rect2i(284, 1341, 98, 183), Rect2i(429, 1341, 97, 181),
		Rect2i(33, 1544, 94, 156), Rect2i(156, 1545, 97, 156),
		Rect2i(284, 1570, 102, 130), Rect2i(420, 1590, 106, 111),
	],
	# 10. OBJETOS URBANOS
	"urban_objects": [
		Rect2i(2027, 1343, 65, 97), Rect2i(2126, 1346, 49, 91),
		Rect2i(2203, 1360, 72, 79), Rect2i(2305, 1344, 60, 92),
		Rect2i(2393, 1342, 60, 95), Rect2i(2519, 1349, 85, 87),
		Rect2i(2635, 1342, 60, 92), Rect2i(2728, 1353, 68, 78),
		Rect2i(2834, 1343, 69, 91), Rect2i(2935, 1334, 102, 100),
		Rect2i(2014, 1461, 102, 127), Rect2i(2135, 1467, 95, 119),
		Rect2i(2262, 1491, 78, 89), Rect2i(2380, 1484, 79, 97),
		Rect2i(2496, 1483, 48, 100), Rect2i(2583, 1524, 50, 61),
		Rect2i(2685, 1462, 57, 126), Rect2i(2772, 1459, 69, 129),
		Rect2i(2869, 1526, 98, 63), Rect2i(2844, 1454, 193, 239),
		Rect2i(2020, 1613, 58, 82), Rect2i(2105, 1614, 45, 80),
		Rect2i(2183, 1617, 62, 74), Rect2i(2278, 1619, 97, 72),
		Rect2i(2404, 1620, 88, 72), Rect2i(2522, 1625, 56, 65),
		Rect2i(2611, 1617, 46, 75), Rect2i(2693, 1616, 49, 76),
		Rect2i(2775, 1607, 59, 85), Rect2i(2883, 1620, 53, 71),
	],
	# 11. DETALHES DE INFANCIA
	"childhood_details": [
		Rect2i(30, 1798, 146, 221), Rect2i(182, 1798, 146, 221),
		Rect2i(349, 1798, 131, 221), Rect2i(489, 1797, 209, 222),
		Rect2i(706, 1798, 126, 221), Rect2i(854, 1798, 107, 215),
	],
	# 12. SOMBRAS / OVERLAYS
	"shadows": [
		Rect2i(1014, 1798, 133, 215), Rect2i(1165, 1798, 107, 215),
		Rect2i(1290, 1798, 100, 215), Rect2i(1409, 1797, 130, 216),
		Rect2i(1557, 1798, 107, 215), Rect2i(1715, 1798, 139, 215),
		Rect2i(1893, 1798, 120, 215),
	],
}
const BLOCKING_GROUPS := ["small_houses", "medium_houses", "roofs", "walls", "stairs"]
const ROAD_DECORATION_GROUPS := ["urban_objects", "childhood_details"]

@export_category("Maze")
# TODO: Change the maze size here or in the Main scene Inspector.
@export_range(24, 100, 1) var map_width: int = 50
@export_range(24, 100, 1) var map_height: int = 50
@export_range(48, 128, 1) var tile_size: int = 80
# TODO: Change the collectible quantity here or in the Main scene Inspector.
@export_range(1, 30, 1) var collectible_count: int = 8
@export var random_seed: int = 0

@export_category("Neighborhood")
@export_range(2, 5, 1) var road_width: int = 3
@export_range(4, 9, 1) var block_size: int = 5
@export_range(0.02, 0.3, 0.01) var plaza_chance: float = 0.11

@onready var streets: TileMapLayer = $Streets
@onready var road_visuals: Node2D = $RoadVisuals
@onready var houses: TileMapLayer = $Houses
@onready var decorations: Node2D = $Decorations
@onready var overlays: Node2D = $Overlays
@onready var world_bounds: StaticBody2D = $WorldBounds

var _rng := RandomNumberGenerator.new()
var _walkable_cells: Array[Vector2i] = []
var _blocked_cells: Array[Vector2i] = []
var _road_cells: Array[Vector2i] = []
var _plaza_cells: Array[Vector2i] = []
var _road_nodes: Array[Vector2i] = []
var _road_edges: Array[Dictionary] = []
var _road_connections: Dictionary = {}
var _atlas_cells_by_group: Dictionary = {}
var _region_queues: Dictionary = {}
var _runtime_tile_set: TileSet
var _source_texture: Texture2D
var _road_floor_material: ShaderMaterial


func generate() -> Dictionary:
	_configure_random()
	_ensure_runtime_tile_set()
	streets.clear()
	houses.clear()
	_clear_visual_layers()
	_walkable_cells.clear()
	_blocked_cells.clear()
	_road_cells.clear()
	_plaza_cells.clear()
	_road_nodes.clear()
	_road_edges.clear()
	_road_connections.clear()
	_region_queues.clear()

	var layout := _build_neighborhood_layout()
	_paint_tiles(layout)
	_paint_road_visuals()
	_ensure_world_bounds()
	var spawn_cell := _pick_spawn_cell()
	_place_neighborhood_details(spawn_cell)

	return {
		"spawn_cell": spawn_cell,
		"walkable_cells": _walkable_cells.duplicate(),
	}


func pick_collectible_cells(count: int, spawn_cell: Vector2i) -> Array[Vector2i]:
	var distant_cells: Array[Vector2i] = []
	var nearby_cells: Array[Vector2i] = []

	for cell in _road_cells:
		if cell == spawn_cell:
			continue
		if abs(cell.x - spawn_cell.x) + abs(cell.y - spawn_cell.y) >= 5:
			distant_cells.append(cell)
		else:
			nearby_cells.append(cell)

	_shuffle(distant_cells)
	_shuffle(nearby_cells)
	distant_cells.append_array(nearby_cells)

	var chosen_cells: Array[Vector2i] = []
	var limit: int = mini(count, distant_cells.size())
	for index in range(limit):
		chosen_cells.append(distant_cells[index])
	return chosen_cells


func cell_to_global_position(cell: Vector2i) -> Vector2:
	var local_position := Vector2(
		cell.x * tile_size + tile_size * 0.5,
		cell.y * tile_size + tile_size * 0.5
	)
	return to_global(local_position)


func get_global_pixel_rect() -> Rect2:
	var top_left := to_global(Vector2.ZERO)
	return Rect2(top_left, Vector2(map_width * tile_size, map_height * tile_size))


func _configure_random() -> void:
	if random_seed == 0:
		_rng.randomize()
	else:
		_rng.seed = random_seed


func _build_neighborhood_layout() -> Dictionary:
	var layout: Dictionary = {}
	var block_origins := _get_block_origins()
	var plaza_origins: Array[Vector2i] = []

	for y in range(map_height):
		for x in range(map_width):
			var cell := Vector2i(x, y)
			var is_border := x == 0 or y == 0 or x == map_width - 1 or y == map_height - 1
			layout[cell] = "border" if is_border else "block"

	_build_road_graph()
	for node_origin in _road_nodes:
		_fill_layout_rect(layout, Rect2i(node_origin, Vector2i.ONE * road_width), "road")
	for edge in _road_edges:
		_fill_layout_rect(layout, _get_road_edge_rect(edge["from"], edge["to"]), "road")

	for block_origin in block_origins:
		if _rng.randf() <= plaza_chance:
			plaza_origins.append(block_origin)

	if plaza_origins.is_empty() and not block_origins.is_empty():
		plaza_origins.append(block_origins[int(block_origins.size() / 2.0)])

	for block_origin in plaza_origins:
		for local_y in range(block_size):
			for local_x in range(block_size):
				var cell: Vector2i = block_origin + Vector2i(local_x, local_y)
				if cell.x < map_width - 1 and cell.y < map_height - 1 and layout[cell] == "block":
					layout[cell] = "plaza"

	return layout


func _get_block_origins() -> Array[Vector2i]:
	var origins: Array[Vector2i] = []
	var period := road_width + block_size
	for y in range(ROAD_MARGIN + road_width, map_height - 1, period):
		for x in range(ROAD_MARGIN + road_width, map_width - 1, period):
			origins.append(Vector2i(x, y))
	return origins


func _build_road_graph() -> void:
	var period := road_width + block_size
	var node_lookup := {}
	for y in range(ROAD_MARGIN, map_height - road_width, period):
		for x in range(ROAD_MARGIN, map_width - road_width, period):
			var origin := Vector2i(x, y)
			_road_nodes.append(origin)
			_road_connections[origin] = 0
			node_lookup[origin] = true

	var start := _road_nodes[_rng.randi_range(0, _road_nodes.size() - 1)]
	var visited := {start: true}
	var stack: Array[Vector2i] = [start]
	while not stack.is_empty():
		var current: Vector2i = stack.back()
		var unvisited_neighbors: Array[Vector2i] = []
		for direction: Dictionary in ROAD_DIRECTIONS:
			var candidate_neighbor: Vector2i = current + direction["delta"] * period
			if node_lookup.has(candidate_neighbor) and not visited.has(candidate_neighbor):
				unvisited_neighbors.append(candidate_neighbor)
		if unvisited_neighbors.is_empty():
			stack.pop_back()
			continue

		_shuffle(unvisited_neighbors)
		var neighbor: Vector2i = unvisited_neighbors[0]
		_connect_road_nodes(current, neighbor)
		visited[neighbor] = true
		stack.append(neighbor)

	for origin in _road_nodes:
		for direction: Dictionary in [ROAD_DIRECTIONS[1], ROAD_DIRECTIONS[2]]:
			var neighbor: Vector2i = origin + direction["delta"] * period
			if (
				node_lookup.has(neighbor)
				and not _road_nodes_are_connected(origin, neighbor)
				and _rng.randf() < ROAD_LOOP_CHANCE
			):
				_connect_road_nodes(origin, neighbor)


func _connect_road_nodes(from: Vector2i, to: Vector2i) -> void:
	var delta := to - from
	for direction: Dictionary in ROAD_DIRECTIONS:
		if delta.sign() == direction["delta"]:
			_road_connections[from] |= direction["bit"]
			_road_connections[to] |= direction["opposite"]
			_road_edges.append({"from": from, "to": to})
			return


func _road_nodes_are_connected(from: Vector2i, to: Vector2i) -> bool:
	var delta := (to - from).sign()
	for direction: Dictionary in ROAD_DIRECTIONS:
		if delta == direction["delta"]:
			return (_road_connections[from] & direction["bit"]) != 0
	return false


func _get_road_edge_rect(from: Vector2i, to: Vector2i) -> Rect2i:
	if from.x != to.x:
		return Rect2i(
			Vector2i(mini(from.x, to.x), from.y),
			Vector2i(absi(to.x - from.x) + road_width, road_width)
		)
	return Rect2i(
		Vector2i(from.x, mini(from.y, to.y)),
		Vector2i(road_width, absi(to.y - from.y) + road_width)
	)


func _fill_layout_rect(layout: Dictionary, rect: Rect2i, cell_kind: String) -> void:
	for y in range(rect.position.y, mini(rect.end.y, map_height - 1)):
		for x in range(rect.position.x, mini(rect.end.x, map_width - 1)):
			layout[Vector2i(x, y)] = cell_kind


func _pick_spawn_cell() -> Vector2i:
	var center := Vector2(map_width * 0.5, map_height * 0.5)
	var best_cell := _road_cells[0]
	var best_distance := INF
	for cell in _road_cells:
		var distance := Vector2(cell).distance_squared_to(center)
		if distance < best_distance:
			best_cell = cell
			best_distance = distance
	return best_cell


func _paint_tiles(layout: Dictionary) -> void:
	for y in range(map_height):
		for x in range(map_width):
			var cell := Vector2i(x, y)
			var cell_kind: String = layout[cell]
			if cell_kind == "road":
				streets.set_cell(cell, SOURCE_ID, _atlas_cells_by_group["floors"][0])
				_walkable_cells.append(cell)
				_road_cells.append(cell)
			elif cell_kind in ["plaza", "border"]:
				streets.set_cell(cell, SOURCE_ID, _pick_atlas_cell("floors"))
				_walkable_cells.append(cell)
				if cell_kind == "plaza":
					_plaza_cells.append(cell)
			else:
				_blocked_cells.append(cell)
				houses.set_cell(cell, SOURCE_ID, _pick_blocking_tile())


func _paint_road_visuals() -> void:
	for cell in _road_cells:
		var floor_region: Rect2i = TILE_REGIONS["floors"][0]
		var variation_chance := (
			HOUSE_EDGE_FLOOR_VARIATION_CHANCE
			if _is_house_edge(cell)
			else ROAD_FLOOR_VARIATION_CHANCE
		)
		var uses_variation := _rng.randf() < variation_chance
		if uses_variation:
			floor_region = _pick_region("floors")
		_spawn_road_floor(cell, floor_region, uses_variation)


func _spawn_road_floor(cell: Vector2i, region: Rect2i, uses_variation: bool) -> void:
	var sprite := Sprite2D.new()
	var display_region := region.grow(-ROAD_FLOOR_SOURCE_INSET)
	sprite.texture = _source_texture
	sprite.region_enabled = true
	sprite.region_rect = display_region
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.position = Vector2(cell) * tile_size + Vector2.ONE * tile_size * 0.5
	var display_size := float(tile_size) - ROAD_FLOOR_MARGIN
	sprite.scale = Vector2(display_size / display_region.size.x, display_size / display_region.size.y)
	sprite.material = _get_road_floor_material()
	sprite.set_meta("tileset_group", "floors")
	sprite.set_meta("source_floor_region", region)
	sprite.set_meta("uses_floor_variation", uses_variation)
	road_visuals.add_child(sprite)


func _get_road_floor_material() -> ShaderMaterial:
	if _road_floor_material == null:
		_road_floor_material = ShaderMaterial.new()
		_road_floor_material.shader = ROAD_FLOOR_SHADER
	return _road_floor_material


func _is_house_edge(cell: Vector2i) -> bool:
	for direction: Dictionary in ROAD_DIRECTIONS:
		if cell + direction["delta"] in _blocked_cells:
			return true
	return false


func _ensure_world_bounds() -> void:
	for child in world_bounds.get_children():
		if child.has_meta("runtime_world_bound"):
			child.queue_free()

	var thickness := float(tile_size)
	var map_size := Vector2(map_width * tile_size, map_height * tile_size)
	_add_world_bound(Vector2(-thickness * 0.5, map_size.y * 0.5), Vector2(thickness, map_size.y))
	_add_world_bound(Vector2(map_size.x + thickness * 0.5, map_size.y * 0.5), Vector2(thickness, map_size.y))
	_add_world_bound(Vector2(map_size.x * 0.5, -thickness * 0.5), Vector2(map_size.x, thickness))
	_add_world_bound(Vector2(map_size.x * 0.5, map_size.y + thickness * 0.5), Vector2(map_size.x, thickness))


func _add_world_bound(bound_position: Vector2, size: Vector2) -> void:
	var shape := RectangleShape2D.new()
	shape.size = size
	var collision_shape := CollisionShape2D.new()
	collision_shape.position = bound_position
	collision_shape.shape = shape
	collision_shape.set_meta("runtime_world_bound", true)
	world_bounds.add_child(collision_shape)


func _ensure_runtime_tile_set() -> void:
	if _runtime_tile_set != null:
		_apply_runtime_tile_set()
		return

	_source_texture = load(TILESET_TEXTURE_PATH) as Texture2D
	var source_image := _source_texture.get_image()
	var entry_count := _get_entry_count()
	var row_count := ceili(float(entry_count) / ATLAS_COLUMNS)
	var atlas_image := Image.create(
		ATLAS_COLUMNS * BASE_TILE_SIZE,
		row_count * BASE_TILE_SIZE,
		true,
		Image.FORMAT_RGBA8
	)
	atlas_image.fill(Color.TRANSPARENT)

	var atlas_source := TileSetAtlasSource.new()
	var blocking_cells: Array[Vector2i] = []
	var entry_index := 0
	for group_name: String in TILE_GROUP_ORDER:
		_atlas_cells_by_group[group_name] = []
		var fill_tile := group_name in ["floors", "alleys"]
		for source_region: Rect2i in TILE_REGIONS[group_name]:
			var atlas_cell := Vector2i(
				entry_index % ATLAS_COLUMNS,
				floori(float(entry_index) / float(ATLAS_COLUMNS))
			)
			_copy_region_to_atlas(atlas_image, source_image, source_region, atlas_cell, fill_tile)
			_atlas_cells_by_group[group_name].append(atlas_cell)
			if group_name in BLOCKING_GROUPS:
				blocking_cells.append(atlas_cell)
			entry_index += 1

	atlas_image.generate_mipmaps()
	var atlas_texture := ImageTexture.create_from_image(atlas_image)
	atlas_source.texture = atlas_texture
	atlas_source.texture_region_size = Vector2i(BASE_TILE_SIZE, BASE_TILE_SIZE)

	for group_name: String in TILE_GROUP_ORDER:
		for atlas_cell: Vector2i in _atlas_cells_by_group[group_name]:
			atlas_source.create_tile(atlas_cell)

	_runtime_tile_set = TileSet.new()
	_runtime_tile_set.tile_size = Vector2i(BASE_TILE_SIZE, BASE_TILE_SIZE)
	_runtime_tile_set.add_physics_layer()
	_runtime_tile_set.set_physics_layer_collision_layer(0, 1)
	_runtime_tile_set.add_source(atlas_source, SOURCE_ID)

	for atlas_cell in blocking_cells:
		_add_house_collision(atlas_source.get_tile_data(atlas_cell, 0))

	_apply_runtime_tile_set()


func _copy_region_to_atlas(
	atlas_image: Image,
	source_image: Image,
	source_region: Rect2i,
	atlas_cell: Vector2i,
	fill_tile: bool
) -> void:
	var piece := source_image.get_region(source_region)
	var destination_size := Vector2i(BASE_TILE_SIZE, BASE_TILE_SIZE)
	var destination_position := atlas_cell * BASE_TILE_SIZE

	if fill_tile:
		piece.resize(BASE_TILE_SIZE, BASE_TILE_SIZE, Image.INTERPOLATE_LANCZOS)
	else:
		var fit_scale: float = minf(
			float(BASE_TILE_SIZE) / piece.get_width(),
			float(BASE_TILE_SIZE) / piece.get_height()
		)
		var fitted_size := Vector2i(
			maxi(1, roundi(piece.get_width() * fit_scale)),
			maxi(1, roundi(piece.get_height() * fit_scale))
		)
		piece.resize(fitted_size.x, fitted_size.y, Image.INTERPOLATE_LANCZOS)
		var remaining_size := destination_size - fitted_size
		destination_position += Vector2i(
			floori(float(remaining_size.x) / 2.0),
			floori(float(remaining_size.y) / 2.0)
		)

	atlas_image.blit_rect(piece, Rect2i(Vector2i.ZERO, piece.get_size()), destination_position)


func _apply_runtime_tile_set() -> void:
	var visual_scale := Vector2.ONE * (float(tile_size) / BASE_TILE_SIZE)
	streets.scale = visual_scale
	houses.scale = visual_scale
	streets.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	houses.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	streets.material = _get_road_floor_material()
	streets.tile_set = _runtime_tile_set
	houses.tile_set = _runtime_tile_set


func _get_entry_count() -> int:
	var count := 0
	for group_name: String in TILE_GROUP_ORDER:
		count += TILE_REGIONS[group_name].size()
	return count


func _pick_atlas_cell(group_name: String) -> Vector2i:
	var candidates: Array = _atlas_cells_by_group[group_name]
	return candidates[_rng.randi_range(0, candidates.size() - 1)]


func _pick_blocking_tile() -> Vector2i:
	var roll := _rng.randf()
	var group_name := "walls"
	if roll < 0.36:
		group_name = "roofs"
	elif roll < 0.66:
		group_name = "small_houses"
	elif roll < 0.86:
		group_name = "medium_houses"
	elif roll < 0.93:
		group_name = "stairs"
	return _pick_atlas_cell(group_name)


func _add_house_collision(tile_data: TileData) -> void:
	var half_size := BASE_TILE_SIZE * 0.5
	var collision_polygon := PackedVector2Array([
		Vector2(-half_size, -half_size),
		Vector2(half_size, -half_size),
		Vector2(half_size, half_size),
		Vector2(-half_size, half_size),
	])
	tile_data.set_collision_polygons_count(0, 1)
	tile_data.set_collision_polygon_points(0, 0, collision_polygon)


func _place_neighborhood_details(spawn_cell: Vector2i) -> void:
	var available_roads := _road_cells.duplicate()
	available_roads.erase(spawn_cell)
	_seed_required_categories(available_roads, _blocked_cells)

	for cell in available_roads:
		if _rng.randf() < 0.062:
			_spawn_decoration(cell, "urban_objects", 0.78, 3)
		if _rng.randf() < 0.025:
			_spawn_decoration(cell, "childhood_details", 0.72, 3)

	for cell in _blocked_cells:
		if _rng.randf() < 0.34:
			var building_group := _pick_group(BLOCKING_GROUPS)
			var size_ratio := _rng.randf_range(1.28, 2.15)
			var offset := Vector2(0.0, -tile_size * _rng.randf_range(0.12, 0.46))
			_spawn_decoration(cell, building_group, size_ratio, 2, Color.WHITE, offset)
		if _rng.randf() < 0.12:
			_spawn_decoration(cell, "roofs", _rng.randf_range(1.28, 1.86), 3)
		if _rng.randf() < 0.08:
			_spawn_decoration(cell, "walls", _rng.randf_range(1.16, 1.64), 3)
		if _rng.randf() < 0.042:
			_spawn_decoration(cell, "urban_objects", 0.86, 4)
		if _rng.randf() < 0.052:
			_spawn_decoration(cell, "shadows", 1.34, 5, Color(1, 1, 1, 0.24), Vector2.ZERO, overlays)

	for cell in _plaza_cells:
		if _rng.randf() < 0.1:
			_spawn_decoration(cell, "childhood_details", 0.78, 3)
		if _rng.randf() < 0.055:
			_spawn_decoration(cell, "urban_objects", 0.82, 3)


func _seed_required_categories(road_cells: Array[Vector2i], blocked_cells: Array[Vector2i]) -> void:
	for group_name in ROAD_DECORATION_GROUPS:
		_spawn_decoration(_pick_cell(road_cells), group_name, 0.86, 3)
	for group_name in BLOCKING_GROUPS:
		_spawn_decoration(_pick_cell(blocked_cells), group_name, 1.54, 3)
	_spawn_decoration(
		_pick_cell(blocked_cells),
		"shadows",
		1.44,
		5,
		Color(1, 1, 1, 0.24),
		Vector2.ZERO,
		overlays
	)


func _spawn_decoration(
	cell: Vector2i,
	group_name: String,
	size_ratio: float,
	layer: int,
	color := Color.WHITE,
	offset := Vector2.ZERO,
	parent: Node2D = decorations
) -> void:
	var region := _pick_region(group_name)
	var sprite := Sprite2D.new()
	sprite.texture = _source_texture
	sprite.region_enabled = true
	sprite.region_rect = region
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var largest_side: float = maxf(region.size.x, region.size.y)
	sprite.scale = Vector2.ONE * (tile_size * size_ratio / largest_side)
	sprite.position = Vector2(
		cell.x * tile_size + tile_size * 0.5,
		cell.y * tile_size + tile_size * 0.5
	) + offset
	sprite.z_index = layer
	sprite.modulate = color
	sprite.set_meta("tileset_group", group_name)
	parent.add_child(sprite)


func _pick_region(group_name: String) -> Rect2i:
	if not _region_queues.has(group_name) or _region_queues[group_name].is_empty():
		var refreshed_regions: Array = TILE_REGIONS[group_name].duplicate()
		_shuffle(refreshed_regions)
		_region_queues[group_name] = refreshed_regions
	return _region_queues[group_name].pop_back()


func _pick_group(groups: Array) -> String:
	return groups[_rng.randi_range(0, groups.size() - 1)]


func _pick_cell(cells: Array[Vector2i]) -> Vector2i:
	return cells[_rng.randi_range(0, cells.size() - 1)]


func _clear_visual_layers() -> void:
	for child in road_visuals.get_children():
		child.queue_free()
	for child in decorations.get_children():
		child.queue_free()
	for child in overlays.get_children():
		child.queue_free()


func _shuffle(values: Array) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index := _rng.randi_range(0, index)
		var old_value = values[index]
		values[index] = values[swap_index]
		values[swap_index] = old_value

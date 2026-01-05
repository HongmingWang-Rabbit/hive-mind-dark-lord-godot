extends RefCounted
## Procedural map generation for both worlds
## Generates identical terrain (floors, buildings, props) in Human and Corrupted worlds

const Tiles := preload("res://scripts/data/tile_data.gd")

# Reference to World (for map access)
var _world: Node2D

# State
var occupied_tiles: Dictionary = {}
var total_tiles: int = 0
var initial_corruption_tile: Vector2i

# Map dimensions
var _map_width: int
var _map_height: int


func setup(world: Node2D, map_width: int, map_height: int) -> void:
	_world = world
	_map_width = map_width
	_map_height = map_height


func generate_map() -> void:
	## Generate the complete map for both worlds
	randomize()
	_clear_all_maps()
	_generate_shared_terrain()
	_start_initial_corruption()


func _clear_all_maps() -> void:
	# Clear Human World
	_world.human_floor_map.clear()
	_world.human_structure_map.clear()
	_world.human_corruption_map.clear()

	# Clear Corrupted World
	_world.corrupted_floor_map.clear()
	_world.corrupted_structure_map.clear()
	_world.corrupted_corruption_map.clear()

	# Clear state
	occupied_tiles.clear()
	total_tiles = 0


func _generate_shared_terrain() -> void:
	# Generate identical floor in both worlds
	for x in range(_map_width):
		for y in range(_map_height):
			var tile := _get_weighted_floor_tile()
			var pos := Vector2i(x, y)
			_world.human_floor_map.set_cell(pos, GameConstants.TILEMAP_SOURCE_ID, tile)
			_world.corrupted_floor_map.set_cell(pos, GameConstants.TILEMAP_SOURCE_ID, tile)
			total_tiles += 1

	# Generate identical buildings in both worlds
	_generate_buildings()

	# Generate identical props in both worlds
	_scatter_props()


func _get_weighted_floor_tile() -> Vector2i:
	var total_weight := GameConstants.FLOOR_WEIGHT_MAIN + GameConstants.FLOOR_WEIGHT_ALT + GameConstants.FLOOR_WEIGHT_VARIATION
	var roll := randi_range(0, total_weight - 1)
	if roll < GameConstants.FLOOR_WEIGHT_MAIN:
		return Tiles.FLOOR_MAIN
	elif roll < GameConstants.FLOOR_WEIGHT_MAIN + GameConstants.FLOOR_WEIGHT_ALT:
		return Tiles.FLOOR_ALT
	else:
		return Tiles.FLOOR_VARIATION


func _generate_buildings() -> void:
	var count := randi_range(
		GameConstants.BUILDING_COUNT_MIN,
		GameConstants.BUILDING_COUNT_MAX
	)
	for i in range(count):
		_try_place_building()


func _try_place_building() -> void:
	var margin := GameConstants.MAP_EDGE_MARGIN
	for _attempt in range(GameConstants.BUILDING_PLACEMENT_ATTEMPTS):
		var size := Vector2i(
			randi_range(GameConstants.BUILDING_SIZE_MIN.x, GameConstants.BUILDING_SIZE_MAX.x),
			randi_range(GameConstants.BUILDING_SIZE_MIN.y, GameConstants.BUILDING_SIZE_MAX.y)
		)
		var pos := Vector2i(
			randi_range(margin, _map_width - size.x - margin),
			randi_range(margin, _map_height - size.y - margin)
		)

		var padding := GameConstants.BUILDING_PADDING
		var check_pos := pos - Vector2i(padding, padding)
		var check_size := size + Vector2i(padding * 2, padding * 2)

		if _is_area_free(check_pos, check_size):
			_place_building(pos, size)
			return


func _is_area_free(pos: Vector2i, size: Vector2i) -> bool:
	for x in range(size.x):
		for y in range(size.y):
			if occupied_tiles.has(pos + Vector2i(x, y)):
				return false
	return true


func _place_building(pos: Vector2i, size: Vector2i) -> void:
	for x in range(size.x):
		for y in range(size.y):
			var tile_pos := pos + Vector2i(x, y)
			var tile := _get_wall_tile(x, y, size)
			# Place in both worlds
			_world.human_structure_map.set_cell(tile_pos, GameConstants.TILEMAP_SOURCE_ID, tile)
			_world.corrupted_structure_map.set_cell(tile_pos, GameConstants.TILEMAP_SOURCE_ID, tile)
			occupied_tiles[tile_pos] = true


func _get_wall_tile(x: int, y: int, size: Vector2i) -> Vector2i:
	if y == 0:
		if x == 0:
			return Tiles.WALL_TOP_LEFT
		elif x == size.x - 1:
			return Tiles.WALL_TOP_RIGHT
		else:
			return Tiles.WALL_TOP
	else:
		if x == 0:
			return Tiles.WALL_LEFT
		elif x == size.x - 1:
			return Tiles.WALL_RIGHT
		else:
			return Tiles.WALL


func _scatter_props() -> void:
	var target_count := GameConstants.PROP_COUNT
	var max_attempts := target_count * GameConstants.PROP_SCATTER_ATTEMPTS_MULTIPLIER
	var placed := 0
	var attempts := 0

	while placed < target_count and attempts < max_attempts:
		attempts += 1
		var pos := Vector2i(randi_range(0, _map_width - 1), randi_range(0, _map_height - 1))

		if _can_place_prop(pos):
			var prop_tile := Tiles.get_random_prop()
			# Place in both worlds
			_world.human_structure_map.set_cell(pos, GameConstants.TILEMAP_SOURCE_ID, prop_tile)
			_world.corrupted_structure_map.set_cell(pos, GameConstants.TILEMAP_SOURCE_ID, prop_tile)
			occupied_tiles[pos] = true
			placed += 1


func _can_place_prop(pos: Vector2i) -> bool:
	if occupied_tiles.has(pos):
		return false

	for dir in GameConstants.ORTHOGONAL_DIRS:
		if occupied_tiles.has(pos + dir):
			return false

	return true


func _start_initial_corruption() -> void:
	var center := Vector2i(_map_width / 2, _map_height / 2)
	if occupied_tiles.has(center):
		center = _find_nearest_free_tile(center)
	initial_corruption_tile = center


func _find_nearest_free_tile(from: Vector2i) -> Vector2i:
	for radius in range(1, max(_map_width, _map_height)):
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				var check := from + Vector2i(dx, dy)
				if _is_valid_free_tile(check):
					return check
	return from


func _is_valid_free_tile(pos: Vector2i) -> bool:
	if occupied_tiles.has(pos):
		return false
	return pos.x >= 0 and pos.x < _map_width and pos.y >= 0 and pos.y < _map_height


func is_floor_tile(pos: Vector2i) -> bool:
	## Check if position is a valid floor tile (not occupied by structure)
	if occupied_tiles.has(pos):
		return false
	return _world.human_floor_map.get_cell_source_id(pos) != -1


func count_existing_tiles() -> void:
	## Count tiles when not using procedural generation
	var used_cells: Array[Vector2i] = _world.human_floor_map.get_used_cells()
	total_tiles = used_cells.size()

extends Node2D
## World manager - handles map generation and corruption spreading
## Uses TileData for tile coordinates and GameConstants for generation settings

const Tiles := preload("res://scripts/data/tile_data.gd")

@onready var terrain_map: TileMapLayer = $TerrainMap
@onready var corruption_map: TileMapLayer = $CorruptionMap
@onready var camera: Camera2D = $Camera2D

# Generation toggle (can override constants via inspector)
@export var use_procedural_generation := true
@export var override_map_size := false
@export var custom_map_width := GameConstants.MAP_WIDTH
@export var custom_map_height := GameConstants.MAP_HEIGHT

# Runtime state
var corrupted_tiles: Dictionary = {}
var occupied_tiles: Dictionary = {}
var total_tiles: int = 0

# Computed map bounds
var map_width: int
var map_height: int

# Camera state
var _camera_bounds: Rect2
var _is_dragging := false
var _drag_start_mouse: Vector2
var _drag_start_camera: Vector2


func _ready() -> void:
	_init_visual_settings()
	_init_map_size()

	if use_procedural_generation:
		generate_map()
	else:
		_count_existing_tiles()

	_init_camera_bounds()
	GameManager.start_game()


func _process(delta: float) -> void:
	_handle_camera_keyboard(delta)


func _init_visual_settings() -> void:
	corruption_map.modulate = GameConstants.CORRUPTION_COLOR
	camera.position = GameConstants.CAMERA_CENTER


func _init_map_size() -> void:
	if override_map_size:
		map_width = custom_map_width
		map_height = custom_map_height
	else:
		map_width = GameConstants.MAP_WIDTH
		map_height = GameConstants.MAP_HEIGHT


func _init_camera_bounds() -> void:
	var tile_size := GameConstants.TILE_SIZE
	var padding := GameConstants.CAMERA_EDGE_PADDING
	var half_viewport := Vector2(GameConstants.VIEWPORT_WIDTH, GameConstants.VIEWPORT_HEIGHT) / 2.0

	var map_pixel_size := Vector2(map_width * tile_size, map_height * tile_size)

	# Camera bounds are where the camera CENTER can be positioned
	_camera_bounds = Rect2(
		half_viewport.x - padding,
		half_viewport.y - padding,
		map_pixel_size.x - GameConstants.VIEWPORT_WIDTH + padding * 2,
		map_pixel_size.y - GameConstants.VIEWPORT_HEIGHT + padding * 2
	)

	# Ensure minimum bounds if map is smaller than viewport
	if _camera_bounds.size.x < 0:
		_camera_bounds.position.x = map_pixel_size.x / 2.0
		_camera_bounds.size.x = 0
	if _camera_bounds.size.y < 0:
		_camera_bounds.position.y = map_pixel_size.y / 2.0
		_camera_bounds.size.y = 0


func _handle_camera_keyboard(delta: float) -> void:
	var input_dir := Vector2.ZERO

	# Arrow keys
	if Input.is_action_pressed("ui_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("ui_right"):
		input_dir.x += 1
	if Input.is_action_pressed("ui_up"):
		input_dir.y -= 1
	if Input.is_action_pressed("ui_down"):
		input_dir.y += 1

	# WASD keys
	if Input.is_physical_key_pressed(KEY_A):
		input_dir.x -= 1
	if Input.is_physical_key_pressed(KEY_D):
		input_dir.x += 1
	if Input.is_physical_key_pressed(KEY_W):
		input_dir.y -= 1
	if Input.is_physical_key_pressed(KEY_S):
		input_dir.y += 1

	if input_dir != Vector2.ZERO:
		var movement := input_dir.normalized() * GameConstants.CAMERA_PAN_SPEED * delta
		camera.position += movement
		_clamp_camera()


func _clamp_camera() -> void:
	camera.position.x = clampf(camera.position.x, _camera_bounds.position.x, _camera_bounds.end.x)
	camera.position.y = clampf(camera.position.y, _camera_bounds.position.y, _camera_bounds.end.y)


func _count_existing_tiles() -> void:
	var used_cells := terrain_map.get_used_cells()
	total_tiles = used_cells.size()


#region Map Generation

func generate_map() -> void:
	randomize()
	_clear_map()
	_generate_floor()
	_generate_buildings()
	_scatter_props()
	_start_initial_corruption()


func _clear_map() -> void:
	terrain_map.clear()
	corruption_map.clear()
	corrupted_tiles.clear()
	occupied_tiles.clear()
	total_tiles = 0


func _generate_floor() -> void:
	for x in range(map_width):
		for y in range(map_height):
			var tile := _get_weighted_floor_tile()
			terrain_map.set_cell(Vector2i(x, y), GameConstants.TILEMAP_SOURCE_ID, tile)
			total_tiles += 1


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
			randi_range(margin, map_width - size.x - margin),
			randi_range(margin, map_height - size.y - margin)
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
			terrain_map.set_cell(tile_pos, GameConstants.TILEMAP_SOURCE_ID, tile)
			occupied_tiles[tile_pos] = true


func _get_wall_tile(x: int, y: int, size: Vector2i) -> Vector2i:
	# Top row uses top variants, all other rows use front
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
		var pos := Vector2i(randi_range(0, map_width - 1), randi_range(0, map_height - 1))

		if _can_place_prop(pos):
			terrain_map.set_cell(pos, GameConstants.TILEMAP_SOURCE_ID, Tiles.get_random_prop())
			occupied_tiles[pos] = true
			placed += 1


func _can_place_prop(pos: Vector2i) -> bool:
	if occupied_tiles.has(pos):
		return false

	# Avoid clustering
	for dir in GameConstants.ORTHOGONAL_DIRS:
		if occupied_tiles.has(pos + dir):
			return false

	return true


func _start_initial_corruption() -> void:
	var center := Vector2i(map_width / 2, map_height / 2)
	if occupied_tiles.has(center):
		center = _find_nearest_free_tile(center)
	corrupt_tile(center)


func _find_nearest_free_tile(from: Vector2i) -> Vector2i:
	for radius in range(1, max(map_width, map_height)):
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				var check := from + Vector2i(dx, dy)
				if _is_valid_free_tile(check):
					return check
	return from


func _is_valid_free_tile(pos: Vector2i) -> bool:
	if occupied_tiles.has(pos):
		return false
	return pos.x >= 0 and pos.x < map_width and pos.y >= 0 and pos.y < map_height

#endregion


#region Corruption

func corrupt_tile(tile_pos: Vector2i) -> void:
	if corrupted_tiles.has(tile_pos):
		return

	if terrain_map.get_cell_source_id(tile_pos) == -1:
		return

	corrupted_tiles[tile_pos] = true

	# Mirror tile to corruption layer (purple tinted via modulate)
	var terrain_tile := terrain_map.get_cell_atlas_coords(tile_pos)
	corruption_map.set_cell(tile_pos, GameConstants.TILEMAP_SOURCE_ID, terrain_tile)

	EventBus.tile_corrupted.emit(tile_pos)
	_update_corruption_percent()


func spread_corruption() -> void:
	var candidates := _get_corruption_candidates()
	if candidates.size() > 0:
		var target: Vector2i = candidates[randi_range(0, candidates.size() - 1)]
		corrupt_tile(target)


func _get_corruption_candidates() -> Array[Vector2i]:
	var candidates: Array[Vector2i] = []

	for tile_pos: Vector2i in corrupted_tiles.keys():
		for dir: Vector2i in GameConstants.ORTHOGONAL_DIRS:
			var neighbor: Vector2i = tile_pos + dir
			if _can_corrupt_tile(neighbor):
				candidates.append(neighbor)

	return candidates


func _can_corrupt_tile(pos: Vector2i) -> bool:
	if corrupted_tiles.has(pos):
		return false
	return terrain_map.get_cell_source_id(pos) != -1


func _update_corruption_percent() -> void:
	if total_tiles == 0:
		return
	var percent := float(corrupted_tiles.size()) / float(total_tiles)
	GameManager.update_corruption(percent)

#endregion


#region Input

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		spread_corruption()

	_handle_camera_drag(event)


func _handle_camera_drag(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT or mouse_event.button_index == MOUSE_BUTTON_MIDDLE:
			if mouse_event.pressed:
				_is_dragging = true
				_drag_start_mouse = mouse_event.position
				_drag_start_camera = camera.position
			else:
				_is_dragging = false

	elif event is InputEventMouseMotion and _is_dragging:
		var motion_event := event as InputEventMouseMotion
		var drag_delta := _drag_start_mouse - motion_event.position
		camera.position = _drag_start_camera + drag_delta
		_clamp_camera()

#endregion

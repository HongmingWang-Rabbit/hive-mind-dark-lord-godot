extends Node2D
## World manager - handles dual-world map generation and corruption spreading
## Uses TileData for tile coordinates and GameConstants for generation settings
##
## Dual World System:
##   HumanWorld    - Normal colors, corruption spreads only near portals
##   CorruptedWorld - Purple tint, atmospheric particles, starts fully corrupted
##
## Each world has identical terrain layout (floor, structures)

const Tiles := preload("res://scripts/data/tile_data.gd")
const DarkLordScene := preload("res://scenes/entities/dark_lord/dark_lord.tscn")

# World containers
@onready var human_world: Node2D = $HumanWorld
@onready var corrupted_world: Node2D = $CorruptedWorld

# Human World layers
@onready var human_floor_map: TileMapLayer = $HumanWorld/FloorMap
@onready var human_structure_map: TileMapLayer = $HumanWorld/StructureMap
@onready var human_corruption_map: TileMapLayer = $HumanWorld/CorruptionMap

# Corrupted World layers
@onready var corrupted_floor_map: TileMapLayer = $CorruptedWorld/FloorMap
@onready var corrupted_structure_map: TileMapLayer = $CorruptedWorld/StructureMap
@onready var corrupted_corruption_map: TileMapLayer = $CorruptedWorld/CorruptionMap
@onready var atmosphere_particles: GPUParticles2D = $CorruptedWorld/AtmosphereParticles

# Per-world entity containers
@onready var human_entities: Node2D = $HumanWorld/Entities
@onready var corrupted_entities: Node2D = $CorruptedWorld/Entities

# Common nodes
@onready var camera: Camera2D = $Camera2D

# Generation toggle (can override constants via inspector)
@export var use_procedural_generation := true
@export var override_map_size := false
@export var custom_map_width := GameConstants.MAP_WIDTH
@export var custom_map_height := GameConstants.MAP_HEIGHT

# Runtime state - per world corruption tracking
var human_corrupted_tiles: Dictionary = {}
var corrupted_corrupted_tiles: Dictionary = {}
var occupied_tiles: Dictionary = {}  # Shared - same layout in both worlds
var total_tiles: int = 0

# Computed map bounds
var map_width: int
var map_height: int

# Initial state
var _initial_corruption_tile: Vector2i
var _dark_lord: CharacterBody2D


func _ready() -> void:
	_init_map_size()

	if use_procedural_generation:
		generate_map()
	else:
		_count_existing_tiles()

	_setup_world_visuals()
	_spawn_dark_lord()
	_init_camera()
	_show_world(WorldManager.active_world)

	EventBus.world_switched.connect(_on_world_switched)
	GameManager.start_game()


func _init_map_size() -> void:
	if override_map_size:
		map_width = custom_map_width
		map_height = custom_map_height
	else:
		map_width = GameConstants.MAP_WIDTH
		map_height = GameConstants.MAP_HEIGHT


func _init_camera() -> void:
	camera.set_map_bounds(map_width, map_height)
	camera.center_on_tile(_initial_corruption_tile)


func _setup_world_visuals() -> void:
	# Human World - normal colors with corruption overlay
	human_world.modulate = GameConstants.HUMAN_WORLD_TINT
	human_corruption_map.modulate = GameConstants.CORRUPTION_COLOR

	# Corrupted World - dark purple tint
	corrupted_world.modulate = GameConstants.CORRUPTED_WORLD_TINT
	corrupted_corruption_map.modulate = GameConstants.CORRUPTION_COLOR

	# Setup atmosphere particles
	_setup_atmosphere_particles()

	# Corrupted World starts fully corrupted
	_fully_corrupt_corrupted_world()


func _setup_atmosphere_particles() -> void:
	# Create particle material
	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(
		map_width * GameConstants.TILE_SIZE / 2.0,
		map_height * GameConstants.TILE_SIZE / 2.0,
		0
	)
	material.direction = GameConstants.CORRUPTED_PARTICLES_DIRECTION
	material.spread = GameConstants.CORRUPTED_PARTICLES_SPREAD
	material.gravity = GameConstants.CORRUPTED_PARTICLES_GRAVITY
	material.initial_velocity_min = GameConstants.CORRUPTED_PARTICLES_VELOCITY_MIN
	material.initial_velocity_max = GameConstants.CORRUPTED_PARTICLES_VELOCITY_MAX
	material.scale_min = GameConstants.CORRUPTED_PARTICLES_SCALE_MIN
	material.scale_max = GameConstants.CORRUPTED_PARTICLES_SCALE_MAX
	material.color = GameConstants.CORRUPTED_PARTICLES_COLOR

	# Create a simple gradient texture for particles
	var gradient := Gradient.new()
	gradient.set_color(0, Color.WHITE)
	gradient.set_color(1, Color.WHITE)
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = GameConstants.CORRUPTED_PARTICLES_TEXTURE_SIZE
	texture.height = GameConstants.CORRUPTED_PARTICLES_TEXTURE_SIZE
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0.0)

	atmosphere_particles.process_material = material
	atmosphere_particles.texture = texture
	atmosphere_particles.amount = GameConstants.CORRUPTED_PARTICLES_AMOUNT
	atmosphere_particles.lifetime = GameConstants.CORRUPTED_PARTICLES_LIFETIME
	atmosphere_particles.position = Vector2(
		map_width * GameConstants.TILE_SIZE / 2.0,
		map_height * GameConstants.TILE_SIZE / 2.0
	)
	atmosphere_particles.emitting = true


func _fully_corrupt_corrupted_world() -> void:
	for x in range(map_width):
		for y in range(map_height):
			var pos := Vector2i(x, y)
			if corrupted_floor_map.get_cell_source_id(pos) != -1:
				corrupted_corrupted_tiles[pos] = true
				var floor_tile := corrupted_floor_map.get_cell_atlas_coords(pos)
				corrupted_corruption_map.set_cell(pos, GameConstants.TILEMAP_SOURCE_ID, floor_tile)


func _spawn_dark_lord() -> void:
	_dark_lord = DarkLordScene.instantiate()
	var tile_size := GameConstants.TILE_SIZE
	_dark_lord.global_position = Vector2(_initial_corruption_tile) * tile_size + Vector2(tile_size, tile_size) / 2.0
	# Dark Lord starts in Corrupted World
	corrupted_entities.add_child(_dark_lord)


func _count_existing_tiles() -> void:
	var used_cells := human_floor_map.get_used_cells()
	total_tiles = used_cells.size()


#region World Switching

func _on_world_switched(new_world: Enums.WorldType) -> void:
	_show_world(new_world)


func _show_world(world: Enums.WorldType) -> void:
	match world:
		Enums.WorldType.HUMAN:
			human_world.visible = true
			corrupted_world.visible = false
		Enums.WorldType.CORRUPTED:
			human_world.visible = false
			corrupted_world.visible = true


func get_entities_container(world: Enums.WorldType) -> Node2D:
	## Get the entities container for a specific world
	match world:
		Enums.WorldType.HUMAN:
			return human_entities
		Enums.WorldType.CORRUPTED:
			return corrupted_entities
	return corrupted_entities


func transfer_entity_to_world(entity: Node2D, target_world: Enums.WorldType) -> void:
	## Move an entity from its current world to target world
	## Preserves global position during transfer
	var global_pos := entity.global_position
	entity.get_parent().remove_child(entity)
	get_entities_container(target_world).add_child(entity)
	entity.global_position = global_pos

#endregion


#region Map Generation

func generate_map() -> void:
	randomize()
	_clear_all_maps()
	_generate_shared_terrain()
	_start_initial_corruption()


func _clear_all_maps() -> void:
	# Clear Human World
	human_floor_map.clear()
	human_structure_map.clear()
	human_corruption_map.clear()

	# Clear Corrupted World
	corrupted_floor_map.clear()
	corrupted_structure_map.clear()
	corrupted_corruption_map.clear()

	# Clear state
	human_corrupted_tiles.clear()
	corrupted_corrupted_tiles.clear()
	occupied_tiles.clear()
	total_tiles = 0


func _generate_shared_terrain() -> void:
	# Generate identical floor in both worlds
	for x in range(map_width):
		for y in range(map_height):
			var tile := _get_weighted_floor_tile()
			var pos := Vector2i(x, y)
			human_floor_map.set_cell(pos, GameConstants.TILEMAP_SOURCE_ID, tile)
			corrupted_floor_map.set_cell(pos, GameConstants.TILEMAP_SOURCE_ID, tile)
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
			# Place in both worlds
			human_structure_map.set_cell(tile_pos, GameConstants.TILEMAP_SOURCE_ID, tile)
			corrupted_structure_map.set_cell(tile_pos, GameConstants.TILEMAP_SOURCE_ID, tile)
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
		var pos := Vector2i(randi_range(0, map_width - 1), randi_range(0, map_height - 1))

		if _can_place_prop(pos):
			var prop_tile := Tiles.get_random_prop()
			# Place in both worlds
			human_structure_map.set_cell(pos, GameConstants.TILEMAP_SOURCE_ID, prop_tile)
			corrupted_structure_map.set_cell(pos, GameConstants.TILEMAP_SOURCE_ID, prop_tile)
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
	var center := Vector2i(map_width / 2, map_height / 2)
	if occupied_tiles.has(center):
		center = _find_nearest_free_tile(center)
	_initial_corruption_tile = center
	# Note: Don't call corrupt_tile here - corrupted world is fully corrupted in _setup_world_visuals


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

func corrupt_tile(tile_pos: Vector2i, world: Enums.WorldType = Enums.WorldType.CORRUPTED) -> void:
	var tiles_dict: Dictionary
	var corruption_map: TileMapLayer
	var floor_map: TileMapLayer

	match world:
		Enums.WorldType.HUMAN:
			# Check if near a portal
			if not WorldManager.can_corrupt_in_human_world(tile_pos):
				return
			tiles_dict = human_corrupted_tiles
			corruption_map = human_corruption_map
			floor_map = human_floor_map
		Enums.WorldType.CORRUPTED:
			tiles_dict = corrupted_corrupted_tiles
			corruption_map = corrupted_corruption_map
			floor_map = corrupted_floor_map

	if tiles_dict.has(tile_pos):
		return

	if floor_map.get_cell_source_id(tile_pos) == -1:
		return

	tiles_dict[tile_pos] = true

	var floor_tile := floor_map.get_cell_atlas_coords(tile_pos)
	corruption_map.set_cell(tile_pos, GameConstants.TILEMAP_SOURCE_ID, floor_tile)

	EventBus.tile_corrupted.emit(tile_pos)
	_update_corruption_percent()


func spread_corruption() -> void:
	var candidates := _get_corruption_candidates(WorldManager.active_world)
	if candidates.size() > 0:
		var target: Vector2i = candidates[randi_range(0, candidates.size() - 1)]
		corrupt_tile(target, WorldManager.active_world)


func _get_corruption_candidates(world: Enums.WorldType) -> Array[Vector2i]:
	var candidates: Array[Vector2i] = []
	var tiles_dict: Dictionary
	var floor_map: TileMapLayer

	match world:
		Enums.WorldType.HUMAN:
			tiles_dict = human_corrupted_tiles
			floor_map = human_floor_map
		Enums.WorldType.CORRUPTED:
			tiles_dict = corrupted_corrupted_tiles
			floor_map = corrupted_floor_map

	for tile_pos: Vector2i in tiles_dict.keys():
		for dir: Vector2i in GameConstants.ORTHOGONAL_DIRS:
			var neighbor: Vector2i = tile_pos + dir
			if _can_corrupt_tile_in_world(neighbor, world, tiles_dict, floor_map):
				candidates.append(neighbor)

	return candidates


func _can_corrupt_tile_in_world(pos: Vector2i, world: Enums.WorldType, tiles_dict: Dictionary, floor_map: TileMapLayer) -> bool:
	if tiles_dict.has(pos):
		return false
	if floor_map.get_cell_source_id(pos) == -1:
		return false
	# In Human World, must be near a portal
	if world == Enums.WorldType.HUMAN:
		return WorldManager.can_corrupt_in_human_world(pos)
	return true


func clear_corruption(tile_pos: Vector2i) -> void:
	## Clear corruption in Human World (human counter-mechanic)
	if not human_corrupted_tiles.has(tile_pos):
		return

	human_corrupted_tiles.erase(tile_pos)
	human_corruption_map.erase_cell(tile_pos)
	EventBus.corruption_cleared.emit(tile_pos)
	_update_corruption_percent()


func _update_corruption_percent() -> void:
	if total_tiles == 0:
		return
	# Calculate based on Human World corruption (that's what matters for winning)
	var percent := float(human_corrupted_tiles.size()) / float(total_tiles)
	GameManager.update_corruption(percent)

#endregion


#region Input

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		spread_corruption()

	# Debug: Switch worlds
	if event is InputEventKey and event.pressed and event.keycode == GameConstants.KEY_SWITCH_WORLD:
		var target := Enums.WorldType.HUMAN if WorldManager.active_world == Enums.WorldType.CORRUPTED else Enums.WorldType.CORRUPTED
		WorldManager.switch_world(target)

#endregion

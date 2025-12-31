extends Node2D
## World manager - handles dual-world map generation and corruption spreading
## Uses TileData for tile coordinates and GameConstants for generation settings
##
## Dual World System:
##   HumanWorld    - Normal colors, corruption spreads only near portals
##   CorruptedWorld - Purple tint, atmospheric particles, small initial corruption
##
## Each world has identical terrain layout (floor, structures)
## Both worlds have fog of war that clears as entities explore or corruption spreads

const Tiles := preload("res://scripts/data/tile_data.gd")
const FogUtils := preload("res://scripts/utils/fog_utils.gd")
const DarkLordScene := preload("res://scenes/entities/dark_lord/dark_lord.tscn")
const CivilianScene := preload("res://scenes/entities/humans/civilian.tscn")
const AnimalScene := preload("res://scenes/entities/humans/animal.tscn")
const MinionScene := preload("res://scenes/entities/minions/minion.tscn")
const EnemyScene := preload("res://scenes/entities/enemies/enemy.tscn")
const CorruptionNodeScene := preload("res://scenes/entities/buildings/corruption_node.tscn")
const SpawningPitScene := preload("res://scenes/entities/buildings/spawning_pit.tscn")
const PortalScene := preload("res://scenes/entities/buildings/portal.tscn")
const PortalData := preload("res://scripts/entities/buildings/PortalData.gd")

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

# Fog of war layers
@onready var human_fog_map: TileMapLayer = $HumanWorld/FogMap
@onready var corrupted_fog_map: TileMapLayer = $CorruptedWorld/FogMap

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

# Fog of war state - tiles that have been revealed (permanently cleared for jam scope)
var _human_explored_tiles: Dictionary = {}
var _corrupted_explored_tiles: Dictionary = {}

# Computed map bounds
var map_width: int
var map_height: int

# Initial state
var _initial_corruption_tile: Vector2i
var _dark_lord: CharacterBody2D

# Enemy spawning
var _police_spawn_timer: float = 0.0
var _military_spawn_timer: float = 0.0
var _heavy_spawn_timer: float = 0.0
var _current_threat_level: Enums.ThreatLevel = Enums.ThreatLevel.NONE


func _ready() -> void:
	_init_map_size()

	if use_procedural_generation:
		generate_map()
	else:
		_count_existing_tiles()

	_setup_world_visuals()
	_setup_fog()
	_spawn_dark_lord()
	_spawn_human_world_entities()
	_init_camera()
	_show_world(WorldManager.active_world)

	EventBus.world_switched.connect(_on_world_switched)
	EventBus.fog_update_requested.connect(_on_fog_update_requested)
	EventBus.threat_level_changed.connect(_on_threat_level_changed)
	EventBus.building_requested.connect(_on_building_requested)
	EventBus.retreat_ordered.connect(_on_retreat_ordered)
	GameManager.start_game()

	# Initial fog update for starting world
	update_fog(WorldManager.active_world)


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

	# Initialize corruption in Corrupted World (small starting area, must expand)
	_init_corrupted_world_corruption()


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


func _init_corrupted_world_corruption() -> void:
	## Initialize corruption in Corrupted World around starting point only
	## Corruption must be expanded over time (same as Human World)
	var tiles := FogUtils.get_tiles_in_sight_range(
		_initial_corruption_tile,
		GameConstants.INITIAL_CORRUPTION_REVEAL_RADIUS
	)
	for pos: Vector2i in tiles:
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


func _spawn_human_world_entities() -> void:
	## Spawn civilians and animals in Human World
	_spawn_civilians()
	_spawn_animals()


func _spawn_civilians() -> void:
	for i in GameConstants.CIVILIAN_COUNT:
		var civilian := CivilianScene.instantiate()
		var spawn_pos := _get_random_floor_tile()
		_place_entity_at_tile(civilian, spawn_pos, Enums.WorldType.HUMAN)


func _spawn_animals() -> void:
	for i in GameConstants.ANIMAL_COUNT:
		var animal := AnimalScene.instantiate()
		var spawn_pos := _get_random_floor_tile()
		_place_entity_at_tile(animal, spawn_pos, Enums.WorldType.HUMAN)


func _place_entity_at_tile(entity: Node2D, tile_pos: Vector2i, world: Enums.WorldType) -> void:
	var container := get_entities_container(world)
	container.add_child(entity)
	var tile_size := GameConstants.TILE_SIZE
	entity.global_position = Vector2(tile_pos) * tile_size + Vector2(tile_size, tile_size) / 2.0


func _get_random_floor_tile() -> Vector2i:
	## Pick a random unoccupied floor tile
	for i in GameConstants.ENTITY_SPAWN_ATTEMPTS:
		var x := randi_range(GameConstants.MAP_EDGE_MARGIN, map_width - GameConstants.MAP_EDGE_MARGIN - 1)
		var y := randi_range(GameConstants.MAP_EDGE_MARGIN, map_height - GameConstants.MAP_EDGE_MARGIN - 1)
		var pos := Vector2i(x, y)
		if _is_floor_tile(pos):
			return pos
	return Vector2i(map_width / 2, map_height / 2)


func _is_floor_tile(pos: Vector2i) -> bool:
	## Check if position is a valid floor tile (not occupied by structure)
	if occupied_tiles.has(pos):
		return false
	return human_floor_map.get_cell_source_id(pos) != -1


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
	# Note: Initial corruption is set up in _init_corrupted_world_corruption() after map generation


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

	# Auto-reveal fog when corruption spreads in Corrupted World
	if world == Enums.WorldType.CORRUPTED and GameConstants.FOG_ENABLED:
		_corrupted_explored_tiles[tile_pos] = true
		corrupted_fog_map.erase_cell(tile_pos)

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


#region Fog of War

func _setup_fog() -> void:
	if not GameConstants.FOG_ENABLED:
		return

	# Fill both worlds with fog
	_fill_fog_map(human_fog_map, human_floor_map)
	_fill_fog_map(corrupted_fog_map, corrupted_floor_map)

	# Reveal initial corruption area in Corrupted World
	_reveal_initial_corruption()


func _fill_fog_map(fog_map: TileMapLayer, floor_map: TileMapLayer) -> void:
	fog_map.modulate = GameConstants.FOG_COLOR
	for x in range(map_width):
		for y in range(map_height):
			var pos := Vector2i(x, y)
			if floor_map.get_cell_source_id(pos) != -1:
				fog_map.set_cell(pos, GameConstants.TILEMAP_SOURCE_ID, Tiles.FOG_TILE)


func _reveal_initial_corruption() -> void:
	var tiles := FogUtils.get_tiles_in_sight_range(
		_initial_corruption_tile,
		GameConstants.INITIAL_CORRUPTION_REVEAL_RADIUS
	)
	for tile: Vector2i in tiles:
		_corrupted_explored_tiles[tile] = true
		corrupted_fog_map.erase_cell(tile)


func update_fog(world: Enums.WorldType) -> void:
	## Update fog visibility for a world based on entity sight ranges
	## Once a tile is revealed, it stays revealed (no re-fogging for jam scope)
	if not GameConstants.FOG_ENABLED:
		return

	var fog_map: TileMapLayer
	var entities_container: Node2D
	var explored_tiles: Dictionary
	var use_corruption_reveal: bool

	match world:
		Enums.WorldType.HUMAN:
			fog_map = human_fog_map
			entities_container = human_entities
			explored_tiles = _human_explored_tiles
			use_corruption_reveal = false
		Enums.WorldType.CORRUPTED:
			fog_map = corrupted_fog_map
			entities_container = corrupted_entities
			explored_tiles = _corrupted_explored_tiles
			use_corruption_reveal = true

	# Gather visible tiles from entities
	var newly_visible: Array[Vector2i] = []
	for entity in entities_container.get_children():
		if entity.has_method("get_visible_tiles"):
			for tile: Vector2i in entity.get_visible_tiles():
				if not explored_tiles.has(tile):
					newly_visible.append(tile)

	# In Corrupted World, corrupted tiles are always revealed
	if use_corruption_reveal:
		for tile_pos: Vector2i in corrupted_corrupted_tiles.keys():
			if not explored_tiles.has(tile_pos):
				newly_visible.append(tile_pos)

	# Reveal newly visible tiles
	for tile_pos: Vector2i in newly_visible:
		explored_tiles[tile_pos] = true
		fog_map.erase_cell(tile_pos)


func _on_fog_update_requested(world: Enums.WorldType) -> void:
	update_fog(world)

#endregion


#region Input

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		spread_corruption()

	# Debug: Switch worlds
	if event is InputEventKey and event.pressed and event.keycode == GameConstants.KEY_SWITCH_WORLD:
		var target := Enums.WorldType.HUMAN if WorldManager.active_world == Enums.WorldType.CORRUPTED else Enums.WorldType.CORRUPTED
		WorldManager.switch_world(target)

	# Minion spawning hotkeys
	if event is InputEventKey and event.pressed:
		match event.keycode:
			GameConstants.KEY_SPAWN_CRAWLER:
				_try_spawn_minion(Enums.MinionType.CRAWLER)
			GameConstants.KEY_SPAWN_BRUTE:
				_try_spawn_minion(Enums.MinionType.BRUTE)
			GameConstants.KEY_SPAWN_STALKER:
				_try_spawn_minion(Enums.MinionType.STALKER)

#endregion


func _process(delta: float) -> void:
	_process_enemy_spawning(delta)


#region Enemy Spawning

func _on_threat_level_changed(new_level: Enums.ThreatLevel) -> void:
	_current_threat_level = new_level


func _process_enemy_spawning(delta: float) -> void:
	## Process enemy spawn timers based on current threat level
	if _current_threat_level == Enums.ThreatLevel.NONE:
		return

	# Police spawn at POLICE threat and above
	if _current_threat_level >= Enums.ThreatLevel.POLICE:
		_police_spawn_timer += delta
		if _police_spawn_timer >= GameConstants.POLICE_SPAWN_INTERVAL:
			_police_spawn_timer = 0.0
			_try_spawn_enemy(Enums.EnemyType.POLICE, GameConstants.MAX_POLICE)

	# Military spawn at MILITARY threat and above
	if _current_threat_level >= Enums.ThreatLevel.MILITARY:
		_military_spawn_timer += delta
		if _military_spawn_timer >= GameConstants.MILITARY_SPAWN_INTERVAL:
			_military_spawn_timer = 0.0
			_try_spawn_enemy(Enums.EnemyType.MILITARY, GameConstants.MAX_MILITARY)

	# Heavy spawn at HEAVY threat
	if _current_threat_level >= Enums.ThreatLevel.HEAVY:
		_heavy_spawn_timer += delta
		if _heavy_spawn_timer >= GameConstants.HEAVY_SPAWN_INTERVAL:
			_heavy_spawn_timer = 0.0
			_try_spawn_enemy(Enums.EnemyType.HEAVY, GameConstants.MAX_HEAVY)


func _try_spawn_enemy(type: Enums.EnemyType, max_count: int) -> void:
	## Try to spawn an enemy if under the max count
	var current_count := _count_enemies_of_type(type)
	if current_count >= max_count:
		return

	var spawn_pos := _get_enemy_spawn_position()
	if spawn_pos == Vector2i(-1, -1):
		return

	var enemy := EnemyScene.instantiate()
	enemy.setup(type)
	human_entities.add_child(enemy)
	enemy.global_position = Vector2(spawn_pos) * GameConstants.TILE_SIZE + Vector2(GameConstants.TILE_SIZE, GameConstants.TILE_SIZE) / 2.0


func _count_enemies_of_type(type: Enums.EnemyType) -> int:
	var group_name: String
	match type:
		Enums.EnemyType.POLICE:
			group_name = GameConstants.GROUP_POLICE
		Enums.EnemyType.MILITARY:
			group_name = GameConstants.GROUP_MILITARY
		Enums.EnemyType.HEAVY:
			group_name = GameConstants.GROUP_HEAVY
		Enums.EnemyType.SPECIAL_FORCES:
			group_name = GameConstants.GROUP_SPECIAL_FORCES

	return get_tree().get_nodes_in_group(group_name).size()


func _get_enemy_spawn_position() -> Vector2i:
	## Get a spawn position at the edge of the map
	var margin := GameConstants.ENEMY_SPAWN_MARGIN

	# Try multiple positions at map edges
	for _attempt in GameConstants.ENTITY_SPAWN_ATTEMPTS:
		var edge := randi() % 4
		var pos: Vector2i

		match edge:
			0:  # Top edge
				pos = Vector2i(randi_range(margin, map_width - margin - 1), margin)
			1:  # Bottom edge
				pos = Vector2i(randi_range(margin, map_width - margin - 1), map_height - margin - 1)
			2:  # Left edge
				pos = Vector2i(margin, randi_range(margin, map_height - margin - 1))
			3:  # Right edge
				pos = Vector2i(map_width - margin - 1, randi_range(margin, map_height - margin - 1))

		if _is_floor_tile(pos):
			return pos

	return Vector2i(-1, -1)

#endregion


#region Minion Spawning

func _try_spawn_minion(type: Enums.MinionType) -> void:
	## Try to spawn a minion of the given type near the Dark Lord
	if not HivePool.spawn_minion(type):
		return  # Can't afford

	# Spawn near Dark Lord
	if _dark_lord == null:
		return

	var minion := MinionScene.instantiate()
	minion.setup(type)

	# Get the world the Dark Lord is currently in
	var dark_lord_world := _get_dark_lord_world()
	var container := get_entities_container(dark_lord_world)
	container.add_child(minion)

	# Position near Dark Lord with small random offset
	var offset := Vector2(randf_range(-16, 16), randf_range(-16, 16))
	minion.global_position = _dark_lord.global_position + offset


func _get_dark_lord_world() -> Enums.WorldType:
	## Determine which world the Dark Lord is currently in
	if _dark_lord.get_parent() == corrupted_entities:
		return Enums.WorldType.CORRUPTED
	return Enums.WorldType.HUMAN

#endregion


#region Building Placement

func _on_building_requested(building_type: Enums.BuildingType) -> void:
	## Handle building placement request from toolbar
	if _dark_lord == null:
		return

	var dark_lord_world := _get_dark_lord_world()
	var tile_pos := Vector2i(_dark_lord.global_position / GameConstants.TILE_SIZE)

	match building_type:
		Enums.BuildingType.CORRUPTION_NODE:
			_try_place_corruption_node(tile_pos, dark_lord_world)
		Enums.BuildingType.SPAWNING_PIT:
			_try_place_spawning_pit(tile_pos, dark_lord_world)
		Enums.BuildingType.PORTAL:
			_try_place_portal(tile_pos, dark_lord_world)


func _try_place_corruption_node(tile_pos: Vector2i, world: Enums.WorldType) -> void:
	var stats: Dictionary = GameConstants.BUILDING_STATS.get(Enums.BuildingType.CORRUPTION_NODE, {})
	var cost: int = stats.get("cost", 50)

	if not Essence.spend(cost):
		return

	var node := CorruptionNodeScene.instantiate()
	var container := get_entities_container(world)
	container.add_child(node)
	node.setup(tile_pos, world)


func _try_place_spawning_pit(tile_pos: Vector2i, world: Enums.WorldType) -> void:
	var stats: Dictionary = GameConstants.BUILDING_STATS.get(Enums.BuildingType.SPAWNING_PIT, {})
	var cost: int = stats.get("cost", 100)

	if not Essence.spend(cost):
		return

	var pit := SpawningPitScene.instantiate()
	var container := get_entities_container(world)
	container.add_child(pit)
	pit.setup(tile_pos, world)


func _try_place_portal(tile_pos: Vector2i, world: Enums.WorldType) -> void:
	# Check if portal already exists at this position
	if WorldManager.has_portal_at(tile_pos, world):
		return

	if not Essence.spend(PortalData.PLACEMENT_COST):
		return

	var portal := PortalScene.instantiate()
	var container := get_entities_container(world)
	container.add_child(portal)
	portal.setup(tile_pos, world)

#endregion


#region Minion Orders

func _on_retreat_ordered() -> void:
	## Make all minions return to following the Dark Lord
	HivePool.recall_attackers()
	# Signal all minions to return to follow state
	var minions := get_tree().get_nodes_in_group(GameConstants.GROUP_MINIONS)
	for minion in minions:
		if minion.has_method("retreat"):
			minion.retreat()

#endregion

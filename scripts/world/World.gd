extends Node2D
## World manager - orchestrates dual-world system via specialized managers
##
## Dual World System:
##   HumanWorld    - Normal colors, corruption spreads only near portals
##   CorruptedWorld - Purple tint, atmospheric particles, small initial corruption
##
## Managers:
##   MapGenerator     - Procedural terrain generation
##   CorruptionManager - Corruption spreading and tracking
##   FogManager       - Fog of war visibility
##   EntitySpawner    - Dark Lord, civilians, animals, minions
##   EnemySpawner     - Threat-based enemy spawning
##   InputManager     - Input handling, cursor preview, interaction modes

# Manager preloads
const MapGenerator := preload("res://scripts/world/MapGenerator.gd")
const CorruptionManager := preload("res://scripts/world/CorruptionManager.gd")
const FogManager := preload("res://scripts/world/FogManager.gd")
const EntitySpawner := preload("res://scripts/world/EntitySpawner.gd")
const EnemySpawner := preload("res://scripts/world/EnemySpawner.gd")
const InputManager := preload("res://scripts/world/InputManager.gd")

# Building scenes (for placement)
const PortalScene := preload("res://scenes/entities/buildings/portal.tscn")
const CorruptionNodeScene := preload("res://scenes/entities/buildings/corruption_node.tscn")
const SpawningPitScene := preload("res://scenes/entities/buildings/spawning_pit.tscn")

# Building data (for costs)
const PortalData := preload("res://scripts/entities/buildings/PortalData.gd")
const CorruptionNodeData := preload("res://scripts/entities/buildings/CorruptionNodeData.gd")
const SpawningPitData := preload("res://scripts/entities/buildings/SpawningPitData.gd")

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

# Computed map bounds
var map_width: int
var map_height: int

# Managers
var _map_generator: RefCounted
var _corruption_manager: RefCounted
var _fog_manager: RefCounted
var _entity_spawner: RefCounted
var _enemy_spawner: RefCounted
var _input_manager: RefCounted


func _ready() -> void:
	_init_map_size()
	_init_managers()

	if use_procedural_generation:
		_map_generator.generate_map()
	else:
		_map_generator.count_existing_tiles()

	_setup_world_visuals()
	_fog_manager.setup_fog()
	_entity_spawner.spawn_dark_lord(_map_generator.initial_corruption_tile)
	_entity_spawner.spawn_initial_corruption_node(_map_generator.initial_corruption_tile)
	_entity_spawner.spawn_human_world_entities()
	_init_camera()
	_show_world(WorldManager.active_world)

	EventBus.world_switched.connect(_on_world_switched)
	GameManager.start_game()

	# Initial fog update for starting world
	_fog_manager.update_fog(WorldManager.active_world)
	_fog_manager.reveal_initial_corruption(_map_generator.initial_corruption_tile)


func _init_map_size() -> void:
	if override_map_size:
		map_width = custom_map_width
		map_height = custom_map_height
	else:
		map_width = GameConstants.MAP_WIDTH
		map_height = GameConstants.MAP_HEIGHT


func _init_managers() -> void:
	# Create managers
	_map_generator = MapGenerator.new()
	_fog_manager = FogManager.new()
	_corruption_manager = CorruptionManager.new()
	_entity_spawner = EntitySpawner.new()
	_enemy_spawner = EnemySpawner.new()
	_input_manager = InputManager.new()

	# Setup managers with references
	_map_generator.setup(self, map_width, map_height)
	_fog_manager.setup(self, map_width, map_height)
	_corruption_manager.setup(self, _fog_manager)
	_entity_spawner.setup(self, _map_generator, map_width, map_height)
	_enemy_spawner.setup(self, _map_generator, map_width, map_height)
	_input_manager.setup(self, camera, _entity_spawner, _corruption_manager)

	# Add cursor sprites to scene tree
	add_child(_input_manager.cursor_preview)
	add_child(_input_manager.order_cursor)


func _init_camera() -> void:
	camera.set_map_bounds(map_width, map_height)
	camera.center_on_tile(_map_generator.initial_corruption_tile)


func _process(delta: float) -> void:
	_enemy_spawner.process(delta)
	_input_manager.update_cursor_preview()


func _unhandled_input(event: InputEvent) -> void:
	_input_manager.handle_input(event)


#region World Visuals

func _setup_world_visuals() -> void:
	# Human World - normal colors with corruption overlay
	human_world.modulate = GameConstants.HUMAN_WORLD_TINT
	human_corruption_map.modulate = GameConstants.CORRUPTION_COLOR

	# Corrupted World - dark purple tint
	corrupted_world.modulate = GameConstants.CORRUPTED_WORLD_TINT
	corrupted_corruption_map.modulate = GameConstants.CORRUPTION_COLOR

	# Setup atmosphere particles
	_setup_atmosphere_particles()


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

#endregion


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

	# Update collision layer so entity collides with correct world
	if entity.has_method("set_world_collision"):
		entity.set_world_collision(target_world)

#endregion


#region Public API (delegates to managers)

func get_total_tiles() -> int:
	## Get total tile count for corruption percentage
	return _map_generator.total_tiles


func is_tile_occupied(tile_pos: Vector2i) -> bool:
	## Check if a tile is occupied by a structure
	return _map_generator.occupied_tiles.has(tile_pos)


func is_tile_corrupted(tile_pos: Vector2i, world: Enums.WorldType) -> bool:
	## Check if a tile is corrupted in the given world
	return _corruption_manager.is_tile_corrupted(tile_pos, world)


func get_corrupted_tiles(world: Enums.WorldType) -> Dictionary:
	## Get dictionary of corrupted tiles for a world
	match world:
		Enums.WorldType.HUMAN:
			return _corruption_manager.human_corrupted_tiles
		Enums.WorldType.CORRUPTED:
			return _corruption_manager.corrupted_corrupted_tiles
	return {}


func corrupt_tile(tile_pos: Vector2i, world: Enums.WorldType = Enums.WorldType.CORRUPTED) -> void:
	## Corrupt a single tile
	_corruption_manager.corrupt_tile(tile_pos, world)


func spread_corruption() -> void:
	## Spread corruption to a random adjacent tile
	_corruption_manager.spread_corruption()


func corrupt_area_around(center: Vector2i, world: Enums.WorldType, radius: int) -> void:
	## Corrupt tiles within radius of center
	_corruption_manager.corrupt_area_around(center, world, radius)


func can_corrupt_tile(tile_pos: Vector2i, world: Enums.WorldType) -> bool:
	## Check if a tile can be corrupted
	return _corruption_manager.can_corrupt_tile(tile_pos, world)


func update_fog(world: Enums.WorldType) -> void:
	## Update fog visibility for a world
	_fog_manager.update_fog(world)

#endregion


#region Building Placement

func execute_build(tile_pos: Vector2i, building_type: Enums.BuildingType) -> void:
	## Place building at clicked tile (called by InputManager)
	var world := WorldManager.active_world

	match building_type:
		Enums.BuildingType.CORRUPTION_NODE:
			_try_place_corruption_node(tile_pos, world)
		Enums.BuildingType.SPAWNING_PIT:
			_try_place_spawning_pit(tile_pos, world)
		Enums.BuildingType.PORTAL:
			_try_place_portal(tile_pos, world)


func _try_place_corruption_node(tile_pos: Vector2i, world: Enums.WorldType) -> void:
	# Must place on corrupted land
	if not is_tile_corrupted(tile_pos, world):
		return

	var stats: Dictionary = GameConstants.BUILDING_STATS.get(Enums.BuildingType.CORRUPTION_NODE, {})
	var cost: int = stats.get("cost", CorruptionNodeData.DEFAULT_COST)

	if not Essence.can_afford(cost):
		return

	if not Essence.spend(cost):
		return

	var node := CorruptionNodeScene.instantiate()
	var container := get_entities_container(world)
	container.add_child(node)
	node.setup(tile_pos, world)


func _try_place_spawning_pit(tile_pos: Vector2i, world: Enums.WorldType) -> void:
	# Must place on corrupted land
	if not is_tile_corrupted(tile_pos, world):
		return

	var stats: Dictionary = GameConstants.BUILDING_STATS.get(Enums.BuildingType.SPAWNING_PIT, {})
	var cost: int = stats.get("cost", SpawningPitData.DEFAULT_COST)

	if not Essence.can_afford(cost):
		return

	if not Essence.spend(cost):
		return

	var pit := SpawningPitScene.instantiate()
	var container := get_entities_container(world)
	container.add_child(pit)
	pit.setup(tile_pos, world)


func _try_place_portal(tile_pos: Vector2i, world: Enums.WorldType) -> void:
	# Must place on corrupted land
	if not is_tile_corrupted(tile_pos, world):
		return

	# Check if portal already exists at this position in either world
	if WorldManager.has_portal_at(tile_pos, Enums.WorldType.CORRUPTED) or WorldManager.has_portal_at(tile_pos, Enums.WorldType.HUMAN):
		return

	if not Essence.can_afford(PortalData.PLACEMENT_COST):
		return

	if not Essence.spend(PortalData.PLACEMENT_COST):
		return

	# Create portal in current world
	var portal := PortalScene.instantiate()
	var container := get_entities_container(world)
	container.add_child(portal)
	portal.setup(tile_pos, world)

	# Auto-create linked portal in the other world
	var other_world: Enums.WorldType
	if world == Enums.WorldType.CORRUPTED:
		other_world = Enums.WorldType.HUMAN
	else:
		other_world = Enums.WorldType.CORRUPTED

	var other_portal := PortalScene.instantiate()
	var other_container := get_entities_container(other_world)
	other_container.add_child(other_portal)
	other_portal.setup(tile_pos, other_world)

	# Create initial corruption around the Human World portal
	corrupt_area_around(tile_pos, Enums.WorldType.HUMAN, GameConstants.PORTAL_INITIAL_CORRUPTION_RANGE)

#endregion

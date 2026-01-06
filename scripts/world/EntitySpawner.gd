extends RefCounted
## Handles spawning of entities: Dark Lord, civilians, animals, police stations, minions
## Uses preloaded scenes for instantiation
## Note: Policemen are spawned by PoliceStationController, not directly by this spawner

const DarkLordScene := preload("res://scenes/entities/dark_lord/dark_lord.tscn")
const CivilianScene := preload("res://scenes/entities/humans/civilian.tscn")
const AnimalScene := preload("res://scenes/entities/humans/animal.tscn")
const MinionScene := preload("res://scenes/entities/minions/minion.tscn")
const CorruptionNodeScene := preload("res://scenes/entities/buildings/corruption_node.tscn")
const AlarmTowerScene := preload("res://scenes/entities/buildings/alarm_tower.tscn")
const PoliceStationScene := preload("res://scenes/entities/buildings/police_station.tscn")

# Reference to World (for map access)
var _world: Node2D

# Reference to MapGenerator (for floor tile checks)
var _map_generator: RefCounted

# Dark Lord reference
var dark_lord: CharacterBody2D

# Map dimensions
var _map_width: int
var _map_height: int


func setup(world: Node2D, map_generator: RefCounted, map_width: int, map_height: int) -> void:
	_world = world
	_map_generator = map_generator
	_map_width = map_width
	_map_height = map_height


func spawn_dark_lord(initial_tile: Vector2i) -> void:
	## Spawn the Dark Lord at the initial corruption tile
	dark_lord = DarkLordScene.instantiate()
	var tile_size := GameConstants.TILE_SIZE
	dark_lord.global_position = Vector2(initial_tile) * tile_size + Vector2(tile_size, tile_size) / 2.0
	# Dark Lord starts in Corrupted World
	_world.corrupted_entities.add_child(dark_lord)


func spawn_initial_corruption_node(initial_tile: Vector2i) -> void:
	## Spawn the initial Corruption Node in Corrupted World
	var initial_node := CorruptionNodeScene.instantiate()
	_world.corrupted_entities.add_child(initial_node)
	# Note: setup() is called after adding to tree so @onready vars are ready
	initial_node.setup(initial_tile, Enums.WorldType.CORRUPTED)


func spawn_human_world_entities() -> void:
	## Spawn civilians, animals, police stations, and alarm towers in Human World
	_spawn_alarm_towers()
	_spawn_police_stations()
	_spawn_civilians()
	_spawn_animals()


func _spawn_alarm_towers() -> void:
	for i in GameConstants.ALARM_TOWER_COUNT:
		var tower := AlarmTowerScene.instantiate()
		var spawn_pos := _get_random_floor_tile()
		_world.human_entities.add_child(tower)
		tower.setup(spawn_pos)


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


func _spawn_police_stations() -> void:
	for i in GameConstants.POLICE_STATION_COUNT:
		var station := PoliceStationScene.instantiate()
		var spawn_pos := _get_random_floor_tile()
		_world.human_entities.add_child(station)
		station.setup(spawn_pos)


func _place_entity_at_tile(entity: Node2D, tile_pos: Vector2i, world: Enums.WorldType) -> void:
	var container: Node2D = _world.get_entities_container(world)
	container.add_child(entity)
	var tile_size := GameConstants.TILE_SIZE
	entity.global_position = Vector2(tile_pos) * tile_size + Vector2(tile_size, tile_size) / 2.0


func _get_random_floor_tile() -> Vector2i:
	## Pick a random unoccupied floor tile
	for i in GameConstants.ENTITY_SPAWN_ATTEMPTS:
		var x := randi_range(GameConstants.MAP_EDGE_MARGIN, _map_width - GameConstants.MAP_EDGE_MARGIN - 1)
		var y := randi_range(GameConstants.MAP_EDGE_MARGIN, _map_height - GameConstants.MAP_EDGE_MARGIN - 1)
		var pos := Vector2i(x, y)
		if _map_generator.is_floor_tile(pos):
			return pos
	return Vector2i(_map_width / 2, _map_height / 2)


func spawn_minion(type: Enums.MinionType) -> bool:
	## Try to spawn a minion of the given type near the Dark Lord
	## Returns true if spawn succeeded
	if not HivePool.spawn_minion(type):
		return false  # Can't afford

	# Spawn near Dark Lord
	if dark_lord == null:
		return false

	var minion := MinionScene.instantiate()
	minion.setup(type)

	# Get the world the Dark Lord is currently in
	var dark_lord_world := get_dark_lord_world()
	var container: Node2D = _world.get_entities_container(dark_lord_world)
	container.add_child(minion)

	# Position near Dark Lord with small random offset
	var spawn_range := float(GameConstants.TILE_SIZE)
	var offset := Vector2(randf_range(-spawn_range, spawn_range), randf_range(-spawn_range, spawn_range))
	minion.global_position = dark_lord.global_position + offset

	# Set collision layer to match the world the minion is in
	minion.set_world_collision(dark_lord_world)
	return true


func get_dark_lord_world() -> Enums.WorldType:
	## Determine which world the Dark Lord is currently in
	if dark_lord and dark_lord.get_parent() == _world.corrupted_entities:
		return Enums.WorldType.CORRUPTED
	return Enums.WorldType.HUMAN

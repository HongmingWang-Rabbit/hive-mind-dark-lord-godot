extends RefCounted
## Handles threat-based enemy spawning
## Spawns police, military, and heavy units based on current threat level

const EnemyScene := preload("res://scenes/entities/enemies/enemy.tscn")

# Reference to World (for map access)
var _world: Node2D

# Reference to MapGenerator (for floor tile checks)
var _map_generator: RefCounted

# Spawn timers
var _police_spawn_timer: float = 0.0
var _military_spawn_timer: float = 0.0
var _heavy_spawn_timer: float = 0.0
var _random_enemy_spawn_timer: float = 0.0

# Current threat level
var _current_threat_level: Enums.ThreatLevel = Enums.ThreatLevel.NONE

# Map dimensions
var _map_width: int
var _map_height: int


func setup(world: Node2D, map_generator: RefCounted, map_width: int, map_height: int) -> void:
	_world = world
	_map_generator = map_generator
	_map_width = map_width
	_map_height = map_height
	EventBus.threat_level_changed.connect(_on_threat_level_changed)


func process(delta: float) -> void:
	## Process enemy spawn timers based on current threat level

	# Random enemy spawning (always active if enabled)
	if GameConstants.RANDOM_ENEMY_SPAWN_ENABLED:
		_random_enemy_spawn_timer += delta
		if _random_enemy_spawn_timer >= GameConstants.RANDOM_ENEMY_SPAWN_INTERVAL:
			_random_enemy_spawn_timer = 0.0
			_try_spawn_random_enemy()

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
	_world.human_entities.add_child(enemy)
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

	return _world.get_tree().get_nodes_in_group(group_name).size()


func _get_enemy_spawn_position() -> Vector2i:
	## Get a spawn position at the edge of the map
	var margin := GameConstants.ENEMY_SPAWN_MARGIN

	# Try multiple positions at map edges
	for _attempt in GameConstants.ENTITY_SPAWN_ATTEMPTS:
		var edge := randi_range(0, 3)
		var pos: Vector2i

		match edge:
			0:  # Top edge
				pos = Vector2i(randi_range(margin, _map_width - margin - 1), margin)
			1:  # Bottom edge
				pos = Vector2i(randi_range(margin, _map_width - margin - 1), _map_height - margin - 1)
			2:  # Left edge
				pos = Vector2i(margin, randi_range(margin, _map_height - margin - 1))
			3:  # Right edge
				pos = Vector2i(_map_width - margin - 1, randi_range(margin, _map_height - margin - 1))

		if _map_generator.is_floor_tile(pos):
			return pos

	return Vector2i(-1, -1)


func _try_spawn_random_enemy() -> void:
	## Spawn a random military enemy (always active, independent of threat level)
	var current_count := _world.get_tree().get_nodes_in_group(GameConstants.GROUP_ENEMIES).size()
	if current_count >= GameConstants.RANDOM_ENEMY_MAX:
		return

	# Pick a random enemy type (weighted towards military)
	var roll := randi_range(0, 99)
	var enemy_type: Enums.EnemyType
	if roll < GameConstants.RANDOM_ENEMY_MILITARY_THRESHOLD:
		enemy_type = Enums.EnemyType.MILITARY
	elif roll < GameConstants.RANDOM_ENEMY_POLICE_THRESHOLD:
		enemy_type = Enums.EnemyType.POLICE
	else:
		enemy_type = Enums.EnemyType.HEAVY

	var spawn_pos := _get_enemy_spawn_position()
	if spawn_pos == Vector2i(-1, -1):
		return

	var enemy := EnemyScene.instantiate()
	enemy.setup(enemy_type)
	_world.human_entities.add_child(enemy)
	enemy.global_position = Vector2(spawn_pos) * GameConstants.TILE_SIZE + Vector2(GameConstants.TILE_SIZE, GameConstants.TILE_SIZE) / 2.0


func _on_threat_level_changed(new_level: Enums.ThreatLevel) -> void:
	_current_threat_level = new_level


func reset() -> void:
	## Reset all spawn timers
	_police_spawn_timer = 0.0
	_military_spawn_timer = 0.0
	_heavy_spawn_timer = 0.0
	_random_enemy_spawn_timer = 0.0
	_current_threat_level = Enums.ThreatLevel.NONE

extends StaticBody2D
## Spawning Pit building - auto-spawns minions periodically
## Place to create secondary spawn points for minions

const Data := preload("res://scripts/entities/buildings/SpawningPitData.gd")
const FogUtils := preload("res://scripts/utils/fog_utils.gd")
const MinionScene := preload("res://scenes/entities/minions/minion.tscn")

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var spawn_timer: Timer = $SpawnTimer

# Building state
var tile_pos: Vector2i
var world: Enums.WorldType


func _ready() -> void:
	_setup_collision_shape()
	_setup_sprite()
	_setup_spawn_timer()
	add_to_group(GameConstants.GROUP_BUILDINGS)
	add_to_group(GameConstants.GROUP_SPAWNING_PITS)


func setup(building_tile_pos: Vector2i, building_world: Enums.WorldType) -> void:
	tile_pos = building_tile_pos
	world = building_world

	# Set collision layer based on world (so buildings don't collide across worlds)
	_set_world_collision_layer(world)

	# Position at tile center
	var tile_size := GameConstants.TILE_SIZE
	global_position = Vector2(tile_pos) * tile_size + Vector2(tile_size, tile_size) / 2.0

	# Update fog around pit
	EventBus.fog_update_requested.emit(world)
	EventBus.building_placed.emit(Enums.BuildingType.SPAWNING_PIT, global_position)

	# Start spawning minions
	spawn_timer.start()


func _setup_collision_shape() -> void:
	var shape := CircleShape2D.new()
	shape.radius = Data.COLLISION_RADIUS
	collision_shape.shape = shape


func _setup_sprite() -> void:
	if sprite.texture == null:
		return
	# Scale sprite based on collision radius
	var texture_size := sprite.texture.get_size()
	var desired_diameter := Data.COLLISION_RADIUS * 2.0 * Data.SPRITE_SIZE_RATIO
	var max_dimension := maxf(texture_size.x, texture_size.y)
	var scale_factor := desired_diameter / max_dimension
	sprite.scale = Vector2(scale_factor, scale_factor)
	sprite.modulate = Data.ACTIVE_COLOR


func _setup_spawn_timer() -> void:
	spawn_timer.wait_time = Data.SPAWN_INTERVAL
	spawn_timer.one_shot = false
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)


func _on_spawn_timer_timeout() -> void:
	_try_spawn_minion()


func _try_spawn_minion() -> void:
	## Try to spawn a minion at this pit's location
	var minion_type: Enums.MinionType = Data.SPAWN_TYPE as Enums.MinionType

	# Check if we can afford the minion (uses HivePool which checks essence)
	if not HivePool.spawn_minion(minion_type):
		return  # Can't afford or at capacity

	# Get the world node to add minion to correct container
	var world_node := get_tree().current_scene
	if world_node == null or not world_node.has_method("get_entities_container"):
		return

	var minion := MinionScene.instantiate()
	minion.setup(minion_type)

	# Add to the same world as this pit
	var container: Node2D = world_node.get_entities_container(world)
	container.add_child(minion)

	# Position at pit with small random offset
	var spawn_range := float(GameConstants.TILE_SIZE) * Data.SPAWN_OFFSET_RATIO
	var offset := Vector2(randf_range(-spawn_range, spawn_range), randf_range(-spawn_range, spawn_range))
	minion.global_position = global_position + offset

	# Set collision layer to match the world
	minion.set_world_collision(world)


func _set_world_collision_layer(target_world: Enums.WorldType) -> void:
	## Set collision layer based on which world this building is in
	match target_world:
		Enums.WorldType.CORRUPTED:
			collision_layer = 1 << (GameConstants.COLLISION_LAYER_CORRUPTED_WORLD - 1)
		Enums.WorldType.HUMAN:
			collision_layer = 1 << (GameConstants.COLLISION_LAYER_HUMAN_WORLD - 1)


#region Fog of War

func get_visible_tiles() -> Array[Vector2i]:
	## Returns array of tiles visible around pit
	return FogUtils.get_tiles_in_sight_range(tile_pos, Data.SIGHT_RANGE)

#endregion

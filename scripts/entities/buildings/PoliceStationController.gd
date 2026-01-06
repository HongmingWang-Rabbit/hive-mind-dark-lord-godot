extends StaticBody2D
## Police Station - Human defense structure
## Spawns and maintains policemen in the area around it.
## Each station can have up to MAX_POLICEMEN_PER_STATION active at once.

const Data := preload("res://scripts/entities/buildings/PoliceStationData.gd")
const PolicemanScene := preload("res://scenes/entities/humans/policeman.tscn")

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var spawn_timer: Timer = $SpawnTimer

# State
var _tile_pos: Vector2i
var _spawned_policemen: Array[Node2D] = []


func _ready() -> void:
	add_to_group(GameConstants.GROUP_POLICE_STATIONS)
	_setup_collision_shape()
	_setup_sprite()
	_setup_spawn_timer()
	# Police stations are in Human World only
	set_world_collision(Enums.WorldType.HUMAN)


func setup(tile_pos: Vector2i) -> void:
	## Call after instantiation to configure position
	_tile_pos = tile_pos
	var tile_size := GameConstants.TILE_SIZE
	global_position = Vector2(tile_pos) * tile_size + Vector2(tile_size, tile_size) / 2.0


func _setup_collision_shape() -> void:
	var shape := CircleShape2D.new()
	shape.radius = Data.COLLISION_RADIUS
	collision_shape.shape = shape


func _setup_sprite() -> void:
	sprite.texture = load(Data.SPRITE_PATH)
	if sprite.texture:
		var texture_size := sprite.texture.get_size()
		var desired_diameter := Data.COLLISION_RADIUS * 2.0 * Data.SPRITE_SIZE_RATIO
		var max_dimension := maxf(texture_size.x, texture_size.y)
		var scale_factor := desired_diameter / max_dimension
		sprite.scale = Vector2(scale_factor, scale_factor)
	sprite.modulate = Data.ACTIVE_COLOR


func _setup_spawn_timer() -> void:
	spawn_timer.wait_time = GameConstants.POLICE_STATION_SPAWN_INTERVAL
	spawn_timer.one_shot = false
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()


func _on_spawn_timer_timeout() -> void:
	_cleanup_dead_policemen()
	_try_spawn_policeman()


func _cleanup_dead_policemen() -> void:
	## Remove invalid references (dead policemen)
	_spawned_policemen = _spawned_policemen.filter(func(p): return is_instance_valid(p))


func _try_spawn_policeman() -> void:
	## Spawn a policeman if under the max count
	if _spawned_policemen.size() >= GameConstants.MAX_POLICEMEN_PER_STATION:
		return

	var policeman := PolicemanScene.instantiate()

	# Get parent container (human_entities)
	var container := get_parent()
	if container == null:
		policeman.queue_free()
		return

	container.add_child(policeman)

	# Position near the station with random offset
	var angle := randf() * TAU
	var offset := Vector2(cos(angle), sin(angle)) * Data.SPAWN_RADIUS
	policeman.global_position = global_position + offset

	_spawned_policemen.append(policeman)


func get_active_policemen_count() -> int:
	_cleanup_dead_policemen()
	return _spawned_policemen.size()


#region World Collision

func set_world_collision(target_world: Enums.WorldType) -> void:
	## Set collision layer based on world
	var world_layer: int
	match target_world:
		Enums.WorldType.CORRUPTED:
			world_layer = 1 << (GameConstants.COLLISION_LAYER_CORRUPTED_WORLD - 1)
		Enums.WorldType.HUMAN:
			world_layer = 1 << (GameConstants.COLLISION_LAYER_HUMAN_WORLD - 1)

	collision_layer = world_layer
	collision_mask = 0  # Static body, doesn't need to detect collisions

#endregion

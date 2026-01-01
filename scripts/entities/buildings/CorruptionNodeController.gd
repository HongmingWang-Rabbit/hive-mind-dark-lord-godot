extends StaticBody2D
## Corruption Node building - spreads corruption and generates essence
## Corruption auto-spreads every few seconds within node's range

const Data := preload("res://scripts/entities/buildings/CorruptionNodeData.gd")
const FogUtils := preload("res://scripts/utils/fog_utils.gd")

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var spread_timer: Timer = $SpreadTimer

# Building state
var tile_pos: Vector2i
var world: Enums.WorldType


func _ready() -> void:
	_setup_collision_shape()
	_setup_sprite()
	_setup_spread_timer()
	add_to_group(GameConstants.GROUP_BUILDINGS)
	add_to_group(GameConstants.GROUP_CORRUPTION_NODES)


func setup(building_tile_pos: Vector2i, building_world: Enums.WorldType) -> void:
	tile_pos = building_tile_pos
	world = building_world

	# Set collision layer based on world (so buildings don't collide across worlds)
	_set_world_collision_layer(world)

	# Position at tile center
	var tile_size := GameConstants.TILE_SIZE
	global_position = Vector2(tile_pos) * tile_size + Vector2(tile_size, tile_size) / 2.0

	# Add essence income bonus
	var stats: Dictionary = GameConstants.BUILDING_STATS.get(Enums.BuildingType.CORRUPTION_NODE, {})
	var essence_bonus: int = stats.get("essence_bonus", Data.DEFAULT_ESSENCE_BONUS)
	Essence.add_income(essence_bonus)

	# Corrupt the tile the node is on
	_corrupt_tile(tile_pos)

	# Update fog around node
	EventBus.fog_update_requested.emit(world)
	EventBus.building_placed.emit(Enums.BuildingType.CORRUPTION_NODE, global_position)

	# Start spreading corruption
	spread_timer.start()


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


func _setup_spread_timer() -> void:
	spread_timer.wait_time = GameConstants.CORRUPTION_SPREAD_INTERVAL
	spread_timer.one_shot = false
	spread_timer.timeout.connect(_on_spread_timer_timeout)


func _on_spread_timer_timeout() -> void:
	_spread_corruption()


func _spread_corruption() -> void:
	## Spread corruption to one adjacent tile within range
	var world_node := get_tree().current_scene
	if world_node == null or not world_node.has_method("is_tile_corrupted"):
		return

	# Get all tiles within range that could be corrupted
	var candidates: Array[Vector2i] = []
	var max_range := GameConstants.CORRUPTION_NODE_RANGE

	# Check corrupted tiles within range for expansion candidates
	for dx in range(-max_range, max_range + 1):
		for dy in range(-max_range, max_range + 1):
			var check_pos := tile_pos + Vector2i(dx, dy)
			var distance := absi(dx) + absi(dy)  # Manhattan distance

			# Skip if outside range
			if distance > max_range:
				continue

			# Skip if already corrupted
			if world_node.is_tile_corrupted(check_pos, world):
				# Check neighbors of corrupted tiles for expansion
				for dir: Vector2i in GameConstants.ORTHOGONAL_DIRS:
					var neighbor := check_pos + dir
					var neighbor_dist := absi(neighbor.x - tile_pos.x) + absi(neighbor.y - tile_pos.y)
					if neighbor_dist <= max_range:
						if world_node.can_corrupt_tile(neighbor, world):
							if not candidates.has(neighbor):
								candidates.append(neighbor)

	# Pick a random candidate and corrupt it
	if candidates.size() > 0:
		var target: Vector2i = candidates[randi_range(0, candidates.size() - 1)]
		_corrupt_tile(target)


func _corrupt_tile(pos: Vector2i) -> void:
	var world_node := get_tree().current_scene
	if world_node != null and world_node.has_method("corrupt_tile"):
		world_node.corrupt_tile(pos, world)


func _set_world_collision_layer(target_world: Enums.WorldType) -> void:
	## Set collision layer based on which world this building is in
	match target_world:
		Enums.WorldType.CORRUPTED:
			collision_layer = 1 << (GameConstants.COLLISION_LAYER_CORRUPTED_WORLD - 1)
		Enums.WorldType.HUMAN:
			collision_layer = 1 << (GameConstants.COLLISION_LAYER_HUMAN_WORLD - 1)


#region Fog of War

func get_visible_tiles() -> Array[Vector2i]:
	## Returns array of tiles visible around node
	return FogUtils.get_tiles_in_sight_range(tile_pos, Data.SIGHT_RANGE)

#endregion

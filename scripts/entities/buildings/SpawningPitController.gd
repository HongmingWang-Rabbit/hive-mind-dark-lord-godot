extends StaticBody2D
## Spawning Pit building - allows spawning minions at this location
## Place to create secondary spawn points for minions

const Data := preload("res://scripts/entities/buildings/SpawningPitData.gd")
const FogUtils := preload("res://scripts/utils/fog_utils.gd")

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# Building state
var tile_pos: Vector2i
var world: Enums.WorldType


func _ready() -> void:
	_setup_collision_shape()
	_setup_sprite()
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

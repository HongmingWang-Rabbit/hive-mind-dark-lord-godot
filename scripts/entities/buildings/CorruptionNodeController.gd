extends StaticBody2D
## Corruption Node building - generates passive essence income
## Place in Corrupted World to boost income

const Data := preload("res://scripts/entities/buildings/CorruptionNodeData.gd")
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
	add_to_group(GameConstants.GROUP_CORRUPTION_NODES)


func setup(building_tile_pos: Vector2i, building_world: Enums.WorldType) -> void:
	tile_pos = building_tile_pos
	world = building_world

	# Position at tile center
	var tile_size := GameConstants.TILE_SIZE
	global_position = Vector2(tile_pos) * tile_size + Vector2(tile_size, tile_size) / 2.0

	# Add essence income bonus
	var stats: Dictionary = GameConstants.BUILDING_STATS.get(Enums.BuildingType.CORRUPTION_NODE, {})
	var essence_bonus: int = stats.get("essence_bonus", 2)
	Essence.add_income(essence_bonus)

	# Update fog around node
	EventBus.fog_update_requested.emit(world)
	EventBus.building_placed.emit(Enums.BuildingType.CORRUPTION_NODE, global_position)


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


#region Fog of War

func get_visible_tiles() -> Array[Vector2i]:
	## Returns array of tiles visible around node
	return FogUtils.get_tiles_in_sight_range(tile_pos, Data.SIGHT_RANGE)

#endregion

extends StaticBody2D
## Portal building - allows travel between Corrupted and Human worlds
## Place in one world, then place matching portal in other world to activate

const Data := preload("res://scripts/entities/buildings/PortalData.gd")
const FogUtils := preload("res://scripts/utils/fog_utils.gd")

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var travel_area: Area2D = $TravelArea
@onready var travel_shape: CollisionShape2D = $TravelArea/CollisionShape2D

# Portal state
var tile_pos: Vector2i
var world: Enums.WorldType
var is_linked := false

# Cooldown tracking
var _travel_cooldown := 0.0


func _ready() -> void:
	_setup_collision_shape()
	_setup_travel_area()
	_setup_sprite()
	add_to_group(GameConstants.GROUP_BUILDINGS)
	add_to_group(GameConstants.GROUP_PORTALS)

	travel_area.body_entered.connect(_on_travel_area_body_entered)
	EventBus.portal_placed.connect(_on_portal_placed)


func setup(portal_tile_pos: Vector2i, portal_world: Enums.WorldType) -> void:
	tile_pos = portal_tile_pos
	world = portal_world

	# Position at tile center
	var tile_size := GameConstants.TILE_SIZE
	global_position = Vector2(tile_pos) * tile_size + Vector2(tile_size, tile_size) / 2.0

	# Register with WorldManager
	WorldManager.register_portal(tile_pos, world)

	# Check if already linked (portal exists in other world)
	_update_linked_status()

	# Update fog around portal
	EventBus.fog_update_requested.emit(world)


func _setup_collision_shape() -> void:
	var shape := CircleShape2D.new()
	shape.radius = Data.COLLISION_RADIUS
	collision_shape.shape = shape


func _setup_travel_area() -> void:
	var shape := CircleShape2D.new()
	shape.radius = Data.TRAVEL_TRIGGER_RADIUS
	travel_shape.shape = shape


func _setup_sprite() -> void:
	# Scale sprite based on collision radius
	var texture_size := sprite.texture.get_size()
	var desired_diameter := Data.COLLISION_RADIUS * 2.0 * Data.SPRITE_SIZE_RATIO
	var max_dimension := maxf(texture_size.x, texture_size.y)
	var scale_factor := desired_diameter / max_dimension
	sprite.scale = Vector2(scale_factor, scale_factor)
	_update_visual()


func _process(delta: float) -> void:
	if _travel_cooldown > 0.0:
		_travel_cooldown -= delta


func _update_linked_status() -> void:
	is_linked = WorldManager.is_portal_linked(tile_pos)
	_update_visual()


func _update_visual() -> void:
	if is_linked:
		sprite.modulate = Data.ACTIVE_COLOR
	else:
		sprite.modulate = Data.INACTIVE_COLOR


func _on_portal_placed(placed_tile_pos: Vector2i, _placed_world: Enums.WorldType) -> void:
	# Check if this portal is now linked
	if placed_tile_pos == tile_pos:
		_update_linked_status()
		if is_linked:
			EventBus.portal_activated.emit(tile_pos)


func _on_travel_area_body_entered(body: Node2D) -> void:
	if not is_linked:
		return

	if _travel_cooldown > 0.0:
		return

	if not body.is_in_group(GameConstants.GROUP_DARK_LORD):
		return

	# Determine target world
	var target_world: Enums.WorldType
	if world == Enums.WorldType.CORRUPTED:
		target_world = Enums.WorldType.HUMAN
	else:
		target_world = Enums.WorldType.CORRUPTED

	# Physically move entity to target world
	var world_node = get_tree().current_scene
	if world_node.has_method("transfer_entity_to_world"):
		world_node.transfer_entity_to_world(body, target_world)

	# Switch view to follow the entity
	WorldManager.switch_world(target_world)
	_travel_cooldown = GameConstants.PORTAL_TRAVEL_COOLDOWN


#region Fog of War

func get_visible_tiles() -> Array[Vector2i]:
	## Returns array of tiles visible around portal
	return FogUtils.get_tiles_in_sight_range(tile_pos, Data.SIGHT_RANGE)

#endregion

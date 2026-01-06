extends StaticBody2D
## Military Portal - Human military gateway to invade Corrupted World
## Spawns at map edges when threat >= 70%. Enemies walk through to enter Corrupted World.
## Player cannot close or destroy these portals.

const Data := preload("res://scripts/entities/buildings/MilitaryPortalData.gd")

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var travel_area: Area2D = $TravelArea
@onready var travel_shape: CollisionShape2D = $TravelArea/CollisionShape2D

# Portal state
var _tile_pos: Vector2i

# Cooldown tracking
var _travel_cooldown := 0.0

# Travel immunity - prevents bounce-back when entity arrives
# Key: entity instance ID, Value: time remaining
static var _travel_immunity: Dictionary = {}


func _ready() -> void:
	add_to_group(GameConstants.GROUP_MILITARY_PORTALS)
	_setup_collision_shape()
	_setup_travel_area()
	_setup_sprite()
	# Military portals exist in Human World, allow travel to Corrupted World
	set_world_collision(Enums.WorldType.HUMAN)

	travel_area.body_entered.connect(_on_travel_area_body_entered)


func setup(tile_pos: Vector2i) -> void:
	## Call after instantiation to configure position
	_tile_pos = tile_pos
	var tile_size := GameConstants.TILE_SIZE
	global_position = Vector2(tile_pos) * tile_size + Vector2(tile_size, tile_size) / 2.0


func _setup_collision_shape() -> void:
	var shape := CircleShape2D.new()
	shape.radius = Data.COLLISION_RADIUS
	collision_shape.shape = shape


func _setup_travel_area() -> void:
	var shape := CircleShape2D.new()
	shape.radius = Data.TRAVEL_TRIGGER_RADIUS
	travel_shape.shape = shape


func _setup_sprite() -> void:
	sprite.texture = load(Data.SPRITE_PATH)
	if sprite.texture:
		var texture_size := sprite.texture.get_size()
		var desired_diameter := Data.COLLISION_RADIUS * 2.0 * Data.SPRITE_SIZE_RATIO
		var max_dimension := maxf(texture_size.x, texture_size.y)
		var scale_factor := desired_diameter / max_dimension
		sprite.scale = Vector2(scale_factor, scale_factor)
	sprite.modulate = Data.ACTIVE_COLOR


func _process(delta: float) -> void:
	if _travel_cooldown > 0.0:
		_travel_cooldown -= delta

	# Update travel immunity timers
	var expired: Array = []
	for entity_id: int in _travel_immunity.keys():
		_travel_immunity[entity_id] -= delta
		if _travel_immunity[entity_id] <= 0.0:
			expired.append(entity_id)
	for entity_id: int in expired:
		_travel_immunity.erase(entity_id)


func _on_travel_area_body_entered(body: Node2D) -> void:
	if _travel_cooldown > 0.0:
		return

	# Check if entity has travel immunity (just came through a portal)
	var entity_id := body.get_instance_id()
	if _travel_immunity.has(entity_id):
		return

	# Only military enemies can use this portal
	if not body.is_in_group(GameConstants.GROUP_ENEMIES):
		return

	# Grant travel immunity to prevent bounce-back
	_travel_immunity[entity_id] = GameConstants.PORTAL_TRAVEL_COOLDOWN

	# Transfer entity to Corrupted World
	var world_node = get_tree().current_scene
	if world_node.has_method("transfer_entity_to_world"):
		world_node.transfer_entity_to_world(body, Enums.WorldType.CORRUPTED)

	_travel_cooldown = GameConstants.PORTAL_TRAVEL_COOLDOWN


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

	# TravelArea should detect entities in this world
	travel_area.collision_mask = world_layer

#endregion

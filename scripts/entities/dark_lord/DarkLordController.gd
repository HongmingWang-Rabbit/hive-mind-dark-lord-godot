extends CharacterBody2D
## Hive Mind Dark Lord - the player's avatar that wanders corrupted territory
## Spawns at initial corruption point. Can place portals to travel between worlds.

const Data := preload("res://scripts/entities/dark_lord/DarkLordData.gd")
const PortalData := preload("res://scripts/entities/buildings/PortalData.gd")
const PortalScene := preload("res://scenes/entities/buildings/portal.tscn")

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var wander_timer: Timer = $WanderTimer

# Current movement target
var _target_position: Vector2
var _is_moving := false


func _ready() -> void:
	add_to_group("dark_lord")
	_setup_collision_shape()
	_setup_sprite_scale()
	_start_wander_timer()


func _setup_collision_shape() -> void:
	var shape := CircleShape2D.new()
	shape.radius = Data.COLLISION_RADIUS
	collision_shape.shape = shape


func _setup_sprite_scale() -> void:
	# Calculate scale from collision radius and texture size
	var texture_size := sprite.texture.get_size()
	var desired_diameter := Data.COLLISION_RADIUS * 2.0 * Data.SPRITE_SIZE_RATIO
	var max_dimension := maxf(texture_size.x, texture_size.y)
	var scale_factor := desired_diameter / max_dimension
	sprite.scale = Vector2(scale_factor, scale_factor)


func _physics_process(_delta: float) -> void:
	if _is_moving:
		_move_toward_target()


func _move_toward_target() -> void:
	var direction := (_target_position - global_position).normalized()
	velocity = direction * Data.WANDER_SPEED

	# Check if reached target
	if global_position.distance_to(_target_position) < Data.WANDER_SPEED * get_physics_process_delta_time():
		global_position = _target_position
		velocity = Vector2.ZERO
		_is_moving = false
		_start_wander_timer()
	else:
		# Flip sprite based on movement direction
		if velocity.x != 0:
			sprite.flip_h = velocity.x < 0
		move_and_slide()


func _pick_new_wander_target() -> void:
	# Pick a random direction and move one tile
	var tile_size := GameConstants.TILE_SIZE
	var directions := GameConstants.ALL_DIRS

	var random_index := randi_range(0, directions.size() - 1)
	var random_dir: Vector2i = directions[random_index]
	_target_position = global_position + Vector2(random_dir) * tile_size


func _start_wander_timer() -> void:
	var interval := randf_range(Data.WANDER_INTERVAL_MIN, Data.WANDER_INTERVAL_MAX)
	wander_timer.start(interval)


func _on_wander_timer_timeout() -> void:
	_pick_new_wander_target()
	_is_moving = true


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == GameConstants.KEY_PLACE_PORTAL:
		_try_place_portal()


func _try_place_portal() -> void:
	# Check if can afford
	if not Essence.can_afford(PortalData.PLACEMENT_COST):
		return

	# Get current tile position
	var tile_size := GameConstants.TILE_SIZE
	var current_tile := Vector2i(global_position / tile_size)

	# Check if portal already exists at this position in current world
	if WorldManager.has_portal_at(current_tile, WorldManager.active_world):
		return

	# Spend essence
	Essence.spend(PortalData.PLACEMENT_COST)

	# Create portal
	var portal := PortalScene.instantiate()
	get_parent().add_child(portal)
	portal.setup(current_tile, WorldManager.active_world)

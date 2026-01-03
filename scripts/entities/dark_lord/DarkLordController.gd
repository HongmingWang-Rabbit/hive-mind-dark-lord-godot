extends CharacterBody2D
## Hive Mind Dark Lord - the player's avatar that wanders corrupted territory
## Spawns at initial corruption point. Can place portals to travel between worlds.

const Data := preload("res://scripts/entities/dark_lord/DarkLordData.gd")
const PortalData := preload("res://scripts/entities/buildings/PortalData.gd")
const PortalScene := preload("res://scenes/entities/buildings/portal.tscn")
const FogUtils := preload("res://scripts/utils/fog_utils.gd")

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var wander_timer: Timer = $WanderTimer
@onready var attack_timer: Timer = $AttackTimer
@onready var attack_range: Area2D = $AttackRange

# Current movement target
var _target_position: Vector2
var _is_moving := false
var _is_player_commanded := false  # True when moving to player-clicked position

# Fog tracking - update fog when crossing tile boundaries
var _last_tile_pos: Vector2i = Vector2i(-999, -999)

# Combat
var _hp: int
var _current_target: Node2D = null
var _targets_in_range: Array[Node2D] = []


func _ready() -> void:
	add_to_group(GameConstants.GROUP_DARK_LORD)
	add_to_group(GameConstants.GROUP_THREATS)
	_hp = GameConstants.DARK_LORD_HP
	_setup_collision_shape()
	_setup_sprite_scale()
	_setup_combat()
	_connect_signals()
	_start_wander_timer()
	# Dark Lord starts in Corrupted World
	set_world_collision(Enums.WorldType.CORRUPTED)
	# Initialize fog around spawn position
	_check_fog_update()


func _connect_signals() -> void:
	EventBus.dark_lord_move_ordered.connect(_on_move_ordered)


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
	var speed := Data.MOVE_SPEED if _is_player_commanded else Data.WANDER_SPEED
	velocity = direction * speed

	# Check if reached target
	var arrival_distance := speed * get_physics_process_delta_time()
	if global_position.distance_to(_target_position) < arrival_distance:
		global_position = _target_position
		velocity = Vector2.ZERO
		_is_moving = false
		_is_player_commanded = false
		_start_wander_timer()
	else:
		# Flip sprite based on movement direction
		if velocity.x != 0:
			sprite.flip_h = velocity.x < 0
		move_and_slide()

	# Update fog when crossing tile boundaries (reveals as we move)
	_check_fog_update()


func _on_move_ordered(target_pos: Vector2) -> void:
	## Player clicked to move Dark Lord to target position
	wander_timer.stop()
	_target_position = target_pos
	_is_moving = true
	_is_player_commanded = true


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
	# Get the world node
	var world_node := get_tree().current_scene
	if not world_node.has_method("get_entities_container"):
		return

	# Get current tile position
	var tile_size := GameConstants.TILE_SIZE
	var current_tile := Vector2i(global_position / tile_size)

	# Get current world the Dark Lord is in
	var current_world: Enums.WorldType
	if get_parent() == world_node.get_entities_container(Enums.WorldType.CORRUPTED):
		current_world = Enums.WorldType.CORRUPTED
	else:
		current_world = Enums.WorldType.HUMAN

	# Must place on corrupted land
	if world_node.has_method("is_tile_corrupted"):
		if not world_node.is_tile_corrupted(current_tile, current_world):
			return

	# Check if can afford
	if not Essence.can_afford(PortalData.PLACEMENT_COST):
		return

	# Check if portal already exists at this position in either world
	if WorldManager.has_portal_at(current_tile, Enums.WorldType.CORRUPTED) or WorldManager.has_portal_at(current_tile, Enums.WorldType.HUMAN):
		return

	# Spend essence
	Essence.spend(PortalData.PLACEMENT_COST)

	# Create portal in current world
	var portal := PortalScene.instantiate()
	world_node.get_entities_container(current_world).add_child(portal)
	portal.setup(current_tile, current_world)

	# Auto-create linked portal in the other world
	var other_world: Enums.WorldType
	if current_world == Enums.WorldType.CORRUPTED:
		other_world = Enums.WorldType.HUMAN
	else:
		other_world = Enums.WorldType.CORRUPTED

	var other_portal := PortalScene.instantiate()
	world_node.get_entities_container(other_world).add_child(other_portal)
	other_portal.setup(current_tile, other_world)

	# Create initial corruption around the Human World portal
	if world_node.has_method("corrupt_area_around"):
		world_node.corrupt_area_around(current_tile, Enums.WorldType.HUMAN, GameConstants.PORTAL_INITIAL_CORRUPTION_RANGE)


#region Fog of War

func get_visible_tiles() -> Array[Vector2i]:
	## Returns array of tiles visible from Dark Lord's position
	var center := Vector2i(global_position / GameConstants.TILE_SIZE)
	return FogUtils.get_tiles_in_sight_range(center, Data.SIGHT_RANGE)


func _check_fog_update() -> void:
	## Update fog when crossing tile boundaries (reveals as we move)
	var current_tile := Vector2i(global_position / GameConstants.TILE_SIZE)
	if current_tile != _last_tile_pos:
		_last_tile_pos = current_tile
		EventBus.fog_update_requested.emit(WorldManager.active_world)

#endregion

#region Combat

func _setup_combat() -> void:
	# Configure attack range from constants
	var attack_shape := attack_range.get_node("CollisionShape2D") as CollisionShape2D
	if attack_shape:
		var circle := CircleShape2D.new()
		circle.radius = GameConstants.DARK_LORD_ATTACK_RANGE
		attack_shape.shape = circle

	attack_timer.wait_time = GameConstants.DARK_LORD_ATTACK_COOLDOWN
	attack_timer.one_shot = true
	attack_range.body_entered.connect(_on_attack_range_body_entered)
	attack_range.body_exited.connect(_on_attack_range_body_exited)


func _on_attack_range_body_entered(body: Node2D) -> void:
	if body.is_in_group(GameConstants.GROUP_KILLABLE):
		_targets_in_range.append(body)
		if _current_target == null:
			_current_target = body
			_try_attack()


func _on_attack_range_body_exited(body: Node2D) -> void:
	_targets_in_range.erase(body)
	if body == _current_target:
		_current_target = _targets_in_range[0] if _targets_in_range.size() > 0 else null


func _try_attack() -> void:
	if _current_target == null or not attack_timer.is_stopped():
		return
	if not is_instance_valid(_current_target):
		_current_target = null
		return

	# Deal damage to target
	if _current_target.has_method("take_damage"):
		_current_target.take_damage(GameConstants.DARK_LORD_DAMAGE)
	attack_timer.start()


func _on_attack_timer_timeout() -> void:
	# Attack again if target still in range
	if _current_target != null and not is_instance_valid(_current_target):
		_current_target = _targets_in_range[0] if _targets_in_range.size() > 0 else null
	_try_attack()


func take_damage(amount: int) -> void:
	_hp -= amount
	if _hp <= 0:
		_die()


func _die() -> void:
	EventBus.game_lost.emit()
	# Don't queue_free - let the game over screen handle cleanup


func get_hp() -> int:
	return _hp


func get_max_hp() -> int:
	return GameConstants.DARK_LORD_HP

#endregion


#region World Collision

func set_world_collision(target_world: Enums.WorldType) -> void:
	## Set collision layer/mask based on which world this entity is in
	## Called when spawned and when transferring between worlds
	var world_layer: int
	match target_world:
		Enums.WorldType.CORRUPTED:
			world_layer = 1 << (GameConstants.COLLISION_LAYER_CORRUPTED_WORLD - 1)
		Enums.WorldType.HUMAN:
			world_layer = 1 << (GameConstants.COLLISION_LAYER_HUMAN_WORLD - 1)

	# Layer: world layer + layer 2 for threat detection (flee behavior)
	# Mask: only layer 1 (walls) - friendly units don't block each other
	collision_layer = world_layer | 2
	collision_mask = 1

	# Update AttackRange to detect entities in the current world
	attack_range.collision_mask = world_layer

#endregion

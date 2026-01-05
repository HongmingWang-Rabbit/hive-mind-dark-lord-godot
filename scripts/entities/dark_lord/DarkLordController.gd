extends CharacterBody2D
## Hive Mind Dark Lord - the player's avatar that wanders corrupted territory
## Spawns at initial corruption point. Can place portals to travel between worlds.

const Data := preload("res://scripts/entities/dark_lord/DarkLordData.gd")
const PortalData := preload("res://scripts/entities/buildings/PortalData.gd")
const PortalScene := preload("res://scenes/entities/buildings/portal.tscn")
const FogUtils := preload("res://scripts/utils/fog_utils.gd")
const HealthComponent := preload("res://scripts/components/HealthComponent.gd")

enum State { IDLE, WANDER, MOVE_TO, CHASE, ATTACK }

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var wander_timer: Timer = $WanderTimer
@onready var attack_timer: Timer = $AttackTimer
@onready var attack_range: Area2D = $AttackRange

# State machine
var _state := State.IDLE
var _target_position: Vector2

# Fog tracking - update fog when crossing tile boundaries
var _last_tile_pos: Vector2i = Data.INVALID_TILE_POS

# Combat - detection (larger range for chasing)
var _detected_enemies: Array[Node2D] = []
var _chase_target: Node2D = null

# Combat - attack (smaller range for attacking)
var _attack_target: Node2D = null
var _targets_in_attack_range: Array[Node2D] = []

# Detection area (created dynamically)
var _detection_area: Area2D

# Components
var _health: Node2D


func _ready() -> void:
	add_to_group(GameConstants.GROUP_DARK_LORD)
	add_to_group(GameConstants.GROUP_THREATS)
	_setup_collision_shape()
	_setup_sprite_scale()
	_setup_detection()
	_setup_combat()
	_setup_health_component()
	_connect_signals()
	_state = State.IDLE
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


func _setup_health_component() -> void:
	_health = HealthComponent.new()
	add_child(_health)
	_health.setup(GameConstants.DARK_LORD_HP)
	_health.died.connect(_die)


func _physics_process(_delta: float) -> void:
	match _state:
		State.IDLE:
			_process_idle()
		State.WANDER:
			_process_wander()
		State.MOVE_TO:
			_process_move_to()
		State.CHASE:
			_process_chase()
		State.ATTACK:
			_process_attack()


func _process_idle() -> void:
	velocity = Vector2.ZERO

	if _try_switch_to_attack():
		return

	# Check for enemies to chase
	if _try_switch_to_chase():
		return


func _process_wander() -> void:
	if _try_switch_to_attack():
		return

	if _try_switch_to_chase():
		return

	var distance := global_position.distance_to(_target_position)
	var arrival_distance := Data.WANDER_SPEED * get_physics_process_delta_time()

	if distance < arrival_distance:
		global_position = _target_position
		velocity = Vector2.ZERO
		_state = State.IDLE
		_start_wander_timer()
	else:
		var direction := (_target_position - global_position).normalized()
		velocity = direction * Data.WANDER_SPEED
		if velocity.x != 0:
			sprite.flip_h = velocity.x < 0
		move_and_slide()

	_check_fog_update()


func _process_move_to() -> void:
	# Player-commanded movement - don't interrupt for enemies
	var distance := global_position.distance_to(_target_position)
	var arrival_distance := Data.MOVE_SPEED * get_physics_process_delta_time()

	if distance < arrival_distance:
		global_position = _target_position
		velocity = Vector2.ZERO
		# Check for attack targets at destination
		if _targets_in_attack_range.size() > 0:
			_update_attack_target()
			if _attack_target != null:
				_state = State.ATTACK
				_try_attack()
				return
		_state = State.IDLE
		_start_wander_timer()
	else:
		var direction := (_target_position - global_position).normalized()
		velocity = direction * Data.MOVE_SPEED
		if velocity.x != 0:
			sprite.flip_h = velocity.x < 0
		move_and_slide()

	_check_fog_update()


func _process_chase() -> void:
	# Validate chase target
	if _chase_target == null or not is_instance_valid(_chase_target):
		_chase_target = null
		_update_chase_target()
		if _chase_target == null:
			_state = State.IDLE
			_start_wander_timer()
			return

	# Check if target is in attack range (Area2D might have already set this)
	if _targets_in_attack_range.has(_chase_target):
		_attack_target = _chase_target
		_state = State.ATTACK
		_try_attack()
		return

	# Chase the target
	var direction := (_chase_target.global_position - global_position).normalized()
	velocity = direction * Data.CHASE_SPEED
	if velocity.x != 0:
		sprite.flip_h = velocity.x < 0
	move_and_slide()

	_check_fog_update()


func _process_attack() -> void:
	# Validate attack target
	if _attack_target == null or not is_instance_valid(_attack_target):
		_attack_target = null
		_update_attack_target()
		if _attack_target == null:
			# Try to find new chase target
			_update_chase_target()
			_state = State.CHASE if _chase_target != null else State.IDLE
			if _state == State.IDLE:
				_start_wander_timer()
			return

	# Check if target moved out of attack range
	var distance := global_position.distance_to(_attack_target.global_position)
	if distance > GameConstants.DARK_LORD_ATTACK_RANGE:
		# Chase it again
		_chase_target = _attack_target
		_state = State.CHASE
		return

	# Stay and attack
	velocity = Vector2.ZERO
	_try_attack()


func _try_switch_to_attack() -> bool:
	## Check for attack targets and switch to ATTACK state if found
	## Returns true if state changed
	if _targets_in_attack_range.size() > 0:
		_update_attack_target()
		if _attack_target != null:
			wander_timer.stop()
			_state = State.ATTACK
			_try_attack()
			return true
	return false


func _try_switch_to_chase() -> bool:
	## Check for enemies to chase and switch to CHASE state if found
	## Returns true if state changed
	if _detected_enemies.size() > 0:
		_update_chase_target()
		if _chase_target != null:
			wander_timer.stop()
			_state = State.CHASE
			return true
	return false


func _on_move_ordered(target_pos: Vector2) -> void:
	## Player clicked to move Dark Lord to target position
	wander_timer.stop()
	_target_position = target_pos
	_state = State.MOVE_TO


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
	if _state == State.IDLE:
		_pick_new_wander_target()
		_state = State.WANDER


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

#region Detection (larger range for chasing)

func _setup_detection() -> void:
	# Create detection area dynamically
	_detection_area = Area2D.new()
	_detection_area.name = "DetectionArea"
	_detection_area.monitoring = true
	_detection_area.monitorable = false
	add_child(_detection_area)

	var detect_shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = Data.DETECTION_RADIUS
	detect_shape.shape = circle
	_detection_area.add_child(detect_shape)

	_detection_area.body_entered.connect(_on_detection_area_body_entered)
	_detection_area.body_exited.connect(_on_detection_area_body_exited)


func _on_detection_area_body_entered(body: Node2D) -> void:
	# Detect enemies (military, police, etc.)
	if body.is_in_group(GameConstants.GROUP_ENEMIES):
		_detected_enemies.append(body)
		# If idle or wandering, start chasing
		if _state == State.IDLE or _state == State.WANDER:
			_update_chase_target()
			if _chase_target != null:
				wander_timer.stop()
				_state = State.CHASE


func _on_detection_area_body_exited(body: Node2D) -> void:
	_detected_enemies.erase(body)
	if body == _chase_target:
		_update_chase_target()


func _update_chase_target() -> void:
	_chase_target = null
	var closest_distance := INF

	_detected_enemies = _detected_enemies.filter(func(e): return is_instance_valid(e))

	for enemy in _detected_enemies:
		var dist := global_position.distance_to(enemy.global_position)
		if dist < closest_distance:
			closest_distance = dist
			_chase_target = enemy

#endregion

#region Combat (attack range)

func _setup_combat() -> void:
	# Configure attack range from constants
	var attack_shape := attack_range.get_node("CollisionShape2D") as CollisionShape2D
	if attack_shape:
		var circle := CircleShape2D.new()
		circle.radius = GameConstants.DARK_LORD_ATTACK_RANGE
		attack_shape.shape = circle

	# Ensure monitoring is enabled
	attack_range.monitoring = true
	attack_range.monitorable = false  # We don't need others to detect this area

	attack_timer.wait_time = GameConstants.DARK_LORD_ATTACK_COOLDOWN
	attack_timer.one_shot = true
	attack_range.body_entered.connect(_on_attack_range_body_entered)
	attack_range.body_exited.connect(_on_attack_range_body_exited)


func _on_attack_range_body_entered(body: Node2D) -> void:
	# Target killable entities (civilians, animals) AND enemies (military, police)
	if body.is_in_group(GameConstants.GROUP_KILLABLE) or body.is_in_group(GameConstants.GROUP_ENEMIES):
		if not _targets_in_attack_range.has(body):
			_targets_in_attack_range.append(body)
		# Switch to attack if not doing player command
		if _state != State.MOVE_TO and _state != State.ATTACK:
			_attack_target = body
			_state = State.ATTACK
			_try_attack()
		elif _state == State.ATTACK and _attack_target == null:
			_attack_target = body
			_try_attack()


func _on_attack_range_body_exited(body: Node2D) -> void:
	_targets_in_attack_range.erase(body)
	if body == _attack_target:
		_update_attack_target()


func _update_attack_target() -> void:
	_attack_target = null
	var closest_distance := INF

	_targets_in_attack_range = _targets_in_attack_range.filter(func(t): return is_instance_valid(t))

	for target in _targets_in_attack_range:
		var dist := global_position.distance_to(target.global_position)
		if dist < closest_distance:
			closest_distance = dist
			_attack_target = target


func _try_attack() -> void:
	if _attack_target == null or not attack_timer.is_stopped():
		return
	if not is_instance_valid(_attack_target):
		_attack_target = null
		return

	# Deal damage to target
	if _attack_target.has_method("take_damage"):
		_attack_target.take_damage(GameConstants.DARK_LORD_DAMAGE)
	attack_timer.start()


func _on_attack_timer_timeout() -> void:
	# Attack again if target still in range
	if _attack_target != null and not is_instance_valid(_attack_target):
		_update_attack_target()
	_try_attack()


func take_damage(amount: int) -> void:
	_health.take_damage(amount)


func _die() -> void:
	EventBus.game_lost.emit()
	# Don't queue_free - let the game over screen handle cleanup


func get_hp() -> int:
	return _health.get_hp() if _health else 0


func get_max_hp() -> int:
	return _health.get_max_hp() if _health else GameConstants.DARK_LORD_HP

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

	# Layer: world layer + threat layer for flee behavior detection
	# Mask: walls only - friendly units don't block each other
	collision_layer = world_layer | GameConstants.COLLISION_MASK_THREATS
	collision_mask = GameConstants.COLLISION_MASK_WALLS

	# Update AttackRange to detect entities in the current world
	attack_range.collision_mask = world_layer

	# Update DetectionArea to detect enemies in the current world
	if _detection_area:
		_detection_area.collision_mask = world_layer

#endregion

extends CharacterBody2D
## Minion entity - follows Dark Lord, attacks enemies
## Spawned via hotkeys, adds to HivePool

const Data := preload("res://scripts/entities/minions/MinionData.gd")

enum State { FOLLOW, ATTACK, WANDER, MOVE_TO }

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var attack_range: Area2D = $AttackRange
@onready var attack_timer: Timer = $AttackTimer

# Configuration
var minion_type: Enums.MinionType = Enums.MinionType.CRAWLER

# State
var _hp: int
var _state := State.FOLLOW
var _current_target: Node2D = null
var _targets_in_range: Array[Node2D] = []
var _wander_offset := Vector2.ZERO
var _order_target := Vector2.ZERO  # Target position for MOVE_TO state
var _order_stance := Enums.Stance.AGGRESSIVE  # How to behave when reaching target

# Cached separation (performance optimization)
var _cached_separation := Vector2.ZERO
var _separation_timer := 0.0


func _ready() -> void:
	add_to_group(GameConstants.GROUP_MINIONS)
	add_to_group(GameConstants.GROUP_THREATS)
	_setup_collision_shape()
	_setup_sprite_scale()
	_setup_combat()
	_connect_signals()


func _connect_signals() -> void:
	EventBus.attack_ordered.connect(_on_attack_ordered)
	EventBus.retreat_ordered.connect(_on_retreat_ordered)


func setup(type: Enums.MinionType) -> void:
	## Call after instantiation to configure minion type
	minion_type = type
	var stats: Dictionary = GameConstants.MINION_STATS.get(type, {})
	_hp = stats.get("hp", Data.DEFAULT_HP)


func _setup_collision_shape() -> void:
	var shape := CircleShape2D.new()
	shape.radius = Data.COLLISION_RADIUS
	collision_shape.shape = shape


func _setup_sprite_scale() -> void:
	if sprite.texture == null:
		return
	var texture_size := sprite.texture.get_size()
	var desired_diameter := Data.COLLISION_RADIUS * 2.0 * Data.SPRITE_SIZE_RATIO
	var max_dimension := maxf(texture_size.x, texture_size.y)
	var scale_factor := desired_diameter / max_dimension
	sprite.scale = Vector2(scale_factor, scale_factor)


func _setup_combat() -> void:
	# Configure attack range
	var attack_shape := attack_range.get_node("CollisionShape2D") as CollisionShape2D
	if attack_shape:
		var circle := CircleShape2D.new()
		circle.radius = Data.ATTACK_RANGE
		attack_shape.shape = circle

	attack_timer.wait_time = Data.ATTACK_COOLDOWN
	attack_timer.one_shot = true

	# Connect signals
	attack_range.body_entered.connect(_on_attack_range_body_entered)
	attack_range.body_exited.connect(_on_attack_range_body_exited)


func _physics_process(delta: float) -> void:
	# Update spatial grid position for efficient neighbor queries
	SpatialGrid.update_entity(self)

	# Update cached separation force periodically (not every frame)
	_separation_timer -= delta
	if _separation_timer <= 0.0:
		_separation_timer = Data.SEPARATION_UPDATE_INTERVAL
		_cached_separation = _calculate_separation_force()

	match _state:
		State.FOLLOW:
			_process_follow()
		State.ATTACK:
			_process_attack()
		State.WANDER:
			_process_wander()
		State.MOVE_TO:
			_process_move_to()


func _process_follow() -> void:
	var dark_lord := _get_dark_lord()
	if dark_lord == null:
		_state = State.WANDER
		return

	var distance := global_position.distance_to(dark_lord.global_position)
	var stats: Dictionary = GameConstants.MINION_STATS.get(minion_type, {})
	var speed: float = stats.get("speed", Data.DEFAULT_SPEED)

	if distance > Data.FOLLOW_DISTANCE:
		# Move toward Dark Lord with separation from other minions
		var direction := (dark_lord.global_position - global_position).normalized()
		velocity = (direction + _cached_separation).normalized() * speed

		if velocity.x != 0:
			sprite.flip_h = velocity.x < 0

		move_and_slide()
	else:
		# Close enough, wander nearby
		velocity = Vector2.ZERO
		_state = State.WANDER
		_pick_wander_offset()


func _process_wander() -> void:
	var dark_lord := _get_dark_lord()
	if dark_lord == null:
		return

	var target := dark_lord.global_position + _wander_offset
	var distance := global_position.distance_to(target)
	var stats: Dictionary = GameConstants.MINION_STATS.get(minion_type, {})
	var speed: float = stats.get("speed", Data.DEFAULT_SPEED) * Data.WANDER_SPEED_FACTOR

	# Check if Dark Lord moved too far
	var lord_distance := global_position.distance_to(dark_lord.global_position)
	if lord_distance > Data.FOLLOW_DISTANCE * Data.FOLLOW_DISTANCE_THRESHOLD:
		_state = State.FOLLOW
		return

	# Apply separation even when wandering to maintain squad spacing
	if distance > Data.WANDER_ARRIVAL_DISTANCE or _cached_separation.length() > Data.SEPARATION_MOVE_THRESHOLD:
		var direction := Vector2.ZERO
		if distance > Data.WANDER_ARRIVAL_DISTANCE:
			direction = (target - global_position).normalized()
		velocity = (direction + _cached_separation).normalized() * speed

		if velocity.x != 0:
			sprite.flip_h = velocity.x < 0

		move_and_slide()
	else:
		velocity = Vector2.ZERO
		# Pick new wander point occasionally
		if randi_range(0, Data.WANDER_DIRECTION_CHANGE_CHANCE - 1) == 0:
			_pick_wander_offset()


func _process_attack() -> void:
	if _current_target == null or not is_instance_valid(_current_target):
		_current_target = null
		_update_attack_target()
		if _current_target == null:
			_state = State.FOLLOW
			return

	# Move toward target if not in range
	var distance := global_position.distance_to(_current_target.global_position)
	var stats: Dictionary = GameConstants.MINION_STATS.get(minion_type, {})
	var speed: float = stats.get("speed", Data.DEFAULT_SPEED)

	if distance > Data.ATTACK_RANGE * Data.ATTACK_RANGE_FACTOR:
		var direction := (_current_target.global_position - global_position).normalized()
		velocity = direction * speed

		if velocity.x != 0:
			sprite.flip_h = velocity.x < 0

		move_and_slide()
	else:
		velocity = Vector2.ZERO
		_try_attack()


func _process_move_to() -> void:
	## Move toward order target position
	var distance := global_position.distance_to(_order_target)
	var stats: Dictionary = GameConstants.MINION_STATS.get(minion_type, {})
	var speed: float = stats.get("speed", Data.DEFAULT_SPEED)

	# Check for enemies in range while moving (aggressive stance)
	if _order_stance == Enums.Stance.AGGRESSIVE and _targets_in_range.size() > 0:
		_update_attack_target()
		if _current_target != null:
			_state = State.ATTACK
			return

	# Arrived at target
	if distance < Data.ORDER_ARRIVAL_DISTANCE:
		velocity = Vector2.ZERO
		# After arriving, stay aggressive or follow based on stance
		match _order_stance:
			Enums.Stance.AGGRESSIVE:
				# Stay here and attack anything that comes in range
				_state = State.WANDER
				_wander_offset = Vector2.ZERO
			Enums.Stance.HOLD:
				# Stay at position
				_state = State.WANDER
				_wander_offset = Vector2.ZERO
			Enums.Stance.RETREAT:
				# Return to Dark Lord
				_state = State.FOLLOW
		return

	# Move toward target with separation from other minions
	var direction := (_order_target - global_position).normalized()
	velocity = (direction + _cached_separation).normalized() * speed

	if velocity.x != 0:
		sprite.flip_h = velocity.x < 0

	move_and_slide()


func _pick_wander_offset() -> void:
	var angle := randf() * TAU
	var radius := randf_range(0, Data.WANDER_RADIUS)
	_wander_offset = Vector2(cos(angle), sin(angle)) * radius


func _get_dark_lord() -> Node2D:
	var lords := get_tree().get_nodes_in_group(GameConstants.GROUP_DARK_LORD)
	if lords.size() > 0:
		return lords[0] as Node2D
	return null


func _calculate_separation_force() -> Vector2:
	## Calculate force to push away from nearby minions (squad formation)
	## Uses SpatialGrid for efficient neighbor lookup instead of checking all minions
	var separation := Vector2.ZERO
	var nearby_count := 0

	# Query spatial grid for nearby entities (much faster than checking all minions)
	var nearby := SpatialGrid.get_nearby_entities(global_position, Data.SEPARATION_DISTANCE)
	for entity in nearby:
		if entity == self or not entity.is_in_group(GameConstants.GROUP_MINIONS):
			continue

		var entity_pos: Vector2 = entity.global_position
		var distance := global_position.distance_to(entity_pos)
		if distance < Data.SEPARATION_DISTANCE and distance > Data.SEPARATION_MIN_CHECK_DISTANCE:
			# Push away from nearby minion, stronger when closer
			var away := (global_position - entity_pos).normalized()
			var strength := 1.0 - (distance / Data.SEPARATION_DISTANCE)
			separation += away * strength
			nearby_count += 1

	if nearby_count > 0:
		separation = separation.normalized() * Data.SEPARATION_STRENGTH

	return separation


func _update_attack_target() -> void:
	_current_target = null
	var closest_distance := INF

	_targets_in_range = _targets_in_range.filter(func(t): return is_instance_valid(t))

	for target in _targets_in_range:
		var dist := global_position.distance_to(target.global_position)
		if dist < closest_distance:
			closest_distance = dist
			_current_target = target


func _try_attack() -> void:
	if _current_target == null or not attack_timer.is_stopped():
		return
	if not is_instance_valid(_current_target):
		_current_target = null
		return

	var stats: Dictionary = GameConstants.MINION_STATS.get(minion_type, {})
	var damage: int = stats.get("damage", Data.DEFAULT_DAMAGE)

	if _current_target.has_method("take_damage"):
		_current_target.take_damage(damage)
	attack_timer.start()


func _on_attack_timer_timeout() -> void:
	if _state == State.ATTACK:
		_try_attack()


#region Combat Detection

func _on_attack_range_body_entered(body: Node2D) -> void:
	if body.is_in_group(GameConstants.GROUP_KILLABLE):
		_targets_in_range.append(body)
		if _state != State.ATTACK:
			_current_target = body
			_state = State.ATTACK


func _on_attack_range_body_exited(body: Node2D) -> void:
	_targets_in_range.erase(body)
	if body == _current_target:
		_update_attack_target()

#endregion


#region Combat

func take_damage(amount: int) -> void:
	_hp -= amount
	if _hp <= 0:
		_die()


func _die() -> void:
	SpatialGrid.remove_entity(self)
	HivePool.on_minion_killed(minion_type)
	queue_free()

#endregion


#region Orders

func _on_attack_ordered(target_pos: Vector2, _percent: float, stance: Enums.Stance) -> void:
	## Called when attack order is issued - move to target position
	_order_target = target_pos
	_order_stance = stance
	_state = State.MOVE_TO


func _on_retreat_ordered() -> void:
	## Called when retreat order is issued - return to following Dark Lord
	_current_target = null
	_state = State.FOLLOW


func retreat() -> void:
	## Public method for retreat (called by World.gd)
	_on_retreat_ordered()

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

#endregion

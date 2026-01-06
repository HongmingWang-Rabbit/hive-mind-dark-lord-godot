extends CharacterBody2D
## Policeman entity - human world law enforcement
## Randomly chooses to fight or flee when detecting threats (Dark Lord, minions)
## Can trigger alarm towers like civilians when fleeing

const Data := preload("res://scripts/entities/humans/PolicemanData.gd")
const HealthComponent := preload("res://scripts/components/HealthComponent.gd")

enum State { WANDER, FLEE, FLEE_TO_ALARM, CHASE, ATTACK }

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var wander_timer: Timer = $WanderTimer
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_range: Area2D = $AttackRange
@onready var attack_timer: Timer = $AttackTimer

# State
var _state := State.WANDER
var _target_position: Vector2
var _is_moving := false
var _flee_target: Node2D = null  # Threat we're fleeing from
var _alarm_target: Node2D = null  # Alarm tower we're fleeing toward
var _chase_target: Node2D = null  # Threat we're chasing
var _attack_target: Node2D = null  # Target in attack range
var _threats_nearby: Array[Node2D] = []
var _threats_in_attack_range: Array[Node2D] = []
var _chose_to_fight := false  # Decision made when first detecting threat

# Components
var _health: Node2D


func _ready() -> void:
	add_to_group(GameConstants.GROUP_POLICEMEN)
	add_to_group(GameConstants.GROUP_KILLABLE)
	_setup_sprite()
	_setup_collision_shape()
	_setup_detection_area()
	_setup_combat()
	_setup_health_component()
	_start_wander_timer()
	# Policemen spawn in Human World
	set_world_collision(Enums.WorldType.HUMAN)


func _setup_sprite() -> void:
	sprite.texture = load(Data.SPRITE_PATH)
	if sprite.texture:
		var texture_size := sprite.texture.get_size()
		var desired_diameter := Data.COLLISION_RADIUS * 2.0 * Data.SPRITE_SIZE_RATIO
		var max_dimension := maxf(texture_size.x, texture_size.y)
		var scale_factor := desired_diameter / max_dimension
		sprite.scale = Vector2(scale_factor, scale_factor)


func _setup_collision_shape() -> void:
	var shape := CircleShape2D.new()
	shape.radius = Data.COLLISION_RADIUS
	collision_shape.shape = shape


func _setup_detection_area() -> void:
	var detect_shape := detection_area.get_node("CollisionShape2D") as CollisionShape2D
	if detect_shape:
		var circle := CircleShape2D.new()
		circle.radius = Data.FLEE_DETECTION_RADIUS
		detect_shape.shape = circle

	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)


func _setup_combat() -> void:
	var attack_shape := attack_range.get_node("CollisionShape2D") as CollisionShape2D
	if attack_shape:
		var circle := CircleShape2D.new()
		circle.radius = Data.ATTACK_RANGE
		attack_shape.shape = circle

	attack_timer.wait_time = Data.ATTACK_COOLDOWN
	attack_timer.one_shot = true

	attack_range.body_entered.connect(_on_attack_range_body_entered)
	attack_range.body_exited.connect(_on_attack_range_body_exited)


func _setup_health_component() -> void:
	_health = HealthComponent.new()
	add_child(_health)
	_health.setup(GameConstants.HUMAN_ENTITY_STATS[Enums.HumanType.POLICEMAN].hp)
	_health.died.connect(_die)


func _physics_process(_delta: float) -> void:
	match _state:
		State.WANDER:
			if _is_moving:
				_move_toward_target()
		State.FLEE:
			_process_flee()
		State.FLEE_TO_ALARM:
			_process_flee_to_alarm()
		State.CHASE:
			_process_chase()
		State.ATTACK:
			_process_attack()


func _move_toward_target() -> void:
	var direction := (_target_position - global_position).normalized()
	velocity = direction * Data.WANDER_SPEED

	if global_position.distance_to(_target_position) < Data.WANDER_SPEED * get_physics_process_delta_time():
		global_position = _target_position
		velocity = Vector2.ZERO
		_is_moving = false
		_start_wander_timer()
	else:
		if velocity.x != 0:
			sprite.flip_h = velocity.x < 0
		move_and_slide()


func _process_flee() -> void:
	if not is_instance_valid(_flee_target):
		_update_flee_target()
		if _flee_target == null:
			_return_to_wander()
			return

	var distance := global_position.distance_to(_flee_target.global_position)
	if distance >= Data.FLEE_SAFE_DISTANCE:
		if _threats_nearby.size() == 0:
			_return_to_wander()
			return
		_update_flee_target()

	if _flee_target != null:
		var flee_direction := (global_position - _flee_target.global_position).normalized()
		velocity = flee_direction * Data.FLEE_SPEED

		if velocity.x != 0:
			sprite.flip_h = velocity.x < 0

		move_and_slide()


func _process_flee_to_alarm() -> void:
	if _alarm_target == null or not is_instance_valid(_alarm_target):
		_alarm_target = null
		_find_alarm_tower()
		if _alarm_target == null:
			_state = State.FLEE
			return

	if _alarm_target.has_method("is_on_cooldown") and _alarm_target.is_on_cooldown():
		_alarm_target = null
		_find_alarm_tower()
		if _alarm_target == null:
			_state = State.FLEE
			return

	var distance := global_position.distance_to(_alarm_target.global_position)

	if distance <= Data.ALARM_TOWER_ARRIVAL_DISTANCE:
		velocity = Vector2.ZERO
	else:
		var direction := (_alarm_target.global_position - global_position).normalized()
		velocity = direction * Data.FLEE_SPEED

		if velocity.x != 0:
			sprite.flip_h = velocity.x < 0

		move_and_slide()

	if _threats_nearby.size() == 0:
		_return_to_wander()


func _process_chase() -> void:
	if _chase_target == null or not is_instance_valid(_chase_target):
		_update_chase_target()
		if _chase_target == null:
			_return_to_wander()
			return

	# Check if target entered attack range
	if _threats_in_attack_range.has(_chase_target):
		_attack_target = _chase_target
		_state = State.ATTACK
		_try_attack()
		return

	var direction := (_chase_target.global_position - global_position).normalized()
	velocity = direction * Data.CHASE_SPEED

	if velocity.x != 0:
		sprite.flip_h = velocity.x < 0

	move_and_slide()


func _process_attack() -> void:
	if _attack_target == null or not is_instance_valid(_attack_target):
		_update_attack_target()
		if _attack_target == null:
			_update_chase_target()
			_state = State.CHASE if _chase_target != null else State.WANDER
			if _state == State.WANDER:
				_start_wander_timer()
			return

	var distance := global_position.distance_to(_attack_target.global_position)
	if distance > Data.ATTACK_RANGE:
		_chase_target = _attack_target
		_state = State.CHASE
		return

	velocity = Vector2.ZERO
	_try_attack()


func _update_flee_target() -> void:
	_flee_target = null
	var closest_distance := INF

	_threats_nearby = _threats_nearby.filter(func(t): return is_instance_valid(t))

	for threat in _threats_nearby:
		var dist := global_position.distance_to(threat.global_position)
		if dist < closest_distance:
			closest_distance = dist
			_flee_target = threat


func _update_chase_target() -> void:
	_chase_target = null
	var closest_distance := INF

	_threats_nearby = _threats_nearby.filter(func(t): return is_instance_valid(t))

	for threat in _threats_nearby:
		var dist := global_position.distance_to(threat.global_position)
		if dist < closest_distance:
			closest_distance = dist
			_chase_target = threat


func _update_attack_target() -> void:
	_attack_target = null
	var closest_distance := INF

	_threats_in_attack_range = _threats_in_attack_range.filter(func(t): return is_instance_valid(t))

	for threat in _threats_in_attack_range:
		var dist := global_position.distance_to(threat.global_position)
		if dist < closest_distance:
			closest_distance = dist
			_attack_target = threat


func _return_to_wander() -> void:
	_state = State.WANDER
	_flee_target = null
	_alarm_target = null
	_chase_target = null
	_chose_to_fight = false  # Reset decision for next encounter
	velocity = Vector2.ZERO
	_is_moving = false
	_start_wander_timer()


func _decide_fight_or_flight() -> bool:
	## Randomly decide whether to fight or flee
	return randi_range(0, 99) < Data.FIGHT_CHANCE


func _start_response(threat: Node2D) -> void:
	## Called when first detecting a threat - decide to fight or flee
	wander_timer.stop()
	_chose_to_fight = _decide_fight_or_flight()

	if _chose_to_fight:
		_chase_target = threat
		_state = State.CHASE
	else:
		_flee_target = threat
		_find_alarm_tower()
		if _alarm_target != null:
			_state = State.FLEE_TO_ALARM
		else:
			_state = State.FLEE


func _find_alarm_tower() -> void:
	_alarm_target = null
	var closest_distance := Data.ALARM_TOWER_SEARCH_RADIUS
	var alarm_towers := get_tree().get_nodes_in_group(GameConstants.GROUP_ALARM_TOWERS)

	for tower in alarm_towers:
		if not is_instance_valid(tower):
			continue
		if tower.has_method("is_on_cooldown") and tower.is_on_cooldown():
			continue

		var dist := global_position.distance_to(tower.global_position)
		if dist < closest_distance:
			closest_distance = dist
			_alarm_target = tower


func _try_attack() -> void:
	if _attack_target == null or not attack_timer.is_stopped():
		return
	if not is_instance_valid(_attack_target):
		_attack_target = null
		return

	if _attack_target.has_method("take_damage"):
		_attack_target.take_damage(GameConstants.HUMAN_ENTITY_STATS[Enums.HumanType.POLICEMAN].damage)
	attack_timer.start()


func _on_attack_timer_timeout() -> void:
	if _state == State.ATTACK:
		_try_attack()


func _pick_new_wander_target() -> void:
	var tile_size := GameConstants.TILE_SIZE
	var directions := GameConstants.ALL_DIRS

	var random_index := randi_range(0, directions.size() - 1)
	var random_dir: Vector2i = directions[random_index]
	_target_position = global_position + Vector2(random_dir) * tile_size


func _start_wander_timer() -> void:
	var interval := randf_range(Data.WANDER_INTERVAL_MIN, Data.WANDER_INTERVAL_MAX)
	wander_timer.start(interval)


func _on_wander_timer_timeout() -> void:
	if _state == State.WANDER:
		_pick_new_wander_target()
		_is_moving = true


#region Detection

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group(GameConstants.GROUP_THREATS):
		_threats_nearby.append(body)
		# First threat detected - make fight/flight decision
		if _state == State.WANDER:
			_start_response(body)
		elif _state == State.CHASE and _chase_target == null:
			_update_chase_target()
		elif _state == State.FLEE and _flee_target == null:
			_update_flee_target()


func _on_detection_area_body_exited(body: Node2D) -> void:
	_threats_nearby.erase(body)
	if body == _chase_target:
		_update_chase_target()
	if body == _flee_target:
		_update_flee_target()


func _on_attack_range_body_entered(body: Node2D) -> void:
	if body.is_in_group(GameConstants.GROUP_THREATS):
		if not _threats_in_attack_range.has(body):
			_threats_in_attack_range.append(body)
		# Switch to attack if we're fighting and target entered range
		if _chose_to_fight and _state == State.CHASE:
			_attack_target = body
			_state = State.ATTACK
			_try_attack()


func _on_attack_range_body_exited(body: Node2D) -> void:
	_threats_in_attack_range.erase(body)
	if body == _attack_target:
		_update_attack_target()

#endregion


#region Combat

func take_damage(amount: int) -> void:
	_health.take_damage(amount)


func _die() -> void:
	EventBus.entity_killed.emit(global_position, Enums.HumanType.POLICEMAN)
	Essence.modify(GameConstants.HUMAN_ENTITY_STATS[Enums.HumanType.POLICEMAN].essence_reward)
	queue_free()

#endregion


#region Alarm Tower Interface

func is_fleeing() -> bool:
	## Returns true if policeman is fleeing (used by alarm tower)
	return _state == State.FLEE or _state == State.FLEE_TO_ALARM


func on_alarm_triggered() -> void:
	## Called by alarm tower when this policeman triggers the alarm
	_return_to_wander()

#endregion


#region World Collision

func set_world_collision(target_world: Enums.WorldType) -> void:
	var world_layer: int
	var world_mask: int
	match target_world:
		Enums.WorldType.CORRUPTED:
			world_layer = 1 << (GameConstants.COLLISION_LAYER_CORRUPTED_WORLD - 1)
			world_mask = GameConstants.COLLISION_MASK_CORRUPTED_WORLD
		Enums.WorldType.HUMAN:
			world_layer = 1 << (GameConstants.COLLISION_LAYER_HUMAN_WORLD - 1)
			world_mask = GameConstants.COLLISION_MASK_HUMAN_WORLD

	collision_layer = world_layer
	collision_mask = world_mask

	# Detection and attack areas detect threats in current world
	detection_area.collision_mask = GameConstants.COLLISION_MASK_THREATS
	attack_range.collision_mask = GameConstants.COLLISION_MASK_THREATS

#endregion

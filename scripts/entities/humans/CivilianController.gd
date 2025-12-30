extends CharacterBody2D
## Civilian entity - wanders in Human World, provides essence when killed
## Flees from threats (Dark Lord, minions) when detected

const Data := preload("res://scripts/entities/humans/CivilianData.gd")

enum State { WANDER, FLEE }

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var wander_timer: Timer = $WanderTimer
@onready var detection_area: Area2D = $DetectionArea

# State
var _hp: int
var _state := State.WANDER
var _target_position: Vector2
var _is_moving := false
var _flee_target: Node2D = null  # The threat we're fleeing from
var _threats_nearby: Array[Node2D] = []


func _ready() -> void:
	add_to_group(GameConstants.GROUP_CIVILIANS)
	add_to_group(GameConstants.GROUP_KILLABLE)
	_hp = GameConstants.CIVILIAN_HP
	_setup_collision_shape()
	_setup_sprite_scale()
	_setup_detection_area()
	_start_wander_timer()


func _setup_collision_shape() -> void:
	var shape := CircleShape2D.new()
	shape.radius = Data.COLLISION_RADIUS
	collision_shape.shape = shape


func _setup_sprite_scale() -> void:
	var texture_size := sprite.texture.get_size()
	var desired_diameter := Data.COLLISION_RADIUS * 2.0 * Data.SPRITE_SIZE_RATIO
	var max_dimension := maxf(texture_size.x, texture_size.y)
	var scale_factor := desired_diameter / max_dimension
	sprite.scale = Vector2(scale_factor, scale_factor)


func _setup_detection_area() -> void:
	# Configure detection area collision shape
	var detect_shape := detection_area.get_node("CollisionShape2D") as CollisionShape2D
	if detect_shape:
		var circle := CircleShape2D.new()
		circle.radius = Data.FLEE_DETECTION_RADIUS
		detect_shape.shape = circle

	# Connect signals
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)


func _physics_process(_delta: float) -> void:
	match _state:
		State.WANDER:
			if _is_moving:
				_move_toward_target()
		State.FLEE:
			_process_flee()


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


func _process_flee() -> void:
	if not is_instance_valid(_flee_target):
		# Threat destroyed, find next threat or return to wander
		_update_flee_target()
		if _flee_target == null:
			_return_to_wander()
			return

	# Check if we're far enough away
	var distance := global_position.distance_to(_flee_target.global_position)
	if distance >= Data.FLEE_SAFE_DISTANCE:
		# Safe distance reached, check if threat still in detection range
		if _threats_nearby.size() == 0:
			_return_to_wander()
			return
		# Still have threats nearby, keep fleeing from closest
		_update_flee_target()

	# Flee away from threat
	if _flee_target != null:
		var flee_direction := (global_position - _flee_target.global_position).normalized()
		velocity = flee_direction * Data.FLEE_SPEED

		# Flip sprite based on movement direction
		if velocity.x != 0:
			sprite.flip_h = velocity.x < 0

		move_and_slide()


func _update_flee_target() -> void:
	## Find the closest threat to flee from
	_flee_target = null
	var closest_distance := INF

	# Clean up invalid references
	_threats_nearby = _threats_nearby.filter(func(t): return is_instance_valid(t))

	for threat in _threats_nearby:
		var dist := global_position.distance_to(threat.global_position)
		if dist < closest_distance:
			closest_distance = dist
			_flee_target = threat


func _return_to_wander() -> void:
	_state = State.WANDER
	_flee_target = null
	velocity = Vector2.ZERO
	_is_moving = false
	_start_wander_timer()


func _start_flee(threat: Node2D) -> void:
	_state = State.FLEE
	_flee_target = threat
	wander_timer.stop()  # Cancel any pending wander


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
		# Start fleeing if not already
		if _state != State.FLEE:
			_start_flee(body)
		elif _flee_target == null:
			_update_flee_target()


func _on_detection_area_body_exited(body: Node2D) -> void:
	_threats_nearby.erase(body)
	if body == _flee_target:
		_update_flee_target()

#endregion


#region Combat

func take_damage(amount: int) -> void:
	_hp -= amount
	if _hp <= 0:
		_die()


func _die() -> void:
	EventBus.entity_killed.emit(global_position, Enums.HumanType.CIVILIAN)
	Essence.modify(GameConstants.ESSENCE_PER_CIVILIAN)
	queue_free()

#endregion

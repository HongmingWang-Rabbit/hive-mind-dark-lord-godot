extends CharacterBody2D
## Minion entity - follows Dark Lord, attacks enemies
## Spawned via hotkeys, adds to HivePool

const Data := preload("res://scripts/entities/minions/MinionData.gd")

enum State { FOLLOW, ATTACK, WANDER }

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


func _ready() -> void:
	add_to_group(GameConstants.GROUP_MINIONS)
	add_to_group(GameConstants.GROUP_THREATS)
	_setup_collision_shape()
	_setup_sprite_scale()
	_setup_combat()


func setup(type: Enums.MinionType) -> void:
	## Call after instantiation to configure minion type
	minion_type = type
	var stats: Dictionary = GameConstants.MINION_STATS.get(type, {})
	_hp = stats.get("hp", 10)


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


func _physics_process(_delta: float) -> void:
	match _state:
		State.FOLLOW:
			_process_follow()
		State.ATTACK:
			_process_attack()
		State.WANDER:
			_process_wander()


func _process_follow() -> void:
	var dark_lord := _get_dark_lord()
	if dark_lord == null:
		_state = State.WANDER
		return

	var distance := global_position.distance_to(dark_lord.global_position)
	var stats: Dictionary = GameConstants.MINION_STATS.get(minion_type, {})
	var speed: float = stats.get("speed", 60.0)

	if distance > Data.FOLLOW_DISTANCE:
		# Move toward Dark Lord
		var direction := (dark_lord.global_position - global_position).normalized()
		velocity = direction * speed

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
	var speed: float = stats.get("speed", 60.0) * Data.WANDER_SPEED_FACTOR

	# Check if Dark Lord moved too far
	var lord_distance := global_position.distance_to(dark_lord.global_position)
	if lord_distance > Data.FOLLOW_DISTANCE * Data.FOLLOW_DISTANCE_THRESHOLD:
		_state = State.FOLLOW
		return

	if distance > Data.WANDER_ARRIVAL_DISTANCE:
		var direction := (target - global_position).normalized()
		velocity = direction * speed

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
	var speed: float = stats.get("speed", 60.0)

	if distance > Data.ATTACK_RANGE * Data.ATTACK_RANGE_FACTOR:
		var direction := (_current_target.global_position - global_position).normalized()
		velocity = direction * speed

		if velocity.x != 0:
			sprite.flip_h = velocity.x < 0

		move_and_slide()
	else:
		velocity = Vector2.ZERO
		_try_attack()


func _pick_wander_offset() -> void:
	var angle := randf() * TAU
	var radius := randf_range(0, Data.WANDER_RADIUS)
	_wander_offset = Vector2(cos(angle), sin(angle)) * radius


func _get_dark_lord() -> Node2D:
	var lords := get_tree().get_nodes_in_group(GameConstants.GROUP_DARK_LORD)
	if lords.size() > 0:
		return lords[0] as Node2D
	return null


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
	var damage: int = stats.get("damage", 2)

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
	HivePool.on_minion_killed(minion_type)
	queue_free()

#endregion

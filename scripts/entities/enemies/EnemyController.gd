extends CharacterBody2D
## Enemy entity - patrols Human World, attacks Dark Lord and minions
## Spawned by threat system based on corruption level

const Data := preload("res://scripts/entities/enemies/EnemyData.gd")
const HealthComponent := preload("res://scripts/components/HealthComponent.gd")

enum State { PATROL, CHASE, ATTACK, INVESTIGATE }

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_range: Area2D = $AttackRange
@onready var attack_timer: Timer = $AttackTimer
@onready var patrol_timer: Timer = $PatrolTimer

# Configuration
var enemy_type: Enums.EnemyType = Enums.EnemyType.POLICE

# State
var _damage: int
var _speed: float
var _state := State.PATROL
var _spawn_position: Vector2
var _patrol_target: Vector2
var _investigate_target: Vector2  # Position to investigate (alarm location)
var _chase_target: Node2D = null
var _attack_target: Node2D = null
var _threats_detected: Array[Node2D] = []
var _threats_in_attack_range: Array[Node2D] = []

# Components
var _health: Node2D


func _ready() -> void:
	add_to_group(GameConstants.GROUP_ENEMIES)
	add_to_group(GameConstants.GROUP_KILLABLE)
	_spawn_position = global_position
	_setup_detection()
	_setup_combat()
	_pick_patrol_target()
	# Enemies spawn in Human World
	set_world_collision(Enums.WorldType.HUMAN)


func setup(type: Enums.EnemyType) -> void:
	## Call after instantiation to configure enemy type
	enemy_type = type
	var max_hp: int
	match type:
		Enums.EnemyType.POLICE:
			max_hp = GameConstants.POLICE_HP
			_damage = GameConstants.POLICE_DAMAGE
			_speed = GameConstants.POLICE_SPEED
			add_to_group(GameConstants.GROUP_POLICE)
		Enums.EnemyType.MILITARY:
			max_hp = GameConstants.MILITARY_HP
			_damage = GameConstants.MILITARY_DAMAGE
			_speed = GameConstants.MILITARY_SPEED
			add_to_group(GameConstants.GROUP_MILITARY)
		Enums.EnemyType.HEAVY:
			max_hp = GameConstants.HEAVY_HP
			_damage = GameConstants.HEAVY_DAMAGE
			_speed = GameConstants.HEAVY_SPEED
			add_to_group(GameConstants.GROUP_HEAVY)
		Enums.EnemyType.SPECIAL_FORCES:
			max_hp = GameConstants.SPECIAL_FORCES_HP
			_damage = GameConstants.SPECIAL_FORCES_DAMAGE
			_speed = GameConstants.SPECIAL_FORCES_SPEED
			add_to_group(GameConstants.GROUP_SPECIAL_FORCES)
	_setup_sprite(type)
	_setup_collision_shape(type)
	_setup_sprite_scale(type)
	_setup_health_component(max_hp)


func _setup_sprite(type: Enums.EnemyType) -> void:
	var sprite_path: String = Data.SPRITE_PATHS.get(type, Data.SPRITE_PATHS[Enums.EnemyType.MILITARY])
	sprite.texture = load(sprite_path)


func _setup_collision_shape(type: Enums.EnemyType) -> void:
	var radius: float = Data.COLLISION_RADII.get(type, Data.COLLISION_RADIUS)
	var shape := CircleShape2D.new()
	shape.radius = radius
	collision_shape.shape = shape


func _setup_sprite_scale(type: Enums.EnemyType) -> void:
	if sprite.texture == null:
		return
	var radius: float = Data.COLLISION_RADII.get(type, Data.COLLISION_RADIUS)
	var size_ratio: float = Data.SPRITE_SIZE_RATIOS.get(type, Data.SPRITE_SIZE_RATIO)
	var texture_size := sprite.texture.get_size()
	var desired_diameter := radius * 2.0 * size_ratio
	var max_dimension := maxf(texture_size.x, texture_size.y)
	var scale_factor := desired_diameter / max_dimension
	sprite.scale = Vector2(scale_factor, scale_factor)


func _setup_detection() -> void:
	# Configure detection area
	var detect_shape := detection_area.get_node("CollisionShape2D") as CollisionShape2D
	if detect_shape:
		var circle := CircleShape2D.new()
		circle.radius = Data.DETECTION_RADIUS
		detect_shape.shape = circle

	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)


func _setup_combat() -> void:
	# Configure attack range
	var attack_shape := attack_range.get_node("CollisionShape2D") as CollisionShape2D
	if attack_shape:
		var circle := CircleShape2D.new()
		circle.radius = Data.ATTACK_RANGE
		attack_shape.shape = circle

	attack_timer.wait_time = Data.ATTACK_COOLDOWN
	attack_timer.one_shot = true

	attack_range.body_entered.connect(_on_attack_range_body_entered)
	attack_range.body_exited.connect(_on_attack_range_body_exited)

	patrol_timer.wait_time = Data.PATROL_INTERVAL
	patrol_timer.one_shot = true
	patrol_timer.start()


func _setup_health_component(max_hp: int) -> void:
	_health = HealthComponent.new()
	add_child(_health)
	_health.setup(max_hp)
	_health.died.connect(_die)


func _physics_process(_delta: float) -> void:
	match _state:
		State.PATROL:
			_process_patrol()
		State.CHASE:
			_process_chase()
		State.ATTACK:
			_process_attack()
		State.INVESTIGATE:
			_process_investigate()


func _process_patrol() -> void:
	var distance := global_position.distance_to(_patrol_target)

	if distance > Data.PATROL_ARRIVAL_DISTANCE:
		var direction := (_patrol_target - global_position).normalized()
		velocity = direction * _speed * Data.PATROL_SPEED_FACTOR

		if velocity.x != 0:
			sprite.flip_h = velocity.x < 0

		move_and_slide()
	else:
		velocity = Vector2.ZERO
		if patrol_timer.is_stopped():
			patrol_timer.start()


func _process_chase() -> void:
	if _chase_target == null or not is_instance_valid(_chase_target):
		_update_chase_target()
		if _chase_target == null:
			_state = State.PATROL
			return

	var distance := global_position.distance_to(_chase_target.global_position)

	if distance > Data.ATTACK_RANGE * Data.ATTACK_RANGE_FACTOR:
		var direction := (_chase_target.global_position - global_position).normalized()
		velocity = direction * _speed

		if velocity.x != 0:
			sprite.flip_h = velocity.x < 0

		move_and_slide()
	else:
		velocity = Vector2.ZERO
		_attack_target = _chase_target
		_state = State.ATTACK


func _process_attack() -> void:
	if _attack_target == null or not is_instance_valid(_attack_target):
		_update_attack_target()
		if _attack_target == null:
			_update_chase_target()
			_state = State.CHASE if _chase_target != null else State.PATROL
			return

	# Stay in position and attack
	velocity = Vector2.ZERO
	_try_attack()


func _process_investigate() -> void:
	# Check if we spotted a threat while investigating
	if _threats_detected.size() > 0:
		_update_chase_target()
		if _chase_target != null:
			_state = State.CHASE
			return

	var distance := global_position.distance_to(_investigate_target)

	if distance > Data.PATROL_ARRIVAL_DISTANCE:
		var direction := (_investigate_target - global_position).normalized()
		velocity = direction * _speed  # Move at full speed to investigate

		if velocity.x != 0:
			sprite.flip_h = velocity.x < 0

		move_and_slide()
	else:
		# Reached investigation point, return to patrol
		velocity = Vector2.ZERO
		_state = State.PATROL
		_pick_patrol_target()


func investigate_position(target_pos: Vector2) -> void:
	## Called when alarm is triggered - move to investigate
	# Only interrupt if not already engaged in combat
	if _state == State.PATROL or _state == State.INVESTIGATE:
		_investigate_target = target_pos
		_state = State.INVESTIGATE


func _pick_patrol_target() -> void:
	var angle := randf() * TAU
	var radius := randf_range(0, Data.PATROL_RADIUS)
	_patrol_target = _spawn_position + Vector2(cos(angle), sin(angle)) * radius


func _update_chase_target() -> void:
	_chase_target = null
	var closest_distance := INF

	_threats_detected = _threats_detected.filter(func(t): return is_instance_valid(t))

	for threat in _threats_detected:
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


func _try_attack() -> void:
	if _attack_target == null or not attack_timer.is_stopped():
		return
	if not is_instance_valid(_attack_target):
		_attack_target = null
		return

	if _attack_target.has_method("take_damage"):
		_attack_target.take_damage(_damage)
	attack_timer.start()


func _on_attack_timer_timeout() -> void:
	if _state == State.ATTACK:
		_try_attack()


func _on_patrol_timer_timeout() -> void:
	if _state == State.PATROL:
		_pick_patrol_target()


#region Detection

func _on_detection_area_body_entered(body: Node2D) -> void:
	# Detect threats (Dark Lord, minions) AND player buildings
	if body.is_in_group(GameConstants.GROUP_THREATS) or body.is_in_group(GameConstants.GROUP_BUILDINGS):
		_threats_detected.append(body)
		if _state == State.PATROL:
			_chase_target = body
			_state = State.CHASE

		# Military sighting: configured enemy types spotting Dark Lord trigger threat increase
		if body.is_in_group(GameConstants.GROUP_DARK_LORD):
			if enemy_type in GameConstants.THREAT_REPORTING_ENEMY_TYPES:
				EventBus.dark_lord_spotted_by_military.emit(global_position)


func _on_detection_area_body_exited(body: Node2D) -> void:
	_threats_detected.erase(body)
	if body == _chase_target:
		_update_chase_target()


func _on_attack_range_body_entered(body: Node2D) -> void:
	# Target threats (Dark Lord, minions) AND player buildings (portals, corruption nodes, spawning pits)
	if body.is_in_group(GameConstants.GROUP_THREATS) or body.is_in_group(GameConstants.GROUP_BUILDINGS):
		_threats_in_attack_range.append(body)
		if _attack_target == null:
			_attack_target = body
			_state = State.ATTACK


func _on_attack_range_body_exited(body: Node2D) -> void:
	_threats_in_attack_range.erase(body)
	if body == _attack_target:
		_update_attack_target()

#endregion


#region Combat

func take_damage(amount: int) -> void:
	_health.take_damage(amount)


func _die() -> void:
	queue_free()

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

	# Layer: world layer only (enemies don't need threat layer)
	# Mask: walls only - units don't block each other
	collision_layer = world_layer
	collision_mask = GameConstants.COLLISION_MASK_WALLS

	# Update detection areas to detect threats in current world
	detection_area.collision_mask = GameConstants.COLLISION_MASK_THREATS
	attack_range.collision_mask = GameConstants.COLLISION_MASK_THREATS

#endregion

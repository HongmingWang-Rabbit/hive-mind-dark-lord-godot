extends CharacterBody2D
## Civilian entity - wanders in Human World, provides essence when killed

const Data := preload("res://scripts/entities/humans/CivilianData.gd")

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var wander_timer: Timer = $WanderTimer

# State
var _hp: int
var _target_position: Vector2
var _is_moving := false


func _ready() -> void:
	add_to_group(GameConstants.GROUP_CIVILIANS)
	add_to_group(GameConstants.GROUP_KILLABLE)
	_hp = GameConstants.CIVILIAN_HP
	_setup_collision_shape()
	_setup_sprite_scale()
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

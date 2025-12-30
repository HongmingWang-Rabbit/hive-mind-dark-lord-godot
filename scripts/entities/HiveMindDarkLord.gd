extends CharacterBody2D
## Hive Mind Dark Lord - the player's avatar that wanders corrupted territory
## Spawns at initial corruption point. More behaviors to be added later.

const Data := preload("res://scripts/entities/DarkLordData.gd")

@onready var sprite: Sprite2D = $Sprite2D
@onready var wander_timer: Timer = $WanderTimer

# Current movement target
var _target_position: Vector2
var _is_moving := false


func _ready() -> void:
	sprite.scale = Data.SPRITE_SCALE
	_start_wander_timer()


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

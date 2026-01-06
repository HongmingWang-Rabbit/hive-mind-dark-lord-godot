extends StaticBody2D
## Alarm Tower - Human defense structure
## Civilians flee toward these when threatened. When a fleeing civilian reaches
## the tower, they trigger an alarm that increases threat and attracts enemies.

const Data := preload("res://scripts/entities/buildings/AlarmTowerData.gd")

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var trigger_area: Area2D = $TriggerArea
@onready var cooldown_timer: Timer = $CooldownTimer

# State
var _tile_pos: Vector2i
var _is_on_cooldown := false


func _ready() -> void:
	add_to_group(GameConstants.GROUP_ALARM_TOWERS)
	_setup_collision_shape()
	_setup_sprite()
	_setup_trigger_area()
	_setup_cooldown_timer()
	# Alarm towers are in Human World only
	set_world_collision(Enums.WorldType.HUMAN)


func setup(tile_pos: Vector2i) -> void:
	## Call after instantiation to configure position
	_tile_pos = tile_pos
	var tile_size := GameConstants.TILE_SIZE
	global_position = Vector2(tile_pos) * tile_size + Vector2(tile_size, tile_size) / 2.0


func _setup_collision_shape() -> void:
	var shape := CircleShape2D.new()
	shape.radius = Data.COLLISION_RADIUS
	collision_shape.shape = shape


func _setup_sprite() -> void:
	sprite.texture = load(Data.SPRITE_PATH)
	if sprite.texture:
		var texture_size := sprite.texture.get_size()
		var desired_diameter := Data.COLLISION_RADIUS * 2.0 * Data.SPRITE_SIZE_RATIO
		var max_dimension := maxf(texture_size.x, texture_size.y)
		var scale_factor := desired_diameter / max_dimension
		sprite.scale = Vector2(scale_factor, scale_factor)
	sprite.modulate = Data.ACTIVE_COLOR


func _setup_trigger_area() -> void:
	var trigger_shape := trigger_area.get_node("CollisionShape2D") as CollisionShape2D
	if trigger_shape:
		var circle := CircleShape2D.new()
		circle.radius = Data.TRIGGER_RADIUS
		trigger_shape.shape = circle

	trigger_area.body_entered.connect(_on_trigger_area_body_entered)


func _setup_cooldown_timer() -> void:
	cooldown_timer.wait_time = Data.ALARM_COOLDOWN
	cooldown_timer.one_shot = true
	cooldown_timer.timeout.connect(_on_cooldown_timer_timeout)


func _on_trigger_area_body_entered(body: Node2D) -> void:
	# Only civilians can trigger the alarm
	if not body.is_in_group(GameConstants.GROUP_CIVILIANS):
		return

	# Check if civilian is fleeing (has seen a threat)
	if body.has_method("is_fleeing") and body.is_fleeing():
		_try_trigger_alarm(body)


func _try_trigger_alarm(triggering_civilian: Node2D) -> void:
	## Attempt to trigger the alarm
	if _is_on_cooldown:
		return

	_is_on_cooldown = true
	cooldown_timer.start()

	# Visual feedback - flash red
	sprite.modulate = Data.ALARM_COLOR
	_flash_alarm()

	# Increase threat level
	EventBus.alarm_triggered.emit(global_position)

	# The civilian has done their job - they can continue fleeing or calm down
	if triggering_civilian.has_method("on_alarm_triggered"):
		triggering_civilian.on_alarm_triggered()


func _flash_alarm() -> void:
	## Visual feedback when alarm triggered
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Data.COOLDOWN_COLOR, Data.ALARM_FLASH_DURATION)


func _on_cooldown_timer_timeout() -> void:
	_is_on_cooldown = false
	sprite.modulate = Data.ACTIVE_COLOR


func is_on_cooldown() -> bool:
	return _is_on_cooldown


#region World Collision

func set_world_collision(target_world: Enums.WorldType) -> void:
	## Set collision layer based on world
	var world_layer: int
	match target_world:
		Enums.WorldType.CORRUPTED:
			world_layer = 1 << (GameConstants.COLLISION_LAYER_CORRUPTED_WORLD - 1)
		Enums.WorldType.HUMAN:
			world_layer = 1 << (GameConstants.COLLISION_LAYER_HUMAN_WORLD - 1)

	collision_layer = world_layer
	collision_mask = 0  # Static body, doesn't need to detect collisions

	# Trigger area detects civilians in the current world
	trigger_area.collision_mask = world_layer

#endregion

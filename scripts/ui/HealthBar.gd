extends Node2D
## Visual health bar component for entities
## Add as child of any entity with health, call update_health() when HP changes

var _max_hp: int = 1
var _current_hp: int = 1

# Visual components (created in code for simplicity)
var _bg_rect: ColorRect
var _fill_rect: ColorRect


func _ready() -> void:
	_setup_visuals()
	# Position above entity
	position.y = GameConstants.HEALTH_BAR_OFFSET_Y


func _setup_visuals() -> void:
	var width := GameConstants.HEALTH_BAR_WIDTH
	var height := GameConstants.HEALTH_BAR_HEIGHT
	var border := GameConstants.HEALTH_BAR_BORDER_WIDTH

	# Background (border)
	_bg_rect = ColorRect.new()
	_bg_rect.size = Vector2(width + border * 2, height + border * 2)
	_bg_rect.position = Vector2(-width / 2.0 - border, -height / 2.0 - border)
	_bg_rect.color = GameConstants.HEALTH_BAR_BORDER_COLOR
	add_child(_bg_rect)

	# Inner background
	var inner_bg := ColorRect.new()
	inner_bg.size = Vector2(width, height)
	inner_bg.position = Vector2(-width / 2.0, -height / 2.0)
	inner_bg.color = GameConstants.HEALTH_BAR_BG_COLOR
	add_child(inner_bg)

	# Health fill
	_fill_rect = ColorRect.new()
	_fill_rect.size = Vector2(width, height)
	_fill_rect.position = Vector2(-width / 2.0, -height / 2.0)
	_fill_rect.color = GameConstants.HEALTH_BAR_HIGH_COLOR
	add_child(_fill_rect)

	# Start hidden (will show when damaged)
	visible = false


func setup(max_hp: int, current_hp: int = -1) -> void:
	## Initialize with max HP. current_hp defaults to max if not specified.
	_max_hp = max_hp
	_current_hp = current_hp if current_hp >= 0 else max_hp
	_update_display()


func update_health(current_hp: int) -> void:
	## Update the health bar display
	_current_hp = current_hp
	_update_display()


func _update_display() -> void:
	if _fill_rect == null:
		return

	var percent := float(_current_hp) / float(_max_hp) if _max_hp > 0 else 0.0
	percent = clampf(percent, 0.0, 1.0)

	# Update fill width
	var full_width := GameConstants.HEALTH_BAR_WIDTH
	_fill_rect.size.x = full_width * percent

	# Update color based on health percentage
	if percent > GameConstants.HEALTH_BAR_HIGH_THRESHOLD:
		_fill_rect.color = GameConstants.HEALTH_BAR_HIGH_COLOR
	elif percent > GameConstants.HEALTH_BAR_LOW_THRESHOLD:
		_fill_rect.color = GameConstants.HEALTH_BAR_MED_COLOR
	else:
		_fill_rect.color = GameConstants.HEALTH_BAR_LOW_COLOR

	# Hide when at full health
	visible = percent < 1.0

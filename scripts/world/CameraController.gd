extends Camera2D
## Camera controller - handles panning via keyboard and mouse drag
## Attach to Camera2D node. Call set_bounds() after map generation.

# Computed bounds (call set_bounds to configure)
var _bounds: Rect2
var _bounds_initialized := false

# Drag state
var _is_dragging := false
var _drag_start_mouse: Vector2
var _drag_start_camera: Vector2


func _ready() -> void:
	position = GameConstants.CAMERA_CENTER


func _process(delta: float) -> void:
	_handle_keyboard_pan(delta)


func _input(event: InputEvent) -> void:
	_handle_drag(event)


## Configure camera bounds based on map size in tiles
func set_map_bounds(map_width: int, map_height: int) -> void:
	var tile_size := GameConstants.TILE_SIZE
	var padding := GameConstants.CAMERA_EDGE_PADDING
	var half_viewport := Vector2(GameConstants.VIEWPORT_WIDTH, GameConstants.VIEWPORT_HEIGHT) / 2.0
	var map_pixel_size := Vector2(map_width * tile_size, map_height * tile_size)

	# Bounds define where camera CENTER can be positioned
	_bounds = Rect2(
		half_viewport.x - padding,
		half_viewport.y - padding,
		map_pixel_size.x - GameConstants.VIEWPORT_WIDTH + padding * 2,
		map_pixel_size.y - GameConstants.VIEWPORT_HEIGHT + padding * 2
	)

	# Handle maps smaller than viewport
	if _bounds.size.x < 0:
		_bounds.position.x = map_pixel_size.x / 2.0
		_bounds.size.x = 0
	if _bounds.size.y < 0:
		_bounds.position.y = map_pixel_size.y / 2.0
		_bounds.size.y = 0

	_bounds_initialized = true
	_clamp_position()


func _handle_keyboard_pan(delta: float) -> void:
	var input_dir := _get_input_direction()

	if input_dir != Vector2.ZERO:
		var movement := input_dir.normalized() * GameConstants.CAMERA_PAN_SPEED * delta
		position += movement
		_clamp_position()


func _get_input_direction() -> Vector2:
	var dir := Vector2.ZERO

	# Arrow keys (built-in actions)
	if Input.is_action_pressed("ui_left"):
		dir.x -= 1
	if Input.is_action_pressed("ui_right"):
		dir.x += 1
	if Input.is_action_pressed("ui_up"):
		dir.y -= 1
	if Input.is_action_pressed("ui_down"):
		dir.y += 1

	# WASD keys (physical for consistent layout)
	if Input.is_physical_key_pressed(KEY_A):
		dir.x -= 1
	if Input.is_physical_key_pressed(KEY_D):
		dir.x += 1
	if Input.is_physical_key_pressed(KEY_W):
		dir.y -= 1
	if Input.is_physical_key_pressed(KEY_S):
		dir.y += 1

	return dir


func _handle_drag(event: InputEvent) -> void:
	# Mouse drag
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if _is_drag_button(mouse_event.button_index):
			_set_dragging(mouse_event.pressed, mouse_event.position)

	elif event is InputEventMouseMotion and _is_dragging:
		_apply_drag((event as InputEventMouseMotion).position)

	# Touch drag
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		_set_dragging(touch_event.pressed, touch_event.position)

	elif event is InputEventScreenDrag and _is_dragging:
		_apply_drag((event as InputEventScreenDrag).position)


func _is_drag_button(button_index: MouseButton) -> bool:
	for btn in GameConstants.CAMERA_DRAG_BUTTONS:
		if button_index == btn:
			return true
	return false


func _set_dragging(pressed: bool, event_position: Vector2) -> void:
	if pressed:
		_is_dragging = true
		_drag_start_mouse = event_position
		_drag_start_camera = position
	else:
		_is_dragging = false


func _apply_drag(current_position: Vector2) -> void:
	var drag_delta := _drag_start_mouse - current_position
	position = _drag_start_camera + drag_delta
	_clamp_position()


func _clamp_position() -> void:
	if not _bounds_initialized:
		return
	position.x = clampf(position.x, _bounds.position.x, _bounds.end.x)
	position.y = clampf(position.y, _bounds.position.y, _bounds.end.y)

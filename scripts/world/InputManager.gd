extends RefCounted
## Handles input, interaction modes, and cursor preview
## Manages build mode, order mode, and keyboard shortcuts

const PortalData := preload("res://scripts/entities/buildings/PortalData.gd")
const CorruptionNodeData := preload("res://scripts/entities/buildings/CorruptionNodeData.gd")
const SpawningPitData := preload("res://scripts/entities/buildings/SpawningPitData.gd")

# Reference to World (for map access)
var _world: Node2D

# Reference to camera
var _camera: Camera2D

# Reference to entity spawner (for minion spawning)
var _entity_spawner: RefCounted

# Reference to corruption manager (for spread debug)
var _corruption_manager: RefCounted

# Interaction mode state
var _interaction_mode: Enums.InteractionMode = Enums.InteractionMode.NONE
var _pending_building_type: Enums.BuildingType
var _pending_order_assignment: Enums.MinionAssignment

# Cursor preview
var cursor_preview: Sprite2D  # Building preview - World adds to tree
var order_cursor: Sprite2D    # Order target - World adds to tree
var _building_textures: Dictionary = {}


func setup(world: Node2D, camera: Camera2D, entity_spawner: RefCounted, corruption_manager: RefCounted) -> void:
	_world = world
	_camera = camera
	_entity_spawner = entity_spawner
	_corruption_manager = corruption_manager

	_setup_cursor_preview()

	EventBus.build_mode_entered.connect(_on_build_mode_entered)
	EventBus.order_mode_entered.connect(_on_order_mode_entered)
	EventBus.retreat_ordered.connect(_on_retreat_ordered)


func _setup_cursor_preview() -> void:
	# Load building sprites from Data files
	_building_textures[Enums.BuildingType.PORTAL] = load(PortalData.SPRITE_PATH)
	_building_textures[Enums.BuildingType.CORRUPTION_NODE] = load(CorruptionNodeData.SPRITE_PATH)
	_building_textures[Enums.BuildingType.SPAWNING_PIT] = load(SpawningPitData.SPRITE_PATH)

	# Create sprite for cursor preview (buildings)
	cursor_preview = Sprite2D.new()
	cursor_preview.visible = false
	cursor_preview.z_index = GameConstants.CURSOR_PREVIEW_Z_INDEX
	cursor_preview.modulate = GameConstants.CURSOR_PREVIEW_COLOR
	cursor_preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	# Create order cursor (simple circle texture)
	order_cursor = Sprite2D.new()
	order_cursor.visible = false
	order_cursor.z_index = GameConstants.CURSOR_PREVIEW_Z_INDEX
	order_cursor.texture = _create_order_cursor_texture()


func _create_order_cursor_texture() -> Texture2D:
	## Create a simple circle texture for order cursor
	var size := int(GameConstants.ORDER_CURSOR_SIZE)
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := size / 2.0
	var radius := size / 2.0 - 1.0

	var ring_width := GameConstants.ORDER_CURSOR_RING_WIDTH
	var center_alpha := GameConstants.ORDER_CURSOR_CENTER_ALPHA

	for x in size:
		for y in size:
			var dist := Vector2(x - center, y - center).length()
			if dist <= radius and dist >= radius - ring_width:
				# Draw ring
				image.set_pixel(x, y, Color.WHITE)
			elif dist < radius - ring_width:
				# Fill center with semi-transparent
				image.set_pixel(x, y, Color(1.0, 1.0, 1.0, center_alpha))

	return ImageTexture.create_from_image(image)


func _get_building_data(building_type: Enums.BuildingType) -> RefCounted:
	match building_type:
		Enums.BuildingType.PORTAL:
			return PortalData
		Enums.BuildingType.CORRUPTION_NODE:
			return CorruptionNodeData
		Enums.BuildingType.SPAWNING_PIT:
			return SpawningPitData
	return null


func handle_input(event: InputEvent) -> bool:
	## Handle input event. Returns true if event was handled.

	# Spread corruption (debug)
	if event.is_action_pressed("ui_accept"):
		_corruption_manager.spread_corruption()
		return true

	# ESC cancels interaction mode (highest priority after UI)
	if event.is_action_pressed("ui_cancel"):
		if _interaction_mode != Enums.InteractionMode.NONE:
			_cancel_interaction_mode()
			_world.get_viewport().set_input_as_handled()
			return true

	# Mouse clicks - check if over UI first
	if event is InputEventMouseButton and event.pressed:
		if _is_mouse_over_ui():
			return false

		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			_handle_left_click(mouse_event)
			return true
		elif mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			_handle_right_click(mouse_event)
			return true

	# Keyboard shortcuts
	if event is InputEventKey:
		return _handle_keyboard(event as InputEventKey)

	return false


func _is_mouse_over_ui() -> bool:
	## Check if mouse is currently over any UI control
	return _world.get_viewport().gui_get_hovered_control() != null


func _handle_left_click(event: InputEventMouseButton) -> void:
	var world_pos := _get_world_position_from_mouse(event.position)

	if _interaction_mode != Enums.InteractionMode.NONE:
		# Left-click confirms placement/order
		_handle_interaction_click(world_pos)
		_world.get_viewport().set_input_as_handled()
	else:
		# Left-click with no mode active = move Dark Lord
		EventBus.dark_lord_move_ordered.emit(world_pos)
		_world.get_viewport().set_input_as_handled()


func _handle_right_click(_event: InputEventMouseButton) -> void:
	# Right-click cancels interaction mode
	if _interaction_mode != Enums.InteractionMode.NONE:
		_cancel_interaction_mode()
		_world.get_viewport().set_input_as_handled()


func _handle_keyboard(event: InputEventKey) -> bool:
	if not event.pressed:
		return false

	# Debug: Switch worlds
	if event.keycode == GameConstants.KEY_SWITCH_WORLD:
		var target := Enums.WorldType.HUMAN if WorldManager.active_world == Enums.WorldType.CORRUPTED else Enums.WorldType.CORRUPTED
		WorldManager.switch_world(target)
		return true

	# Minion spawning hotkeys
	match event.keycode:
		GameConstants.KEY_SPAWN_CRAWLER:
			_entity_spawner.spawn_minion(Enums.MinionType.CRAWLER)
			return true
		GameConstants.KEY_SPAWN_BRUTE:
			_entity_spawner.spawn_minion(Enums.MinionType.BRUTE)
			return true
		GameConstants.KEY_SPAWN_STALKER:
			_entity_spawner.spawn_minion(Enums.MinionType.STALKER)
			return true

	return false


func _get_world_position_from_mouse(_screen_pos: Vector2) -> Vector2:
	## Convert screen position to world position
	return _camera.get_global_mouse_position()


func update_cursor_preview() -> void:
	## Update cursor preview position (called from World._process)
	if _interaction_mode == Enums.InteractionMode.NONE:
		return

	var mouse_pos := _camera.get_global_mouse_position()

	if _interaction_mode == Enums.InteractionMode.BUILD:
		var tile_pos := Vector2i(mouse_pos / GameConstants.TILE_SIZE)
		# Center sprite on tile (Sprite2D is centered by default)
		var tile_size := float(GameConstants.TILE_SIZE)
		cursor_preview.position = Vector2(tile_pos) * tile_size + Vector2(tile_size, tile_size) / 2.0
	elif _interaction_mode == Enums.InteractionMode.ORDER:
		# Order cursor follows mouse directly (not snapped to tile)
		order_cursor.position = mouse_pos


#region Interaction Mode

func _on_build_mode_entered(building_type: Enums.BuildingType) -> void:
	## Enter build placement mode - next click will place building
	_interaction_mode = Enums.InteractionMode.BUILD
	_pending_building_type = building_type

	# Set texture and scale based on building data
	var texture: Texture2D = _building_textures.get(building_type)
	cursor_preview.texture = texture
	if texture:
		var data := _get_building_data(building_type)
		var texture_size := texture.get_size()
		var desired_diameter: float = data.COLLISION_RADIUS * 2.0 * data.SPRITE_SIZE_RATIO
		var max_dimension := maxf(texture_size.x, texture_size.y)
		var scale_factor := desired_diameter / max_dimension
		cursor_preview.scale = Vector2(scale_factor, scale_factor)

	cursor_preview.visible = true
	EventBus.interaction_mode_changed.emit(Enums.InteractionMode.BUILD, building_type)


func _on_order_mode_entered(assignment: Enums.MinionAssignment) -> void:
	## Enter order mode - next click will issue order to that location
	_interaction_mode = Enums.InteractionMode.ORDER
	_pending_order_assignment = assignment

	# Set order cursor color based on assignment type
	match assignment:
		Enums.MinionAssignment.ATTACKING:
			order_cursor.modulate = GameConstants.ORDER_CURSOR_COLOR
		Enums.MinionAssignment.DEFENDING:
			order_cursor.modulate = GameConstants.ORDER_CURSOR_DEFEND_COLOR
		Enums.MinionAssignment.IDLE:
			order_cursor.modulate = GameConstants.ORDER_CURSOR_SCOUT_COLOR

	order_cursor.visible = true
	EventBus.interaction_mode_changed.emit(Enums.InteractionMode.ORDER, assignment)


func _cancel_interaction_mode() -> void:
	_interaction_mode = Enums.InteractionMode.NONE
	cursor_preview.visible = false
	order_cursor.visible = false
	EventBus.interaction_cancelled.emit()


func _handle_interaction_click(world_pos: Vector2) -> void:
	## Handle a click in interaction mode
	var tile_pos := Vector2i(world_pos / GameConstants.TILE_SIZE)

	match _interaction_mode:
		Enums.InteractionMode.BUILD:
			_world.execute_build(tile_pos, _pending_building_type)
		Enums.InteractionMode.ORDER:
			_execute_order(world_pos)

	_cancel_interaction_mode()


func _execute_order(target_pos: Vector2) -> void:
	## Issue order to minions at target position
	match _pending_order_assignment:
		Enums.MinionAssignment.ATTACKING:
			HivePool.send_attack(target_pos, 1.0, Enums.Stance.AGGRESSIVE)
		Enums.MinionAssignment.DEFENDING:
			# Defend mode - move to position and hold (attack only when attacked)
			HivePool.send_attack(target_pos, 1.0, Enums.Stance.HOLD)
		Enums.MinionAssignment.IDLE:
			# Scout - move to location then return to follow
			HivePool.send_attack(target_pos, 1.0, Enums.Stance.RETREAT)


func _on_retreat_ordered() -> void:
	## Make all minions return to following the Dark Lord
	HivePool.recall_attackers()
	# Signal all minions to return to follow state
	var minions := _world.get_tree().get_nodes_in_group(GameConstants.GROUP_MINIONS)
	for minion in minions:
		if minion.has_method("retreat"):
			minion.retreat()

#endregion

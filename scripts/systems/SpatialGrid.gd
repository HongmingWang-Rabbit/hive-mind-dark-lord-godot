extends Node
## Spatial partitioning grid for efficient neighbor queries
## Reduces O(n²) neighbor checks to O(n) by only checking nearby cells

# Grid cell size - should be >= separation distance for efficiency
const CELL_SIZE := 32.0  # 2x SEPARATION_DISTANCE (16)

# Grid storage: Dictionary[Vector2i cell -> Array[Node2D] entities]
var _grid: Dictionary = {}

# Entity to cell mapping for fast removal
var _entity_cells: Dictionary = {}  # Dictionary[Node2D -> Vector2i]


func _ready() -> void:
	# Clean up dead entities periodically
	var cleanup_timer := Timer.new()
	cleanup_timer.wait_time = 1.0
	cleanup_timer.timeout.connect(_cleanup_dead_entities)
	add_child(cleanup_timer)
	cleanup_timer.start()


func _pos_to_cell(pos: Vector2) -> Vector2i:
	return Vector2i(floor(pos.x / CELL_SIZE), floor(pos.y / CELL_SIZE))


func update_entity(entity: Node2D) -> void:
	## Call this when an entity moves to update its grid position
	var new_cell := _pos_to_cell(entity.global_position)
	var old_cell: Variant = _entity_cells.get(entity)

	# Skip if cell hasn't changed
	if old_cell != null and old_cell == new_cell:
		return

	# Remove from old cell
	if old_cell != null:
		var old_cell_key: Vector2i = old_cell
		if _grid.has(old_cell_key):
			var cell_entities: Array = _grid[old_cell_key]
			cell_entities.erase(entity)
			if cell_entities.is_empty():
				_grid.erase(old_cell_key)

	# Add to new cell
	if not _grid.has(new_cell):
		_grid[new_cell] = []
	_grid[new_cell].append(entity)
	_entity_cells[entity] = new_cell


func remove_entity(entity: Node2D) -> void:
	## Call when entity is destroyed
	var cell: Variant = _entity_cells.get(entity)
	if cell != null:
		var cell_key: Vector2i = cell
		if _grid.has(cell_key):
			_grid[cell_key].erase(entity)
			if _grid[cell_key].is_empty():
				_grid.erase(cell_key)
		_entity_cells.erase(entity)


func get_nearby_entities(pos: Vector2, radius: float) -> Array[Node2D]:
	## Get all entities within radius of position (approximate - checks nearby cells)
	var result: Array[Node2D] = []
	var center_cell := _pos_to_cell(pos)
	var cell_radius := ceili(radius / CELL_SIZE)

	# Check all cells within range
	for dx in range(-cell_radius, cell_radius + 1):
		for dy in range(-cell_radius, cell_radius + 1):
			var check_cell := center_cell + Vector2i(dx, dy)
			if _grid.has(check_cell):
				for entity in _grid[check_cell]:
					if is_instance_valid(entity):
						result.append(entity)

	return result


func _cleanup_dead_entities() -> void:
	## Remove entities that have been freed
	var to_remove: Array[Node2D] = []
	for entity in _entity_cells.keys():
		if not is_instance_valid(entity):
			to_remove.append(entity)

	for entity in to_remove:
		var cell: Variant = _entity_cells.get(entity)
		if cell != null:
			var cell_key: Vector2i = cell
			if _grid.has(cell_key):
				_grid[cell_key].erase(entity)
				if _grid[cell_key].is_empty():
					_grid.erase(cell_key)
		_entity_cells.erase(entity)


func reset() -> void:
	## Clear all data
	_grid.clear()
	_entity_cells.clear()

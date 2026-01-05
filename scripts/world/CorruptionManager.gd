extends RefCounted
## Manages corruption spreading and tracking in both worlds
## Corruption spreads from Corruption Nodes and near portals

# Reference to World (for map access)
var _world: Node2D

# Per-world corruption tracking
var human_corrupted_tiles: Dictionary = {}
var corrupted_corrupted_tiles: Dictionary = {}

# Reference to fog manager for auto-reveal
var _fog_manager: RefCounted


func setup(world: Node2D, fog_manager: RefCounted = null) -> void:
	_world = world
	_fog_manager = fog_manager


func corrupt_tile(tile_pos: Vector2i, world: Enums.WorldType = Enums.WorldType.CORRUPTED) -> void:
	## Corrupt a single tile in the specified world
	var tiles_dict: Dictionary
	var corruption_map: TileMapLayer
	var floor_map: TileMapLayer

	match world:
		Enums.WorldType.HUMAN:
			# In Human World, corruption can spread:
			# 1. Near a portal (initial corruption)
			# 2. Adjacent to existing corruption (natural spread from nodes)
			if not WorldManager.can_corrupt_in_human_world(tile_pos):
				if not _is_adjacent_to_corruption(tile_pos, world):
					return
			tiles_dict = human_corrupted_tiles
			corruption_map = _world.human_corruption_map
			floor_map = _world.human_floor_map
		Enums.WorldType.CORRUPTED:
			tiles_dict = corrupted_corrupted_tiles
			corruption_map = _world.corrupted_corruption_map
			floor_map = _world.corrupted_floor_map

	if tiles_dict.has(tile_pos):
		return

	if floor_map.get_cell_source_id(tile_pos) == -1:
		return

	tiles_dict[tile_pos] = true

	var floor_tile := floor_map.get_cell_atlas_coords(tile_pos)
	corruption_map.set_cell(tile_pos, GameConstants.TILEMAP_SOURCE_ID, floor_tile)

	# Auto-reveal fog when corruption spreads in Corrupted World
	if world == Enums.WorldType.CORRUPTED and GameConstants.FOG_ENABLED and _fog_manager:
		_fog_manager.reveal_tile(tile_pos, Enums.WorldType.CORRUPTED)

	EventBus.tile_corrupted.emit(tile_pos)
	_update_corruption_percent()


func spread_corruption() -> void:
	## Spread corruption to a random adjacent tile in the active world
	var candidates := _get_corruption_candidates(WorldManager.active_world)
	if candidates.size() > 0:
		var target: Vector2i = candidates[randi_range(0, candidates.size() - 1)]
		corrupt_tile(target, WorldManager.active_world)


func _get_corruption_candidates(world: Enums.WorldType) -> Array[Vector2i]:
	var candidates: Array[Vector2i] = []
	var tiles_dict: Dictionary
	var floor_map: TileMapLayer

	match world:
		Enums.WorldType.HUMAN:
			tiles_dict = human_corrupted_tiles
			floor_map = _world.human_floor_map
		Enums.WorldType.CORRUPTED:
			tiles_dict = corrupted_corrupted_tiles
			floor_map = _world.corrupted_floor_map

	for tile_pos: Vector2i in tiles_dict.keys():
		for dir: Vector2i in GameConstants.ORTHOGONAL_DIRS:
			var neighbor: Vector2i = tile_pos + dir
			if _can_corrupt_tile_in_world(neighbor, world, tiles_dict, floor_map):
				candidates.append(neighbor)

	return candidates


func _can_corrupt_tile_in_world(pos: Vector2i, world: Enums.WorldType, tiles_dict: Dictionary, floor_map: TileMapLayer) -> bool:
	if tiles_dict.has(pos):
		return false
	if floor_map.get_cell_source_id(pos) == -1:
		return false
	# In Human World, must be near a portal
	if world == Enums.WorldType.HUMAN:
		return WorldManager.can_corrupt_in_human_world(pos)
	return true


func clear_corruption(tile_pos: Vector2i) -> void:
	## Clear corruption in Human World (human counter-mechanic)
	if not human_corrupted_tiles.has(tile_pos):
		return

	human_corrupted_tiles.erase(tile_pos)
	_world.human_corruption_map.erase_cell(tile_pos)
	EventBus.corruption_cleared.emit(tile_pos)
	_update_corruption_percent()


func _update_corruption_percent() -> void:
	var total_tiles: int = _world.get_total_tiles()
	if total_tiles == 0:
		return
	# Calculate based on Human World corruption (that's what matters for winning)
	var percent := float(human_corrupted_tiles.size()) / float(total_tiles)
	GameManager.update_corruption(percent)


func is_tile_corrupted(tile_pos: Vector2i, world: Enums.WorldType) -> bool:
	## Check if a tile is corrupted in the given world
	match world:
		Enums.WorldType.HUMAN:
			return human_corrupted_tiles.has(tile_pos)
		Enums.WorldType.CORRUPTED:
			return corrupted_corrupted_tiles.has(tile_pos)
	return false


func _is_adjacent_to_corruption(tile_pos: Vector2i, world: Enums.WorldType) -> bool:
	## Check if tile is adjacent to any corrupted tile (for natural spread)
	for dir: Vector2i in GameConstants.ORTHOGONAL_DIRS:
		if is_tile_corrupted(tile_pos + dir, world):
			return true
	return false


func can_corrupt_tile(tile_pos: Vector2i, world: Enums.WorldType) -> bool:
	## Check if a tile can be corrupted (is floor and not already corrupted)
	var floor_map: TileMapLayer
	var tiles_dict: Dictionary

	match world:
		Enums.WorldType.HUMAN:
			floor_map = _world.human_floor_map
			tiles_dict = human_corrupted_tiles
		Enums.WorldType.CORRUPTED:
			floor_map = _world.corrupted_floor_map
			tiles_dict = corrupted_corrupted_tiles

	# Already corrupted
	if tiles_dict.has(tile_pos):
		return false

	# Not a valid floor tile
	if floor_map.get_cell_source_id(tile_pos) == -1:
		return false

	# Occupied by structure
	if _world.is_tile_occupied(tile_pos):
		return false

	return true


func corrupt_area_around(center: Vector2i, world: Enums.WorldType, radius: int) -> void:
	## Corrupt tiles within radius of center (Manhattan distance)
	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			var dist := absi(dx) + absi(dy)
			if dist <= radius:
				var pos := center + Vector2i(dx, dy)
				corrupt_tile(pos, world)


func reset() -> void:
	## Reset all corruption state
	human_corrupted_tiles.clear()
	corrupted_corrupted_tiles.clear()

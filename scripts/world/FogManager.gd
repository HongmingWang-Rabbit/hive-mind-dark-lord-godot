extends RefCounted
## Manages fog of war visibility in both worlds
## Tiles are revealed permanently once explored (no re-fogging for jam scope)

const Tiles := preload("res://scripts/data/tile_data.gd")
const FogUtils := preload("res://scripts/utils/fog_utils.gd")

# Reference to World (for map access)
var _world: Node2D

# Fog state - tiles that have been revealed (permanently cleared)
var _human_explored_tiles: Dictionary = {}
var _corrupted_explored_tiles: Dictionary = {}

# Map dimensions
var _map_width: int
var _map_height: int


func setup(world: Node2D, map_width: int, map_height: int) -> void:
	_world = world
	_map_width = map_width
	_map_height = map_height
	EventBus.fog_update_requested.connect(_on_fog_update_requested)


func setup_fog() -> void:
	## Initialize fog for both worlds
	if not GameConstants.FOG_ENABLED:
		return

	# Fill both worlds with fog
	_fill_fog_map(_world.human_fog_map, _world.human_floor_map)
	_fill_fog_map(_world.corrupted_fog_map, _world.corrupted_floor_map)


func _fill_fog_map(fog_map: TileMapLayer, floor_map: TileMapLayer) -> void:
	fog_map.modulate = GameConstants.FOG_COLOR
	for x in range(_map_width):
		for y in range(_map_height):
			var pos := Vector2i(x, y)
			if floor_map.get_cell_source_id(pos) != -1:
				fog_map.set_cell(pos, GameConstants.TILEMAP_SOURCE_ID, Tiles.FOG_TILE)


func reveal_initial_corruption(initial_tile: Vector2i) -> void:
	## Reveal area around initial corruption in Corrupted World
	var tiles := FogUtils.get_tiles_in_sight_range(
		initial_tile,
		GameConstants.INITIAL_CORRUPTION_REVEAL_RADIUS
	)
	for tile: Vector2i in tiles:
		_corrupted_explored_tiles[tile] = true
		_world.corrupted_fog_map.erase_cell(tile)


func reveal_tile(tile_pos: Vector2i, world: Enums.WorldType) -> void:
	## Reveal a single tile in the specified world
	var explored_tiles: Dictionary
	var fog_map: TileMapLayer

	match world:
		Enums.WorldType.HUMAN:
			explored_tiles = _human_explored_tiles
			fog_map = _world.human_fog_map
		Enums.WorldType.CORRUPTED:
			explored_tiles = _corrupted_explored_tiles
			fog_map = _world.corrupted_fog_map

	if not explored_tiles.has(tile_pos):
		explored_tiles[tile_pos] = true
		fog_map.erase_cell(tile_pos)


func update_fog(world: Enums.WorldType) -> void:
	## Update fog visibility for a world based on entity sight ranges
	## Once a tile is revealed, it stays revealed (no re-fogging for jam scope)
	if not GameConstants.FOG_ENABLED:
		return

	var fog_map: TileMapLayer
	var entities_container: Node2D
	var explored_tiles: Dictionary
	var use_corruption_reveal: bool

	match world:
		Enums.WorldType.HUMAN:
			fog_map = _world.human_fog_map
			entities_container = _world.human_entities
			explored_tiles = _human_explored_tiles
			use_corruption_reveal = false
		Enums.WorldType.CORRUPTED:
			fog_map = _world.corrupted_fog_map
			entities_container = _world.corrupted_entities
			explored_tiles = _corrupted_explored_tiles
			use_corruption_reveal = true

	# Gather visible tiles from entities
	var newly_visible: Array[Vector2i] = []
	for entity in entities_container.get_children():
		if entity.has_method("get_visible_tiles"):
			for tile: Vector2i in entity.get_visible_tiles():
				if not explored_tiles.has(tile):
					newly_visible.append(tile)

	# In Corrupted World, corrupted tiles are always revealed
	if use_corruption_reveal:
		var corrupted_tiles: Dictionary = _world.get_corrupted_tiles(Enums.WorldType.CORRUPTED)
		for tile_pos: Vector2i in corrupted_tiles.keys():
			if not explored_tiles.has(tile_pos):
				newly_visible.append(tile_pos)

	# Reveal newly visible tiles
	for tile_pos: Vector2i in newly_visible:
		explored_tiles[tile_pos] = true
		fog_map.erase_cell(tile_pos)


func _on_fog_update_requested(world: Enums.WorldType) -> void:
	update_fog(world)


func reset() -> void:
	## Reset all fog state
	_human_explored_tiles.clear()
	_corrupted_explored_tiles.clear()

extends Node
## Manages dual-world state and portal tracking
## Handles world switching and corruption proximity checks

var active_world: Enums.WorldType = Enums.WorldType.CORRUPTED
var portals: Dictionary = {}  # {tile_pos: {WorldType.CORRUPTED: bool, WorldType.HUMAN: bool}}


func switch_world(target_world: Enums.WorldType) -> void:
	if target_world == active_world:
		return
	active_world = target_world
	EventBus.world_switched.emit(active_world)


func register_portal(tile_pos: Vector2i, world: Enums.WorldType) -> void:
	if not portals.has(tile_pos):
		portals[tile_pos] = {Enums.WorldType.CORRUPTED: false, Enums.WorldType.HUMAN: false}
	portals[tile_pos][world] = true
	EventBus.portal_placed.emit(tile_pos, world)


func unregister_portal(tile_pos: Vector2i, world: Enums.WorldType) -> void:
	if portals.has(tile_pos):
		portals[tile_pos][world] = false
		# Clean up if no portals at this position
		if not portals[tile_pos][Enums.WorldType.CORRUPTED] and not portals[tile_pos][Enums.WorldType.HUMAN]:
			portals.erase(tile_pos)


func get_portals_in_world(world: Enums.WorldType) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for pos: Vector2i in portals.keys():
		if portals[pos][world]:
			result.append(pos)
	return result


func has_portal_at(tile_pos: Vector2i, world: Enums.WorldType) -> bool:
	return portals.has(tile_pos) and portals[tile_pos][world]


func is_portal_linked(tile_pos: Vector2i) -> bool:
	## Returns true if portal exists in both worlds at this position
	if not portals.has(tile_pos):
		return false
	return portals[tile_pos][Enums.WorldType.CORRUPTED] and portals[tile_pos][Enums.WorldType.HUMAN]


func can_corrupt_in_human_world(tile_pos: Vector2i) -> bool:
	## Corruption can only spread near portals in Human World
	for portal_pos: Vector2i in get_portals_in_world(Enums.WorldType.HUMAN):
		var distance := absi(tile_pos.x - portal_pos.x) + absi(tile_pos.y - portal_pos.y)
		if distance <= GameConstants.PORTAL_CORRUPTION_RADIUS:
			return true
	return false


func reset() -> void:
	active_world = Enums.WorldType.CORRUPTED
	portals.clear()

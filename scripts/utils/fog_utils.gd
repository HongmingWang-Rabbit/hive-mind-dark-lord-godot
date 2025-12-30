extends RefCounted
## Fog of war utility functions
## Use preload pattern: const FogUtils := preload("res://scripts/utils/fog_utils.gd")


static func get_tiles_in_sight_range(center: Vector2i, sight_range: int) -> Array[Vector2i]:
	## Returns array of tiles within circular (Euclidean) distance from center
	## Used by entities to report visible tiles for fog of war
	var tiles: Array[Vector2i] = []
	var range_squared := sight_range * sight_range

	for x in range(center.x - sight_range, center.x + sight_range + 1):
		for y in range(center.y - sight_range, center.y + sight_range + 1):
			var dx := x - center.x
			var dy := y - center.y
			if dx * dx + dy * dy <= range_squared:
				tiles.append(Vector2i(x, y))

	return tiles

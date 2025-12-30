extends RefCounted
## Tile atlas coordinates for the current tileset
## Use via preload: const Tiles := preload("res://scripts/data/tile_data.gd")
## Change this file to swap tilesets without touching game logic

# Tileset info
const TILE_SIZE := Vector2i(16, 16)
const ATLAS_COLUMNS := 12
const ATLAS_ROWS := 11

# Floors
const FLOOR_MAIN := Vector2i(0, 4)
const FLOOR_ALT := Vector2i(1, 4)
const FLOOR_VARIATION := Vector2i(2, 4)
const FLOORS: Array[Vector2i] = [FLOOR_MAIN, FLOOR_ALT, FLOOR_VARIATION]

# Walls (blue stone bricks)
const WALL := Vector2i(1, 3)
const WALL_LEFT := Vector2i(0, 3)
const WALL_RIGHT := Vector2i(2, 3)
const WALL_TOP := Vector2i(1, 3)
const WALL_TOP_LEFT := Vector2i(0, 3)
const WALL_TOP_RIGHT := Vector2i(2, 3)

# Props
const PROP_CRATE := Vector2i(0, 6)
const PROP_BARREL := Vector2i(1, 6)
const PROP_DOOR := Vector2i(3, 6)
const PROP_CHEST := Vector2i(6, 5)
const PROP_TOMBSTONE := Vector2i(4, 5)
const PROP_BARS := Vector2i(4, 6)
const PROPS: Array[Vector2i] = [PROP_BARREL, PROP_CRATE, PROP_CHEST]

# Characters - Minions
const CHAR_SKELETON := Vector2i(3, 7)
const CHAR_DEMON := Vector2i(2, 9)
const CHAR_GHOST := Vector2i(1, 10)
const CHAR_SLIME := Vector2i(0, 9)
const CHAR_BAT := Vector2i(0, 10)

# Characters - Humans
const CHAR_VILLAGER := Vector2i(1, 7)
const CHAR_VILLAGER_ALT := Vector2i(2, 7)
const CHAR_GUARD := Vector2i(4, 8)
const CHAR_KNIGHT := Vector2i(0, 8)
const CHAR_WIZARD := Vector2i(0, 7)

# Special
const CHAR_DARK_LORD := Vector2i(2, 9)


## Helper to get a random floor tile
static func get_random_floor() -> Vector2i:
	return FLOORS[randi_range(0, FLOORS.size() - 1)]


## Helper to get a random prop tile
static func get_random_prop() -> Vector2i:
	return PROPS[randi_range(0, PROPS.size() - 1)]

extends Node
## Game balance constants - tweak these for balancing
## All gameplay-affecting numbers should be here

#region Essence

const STARTING_ESSENCE := 100
const DARK_LORD_UPKEEP := 2

const ESSENCE_PER_TILE := 1
const ESSENCE_PER_KILL := 10
const ESSENCE_PER_POSSESS := 25

#endregion

#region Units

# Minion stats: {cost, upkeep, hp, damage, speed}
const MINION_STATS := {
	Enums.MinionType.CRAWLER: {cost = 20, upkeep = 1, hp = 10, damage = 2, speed = 60.0},
	Enums.MinionType.BRUTE: {cost = 50, upkeep = 2, hp = 30, damage = 5, speed = 30.0},
	Enums.MinionType.STALKER: {cost = 40, upkeep = 1, hp = 15, damage = 4, speed = 80.0},
}

#endregion

#region Buildings

const BUILDING_STATS := {
	Enums.BuildingType.CORRUPTION_NODE: {cost = 50, essence_bonus = 2},
	Enums.BuildingType.SPAWNING_PIT: {cost = 100, capacity = 5},
	Enums.BuildingType.PORTAL: {cost = 200, hp = 500},
}

#endregion

#region Win/Lose Conditions

const WIN_THRESHOLD := 0.8
const THREAT_THRESHOLDS: Array[float] = [0.2, 0.4, 0.6]

#endregion

#region Map Generation

const MAP_WIDTH := 30
const MAP_HEIGHT := 17
const MAP_EDGE_MARGIN := 1

# TileMap source ID (atlas index in tileset)
const TILEMAP_SOURCE_ID := 0

# Building generation
const BUILDING_COUNT_MIN := 5
const BUILDING_COUNT_MAX := 10
const BUILDING_SIZE_MIN := Vector2i(2, 2)
const BUILDING_SIZE_MAX := Vector2i(6, 4)
const BUILDING_PADDING := 1
const BUILDING_PLACEMENT_ATTEMPTS := 10

# Floor generation weights (relative, total calculated dynamically)
const FLOOR_WEIGHT_MAIN := 70
const FLOOR_WEIGHT_ALT := 20
const FLOOR_WEIGHT_VARIATION := 10

# Props
const PROP_COUNT := 15
const PROP_SCATTER_ATTEMPTS_MULTIPLIER := 5

#endregion

#region Display

const VIEWPORT_WIDTH := 480
const VIEWPORT_HEIGHT := 270
const CAMERA_CENTER := Vector2(VIEWPORT_WIDTH / 2.0, VIEWPORT_HEIGHT / 2.0)

#endregion

#region Camera

const TILE_SIZE := 16
const CAMERA_PAN_SPEED := 200.0
const CAMERA_EDGE_PADDING := 32  # Pixels of padding beyond map edges

#endregion

#region Corruption Visual

const CORRUPTION_COLOR := Color(0.6, 0.2, 0.8, 0.7)

#endregion

#region Directions

const ORTHOGONAL_DIRS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0),
	Vector2i(0, 1), Vector2i(0, -1)
]

const ALL_DIRS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0),
	Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(-1, -1),
	Vector2i(1, -1), Vector2i(-1, 1)
]

#endregion

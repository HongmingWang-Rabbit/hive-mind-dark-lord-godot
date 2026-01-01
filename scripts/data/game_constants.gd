extends Node
## Game balance constants - tweak these for balancing
## All gameplay-affecting numbers should be here

#region Essence

const STARTING_ESSENCE := 100
const DARK_LORD_UPKEEP := 2

const ESSENCE_PER_TILE := 1
const ESSENCE_PER_KILL := 10
const ESSENCE_PER_POSSESS := 25

# Entity rewards
const ESSENCE_PER_CIVILIAN := 10
const ESSENCE_PER_ANIMAL := 5

#endregion

#region Human World Entities

const CIVILIAN_COUNT := 10
const ANIMAL_COUNT := 8
const ENTITY_SPAWN_ATTEMPTS := 50  # Max attempts to find valid spawn position

#endregion

#region Entity Groups

const GROUP_DARK_LORD := "dark_lord"
const GROUP_CIVILIANS := "civilians"
const GROUP_ANIMALS := "animals"
const GROUP_KILLABLE := "killable"
const GROUP_MINIONS := "minions"
const GROUP_THREATS := "threats"  # Dark Lord + minions - entities that civilians flee from

#endregion

#region Combat - Dark Lord

const DARK_LORD_HP := 100
const DARK_LORD_DAMAGE := 10
const DARK_LORD_ATTACK_RANGE := 16.0  # Pixels (1 tile = 16)
const DARK_LORD_ATTACK_COOLDOWN := 0.5  # Seconds between attacks

#endregion

#region Combat - Entities

const CIVILIAN_HP := 10
const ANIMAL_HP := 10

#endregion

#region Combat - Enemies

const POLICE_HP := 20
const POLICE_DAMAGE := 5
const POLICE_SPEED := 40.0

const MILITARY_HP := 40
const MILITARY_DAMAGE := 10
const MILITARY_SPEED := 35.0

const HEAVY_HP := 80
const HEAVY_DAMAGE := 20
const HEAVY_SPEED := 25.0

const SPECIAL_FORCES_HP := 50
const SPECIAL_FORCES_DAMAGE := 15
const SPECIAL_FORCES_SPEED := 45.0

#endregion

#region Enemy Spawning

const POLICE_SPAWN_INTERVAL := 10.0  # Seconds between spawns
const MILITARY_SPAWN_INTERVAL := 8.0
const HEAVY_SPAWN_INTERVAL := 15.0

const MAX_POLICE := 5
const MAX_MILITARY := 3
const MAX_HEAVY := 2
const MAX_SPECIAL_FORCES := 2

const ENEMY_SPAWN_MARGIN := 2  # Tiles from map edge to spawn

#endregion

#region Entity Groups - Enemies

const GROUP_ENEMIES := "enemies"
const GROUP_POLICE := "police"
const GROUP_MILITARY := "military"
const GROUP_HEAVY := "heavy"
const GROUP_SPECIAL_FORCES := "special_forces"

#endregion

#region Entity Groups - Buildings

const GROUP_BUILDINGS := "buildings"
const GROUP_PORTALS := "portals"
const GROUP_CORRUPTION_NODES := "corruption_nodes"
const GROUP_SPAWNING_PITS := "spawning_pits"

#endregion

#region World Collision Layers
## Each world uses separate collision layers so entities don't collide across worlds
## Layer 1: Shared (walls, structures from tilemap)
## Layer 2: Threats detection (Dark Lord, minions - for flee behavior)
## Layer 4: Corrupted World physics
## Layer 5: Human World physics

const COLLISION_LAYER_CORRUPTED_WORLD := 4
const COLLISION_LAYER_HUMAN_WORLD := 5

# Combined masks for entities that need to collide with world geometry + their world's entities
const COLLISION_MASK_CORRUPTED_WORLD := 1 | (1 << (COLLISION_LAYER_CORRUPTED_WORLD - 1))  # Layers 1 + 4
const COLLISION_MASK_HUMAN_WORLD := 1 | (1 << (COLLISION_LAYER_HUMAN_WORLD - 1))  # Layers 1 + 5

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
	# Portal stats in PortalData.gd (entity-specific data pattern)
}

#endregion

#region Corruption Spread

const CORRUPTION_SPREAD_INTERVAL := 2.0  # Seconds between corruption spread ticks
const CORRUPTION_NODE_RANGE := 5  # Max tiles from node that corruption can spread
const PORTAL_INITIAL_CORRUPTION_RANGE := 1  # Tiles of corruption created in Human World around portal

#endregion

#region Win/Lose Conditions

const WIN_THRESHOLD := 0.8
const THREAT_THRESHOLDS: Array[float] = [0.2, 0.4, 0.6]

#endregion

#region Map Generation

const MAP_WIDTH := 50
const MAP_HEIGHT := 30
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
const CAMERA_EDGE_PADDING := 32  # Pixels beyond map edges camera can see
const CAMERA_DRAG_BUTTONS: Array[MouseButton] = [MOUSE_BUTTON_MIDDLE]  # Left-click used for actions

# Keyboard pan keys (physical key codes for consistent layout across keyboard types)
const CAMERA_PAN_LEFT_KEYS: Array[Key] = [KEY_A]
const CAMERA_PAN_RIGHT_KEYS: Array[Key] = [KEY_D]
const CAMERA_PAN_UP_KEYS: Array[Key] = [KEY_W]
const CAMERA_PAN_DOWN_KEYS: Array[Key] = [KEY_S]

#endregion

#region Input Keys (Debug/Gameplay)

const KEY_PLACE_PORTAL: Key = KEY_P
const KEY_SWITCH_WORLD: Key = KEY_TAB  # Debug only

# Minion spawning hotkeys
const KEY_SPAWN_CRAWLER: Key = KEY_1
const KEY_SPAWN_BRUTE: Key = KEY_2
const KEY_SPAWN_STALKER: Key = KEY_3

#endregion

#region Corruption Visual

const CORRUPTION_COLOR := Color(0.6, 0.2, 0.8, 0.7)

#endregion

#region Cursor Preview

const CURSOR_PREVIEW_COLOR := Color(1.0, 1.0, 1.0, 0.7)  # Semi-transparent white
const CURSOR_PREVIEW_Z_INDEX := 50  # Above world, below UI

# Order cursor (attack/defend targeting)
const ORDER_CURSOR_COLOR := Color(1.0, 0.3, 0.3, 0.8)  # Red for attack orders
const ORDER_CURSOR_DEFEND_COLOR := Color(0.3, 0.5, 1.0, 0.8)  # Blue for defend orders
const ORDER_CURSOR_SCOUT_COLOR := Color(0.3, 1.0, 0.5, 0.8)  # Green for scout orders
const ORDER_CURSOR_SIZE := 12.0  # Diameter of order cursor circle

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

#region Fog of War

const FOG_ENABLED := true
const FOG_COLOR := Color(0.0, 0.0, 0.0, 0.95)  # Unexplored fog color
const INITIAL_CORRUPTION_REVEAL_RADIUS := 3    # Tiles revealed at start around spawn

#endregion

#region Dual World

# World visual theming
const HUMAN_WORLD_TINT := Color(1.0, 1.0, 1.0, 1.0)
const CORRUPTED_WORLD_TINT := Color(0.4, 0.2, 0.5, 1.0)

# Corrupted world atmosphere particles
const CORRUPTED_PARTICLES_AMOUNT := 50
const CORRUPTED_PARTICLES_LIFETIME := 3.0
const CORRUPTED_PARTICLES_COLOR := Color(0.6, 0.2, 0.8, 0.5)
const CORRUPTED_PARTICLES_DIRECTION := Vector3(0, -1, 0)  # Downward falling
const CORRUPTED_PARTICLES_SPREAD := 45.0
const CORRUPTED_PARTICLES_GRAVITY := Vector3(0, 10, 0)
const CORRUPTED_PARTICLES_VELOCITY_MIN := 5.0
const CORRUPTED_PARTICLES_VELOCITY_MAX := 15.0
const CORRUPTED_PARTICLES_SCALE_MIN := 0.3
const CORRUPTED_PARTICLES_SCALE_MAX := 0.6
const CORRUPTED_PARTICLES_TEXTURE_SIZE := 8  # Pixel size of particle texture

# Portal configuration
const PORTAL_CORRUPTION_RADIUS := 5
const PORTAL_TRAVEL_COOLDOWN := 1.0

#endregion

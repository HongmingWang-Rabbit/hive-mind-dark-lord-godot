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
const ESSENCE_PER_POLICEMAN := 15

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
const GROUP_POLICEMEN := "policemen"
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
const POLICEMAN_HP := 25
const POLICEMAN_DAMAGE := 5

#endregion

#region Combat - Enemies

# Enemy stats: {hp, damage, speed, group}
const ENEMY_STATS := {
	Enums.EnemyType.SWAT: {hp = 20, damage = 5, speed = 40.0, group = "swat"},
	Enums.EnemyType.MILITARY: {hp = 40, damage = 10, speed = 35.0, group = "military"},
	Enums.EnemyType.HEAVY: {hp = 80, damage = 20, speed = 25.0, group = "heavy"},
	Enums.EnemyType.SPECIAL_FORCES: {hp = 50, damage = 15, speed = 45.0, group = "special_forces"},
	Enums.EnemyType.PSYCHIC: {hp = 15, damage = 8, speed = 50.0, group = "psychic"},
}

#endregion

#region Enemy Spawning

const SWAT_SPAWN_INTERVAL := 10.0  # Seconds between spawns
const MILITARY_SPAWN_INTERVAL := 8.0
const HEAVY_SPAWN_INTERVAL := 15.0
const PSYCHIC_SPAWN_INTERVAL := 12.0

const MAX_SWAT := 5
const MAX_MILITARY := 3
const MAX_HEAVY := 2
const MAX_SPECIAL_FORCES := 2
const MAX_PSYCHIC := 2

const ENEMY_SPAWN_MARGIN := 2  # Tiles from map edge to spawn

# Random spawning (always active, independent of threat level)
const RANDOM_ENEMY_SPAWN_ENABLED := true
const RANDOM_ENEMY_SPAWN_INTERVAL := 15.0  # Seconds between random spawns
const RANDOM_ENEMY_MAX := 6  # Max random enemies at once

# Random enemy type weights (cumulative thresholds out of 100)
const RANDOM_ENEMY_MILITARY_THRESHOLD := 50  # 0-49 = Military (50%)
const RANDOM_ENEMY_SWAT_THRESHOLD := 80    # 50-79 = SWAT (30%)
# 80-99 = Heavy (20%)

#endregion

#region Entity Groups - Enemies

const GROUP_ENEMIES := "enemies"
const GROUP_SWAT := "swat"
const GROUP_MILITARY := "military"
const GROUP_HEAVY := "heavy"
const GROUP_SPECIAL_FORCES := "special_forces"
const GROUP_PSYCHIC := "psychic"

#endregion

#region Entity Groups - Buildings

const GROUP_BUILDINGS := "buildings"
const GROUP_PORTALS := "portals"
const GROUP_CORRUPTION_NODES := "corruption_nodes"
const GROUP_SPAWNING_PITS := "spawning_pits"
const GROUP_ALARM_TOWERS := "alarm_towers"      # Human defense structures
const GROUP_POLICE_STATIONS := "police_stations"  # Human defense structures
const GROUP_MILITARY_PORTALS := "military_portals"  # Human military portals

#endregion

#region Alarm Towers (Human Defense)

const ALARM_TOWER_COUNT := 3  # Number of alarm towers to spawn on map
const ALARM_ENEMY_ATTRACT_RADIUS := 128.0  # Pixels - enemies within this range move toward alarm

#endregion

#region Police Stations (Human Defense)

const POLICE_STATION_COUNT := 2  # Number of police stations to spawn on map
const MAX_POLICEMEN_PER_STATION := 5  # Max policemen each station can maintain
const POLICE_STATION_SPAWN_INTERVAL := 5.0  # Seconds between policeman spawn attempts

#endregion

#region Military Portals (Human Defense)

const MILITARY_PORTAL_THREAT_THRESHOLD := 0.7  # Threat level (70%) to start spawning portals
const MILITARY_PORTAL_SPAWN_INTERVAL := 30.0   # Seconds between portal spawns
const MILITARY_PORTAL_MAX_COUNT := 3           # Max military portals on map

#endregion

#region World Collision Layers
## Each world uses separate collision layers so entities don't collide across worlds
## Layer 1: Shared (walls, structures from tilemap)
## Layer 2: Threats detection (Dark Lord, minions - for flee behavior)
## Layer 4: Corrupted World physics
## Layer 5: Human World physics

const COLLISION_LAYER_WALLS := 1
const COLLISION_LAYER_THREATS := 2
const COLLISION_LAYER_CORRUPTED_WORLD := 4
const COLLISION_LAYER_HUMAN_WORLD := 5

# Masks
const COLLISION_MASK_WALLS := 1 << (COLLISION_LAYER_WALLS - 1)  # Layer 1 only
const COLLISION_MASK_THREATS := 1 << (COLLISION_LAYER_THREATS - 1)  # Layer 2 only

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
	Enums.BuildingType.CORRUPTION_NODE: {cost = 50, essence_bonus = 2, hp = 50},
	Enums.BuildingType.SPAWNING_PIT: {cost = 100, capacity = 5, hp = 80},
	Enums.BuildingType.PORTAL: {hp = 100},
	# Portal cost in PortalData.gd (entity-specific data pattern)
}

#endregion

#region Corruption Spread

const CORRUPTION_SPREAD_INTERVAL := 2.0  # Seconds between corruption spread ticks
const CORRUPTION_NODE_RANGE := 5  # Max tiles from node that corruption can spread
const PORTAL_INITIAL_CORRUPTION_RANGE := 1  # Tiles of corruption created in Human World around portal

#endregion

#region Win/Lose Conditions

const WIN_THRESHOLD := 0.8

#endregion

#region Threat System

# Float-based threat thresholds for enum conversion
# 0.0-0.25 = NONE, 0.25-0.5 = SWAT, 0.5-0.75 = MILITARY, 0.75-1.0 = HEAVY
const THREAT_LEVEL_THRESHOLDS: Array[float] = [0.25, 0.5, 0.75]

# Corruption to threat scaling (linear from min to max)
const THREAT_CORRUPTION_MIN := 0.2   # Below 20% corruption = 0.0 threat
const THREAT_CORRUPTION_MAX := 0.8   # Above 80% corruption = 1.0 threat

# Threat floors (one-time events that set minimum threat)
const THREAT_MILITARY_SIGHTING_FLOOR := 0.5  # Military spots Dark Lord
const THREAT_ALARM_TOWER_FLOOR := 0.5        # Alarm tower triggered

# Source IDs (for consistency)
const THREAT_SOURCE_CORRUPTION := "corruption"
const THREAT_SOURCE_MILITARY_SIGHTING := "military_sighting"
const THREAT_SOURCE_ALARM_TOWER := "alarm_tower"

# Enemy types that report Dark Lord sightings (triggers military sighting threat)
const THREAT_REPORTING_ENEMY_TYPES: Array[Enums.EnemyType] = [
	Enums.EnemyType.MILITARY,
	Enums.EnemyType.HEAVY,
	Enums.EnemyType.SPECIAL_FORCES,
]

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

#region Spatial Grid (performance optimization)

const SPATIAL_GRID_CELL_SIZE := 32.0  # Should be >= separation distance for efficiency
const SPATIAL_GRID_CLEANUP_INTERVAL := 1.0  # Seconds between dead entity cleanup

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

# Zoom (scroll wheel)
const CAMERA_ZOOM_MIN := 0.5  # Zoomed out (see more)
const CAMERA_ZOOM_MAX := 2.0  # Zoomed in (see less)
const CAMERA_ZOOM_STEP := 0.1  # Zoom change per scroll tick

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

#region Health Bar

const HEALTH_BAR_WIDTH := 12.0  # Pixels wide
const HEALTH_BAR_HEIGHT := 2.0  # Pixels tall
const HEALTH_BAR_OFFSET_Y := -10.0  # Pixels above entity center
const HEALTH_BAR_BORDER_WIDTH := 1.0  # Pixels of border around bar
const HEALTH_BAR_BG_COLOR := Color(0.2, 0.2, 0.2, 0.8)  # Dark background
const HEALTH_BAR_BORDER_COLOR := Color(0.0, 0.0, 0.0, 0.9)  # Black border

# Health thresholds and colors
const HEALTH_BAR_HIGH_THRESHOLD := 0.6  # Above this = green
const HEALTH_BAR_LOW_THRESHOLD := 0.3  # Below this = red, between = yellow
const HEALTH_BAR_HIGH_COLOR := Color(0.2, 0.8, 0.2, 1.0)  # Green
const HEALTH_BAR_MED_COLOR := Color(0.9, 0.8, 0.1, 1.0)  # Yellow
const HEALTH_BAR_LOW_COLOR := Color(0.9, 0.2, 0.2, 1.0)  # Red

#endregion

#region Cursor Preview

const CURSOR_PREVIEW_COLOR := Color(1.0, 1.0, 1.0, 0.7)  # Semi-transparent white
const CURSOR_PREVIEW_Z_INDEX := 50  # Above world, below UI

# Order cursor (attack/defend targeting)
const ORDER_CURSOR_COLOR := Color(1.0, 0.3, 0.3, 0.8)  # Red for attack orders
const ORDER_CURSOR_DEFEND_COLOR := Color(0.3, 0.5, 1.0, 0.8)  # Blue for defend orders
const ORDER_CURSOR_SCOUT_COLOR := Color(0.3, 1.0, 0.5, 0.8)  # Green for scout orders
const ORDER_CURSOR_SIZE := 12.0  # Diameter of order cursor circle
const ORDER_CURSOR_RING_WIDTH := 2.0  # Width of the ring outline
const ORDER_CURSOR_CENTER_ALPHA := 0.3  # Alpha of the center fill

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

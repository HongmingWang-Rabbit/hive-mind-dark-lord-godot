# Constants Reference

## Enums Reference

```gdscript
# Game flow
Enums.GameState {MENU, PLAYING, PAUSED, WON, LOST}

# Units - Player
Enums.MinionType {CRAWLER, BRUTE, STALKER}
Enums.MinionAssignment {IDLE, ATTACKING, DEFENDING}
Enums.Stance {AGGRESSIVE, HOLD, RETREAT}

# Interaction
Enums.InteractionMode {NONE, BUILD, ORDER}

# Units - Human World
Enums.HumanType {CIVILIAN, ANIMAL, POLICE, MILITARY, HEAVY, SPECIAL}

# Units - Special Forces (invade Dark World)
Enums.SpecialForcesType {SCOUT, CLEANSER, STRIKE_TEAM}

# World
Enums.BuildingType {CORRUPTION_NODE, SPAWNING_PIT, PORTAL, MILITARY_PORTAL}
Enums.ThreatLevel {NONE, POLICE, MILITARY, HEAVY}
Enums.TileType {FLOOR, WALL, PROP, EMPTY}
Enums.WorldType {CORRUPTED, HUMAN}

# Portal ownership
Enums.PortalOwner {DARK_LORD, MILITARY}
```

## GameConstants Reference

```gdscript
#region Essence
STARTING_ESSENCE        # Initial essence amount
DARK_LORD_UPKEEP        # Passive drain rate
ESSENCE_PER_TILE        # Income per corrupted tile
ESSENCE_PER_KILL        # Bonus for kills
ESSENCE_PER_POSSESS     # Bonus for possession
ESSENCE_PER_CIVILIAN    # +10 - reward for killing civilians
ESSENCE_PER_ANIMAL      # +5 - reward for killing animals

#region Human World Entities
CIVILIAN_COUNT          # Number of civilians to spawn (10)
ANIMAL_COUNT            # Number of animals to spawn (8)
ENTITY_SPAWN_ATTEMPTS   # Max attempts to find valid spawn position (50)

#region Entity Groups (use for add_to_group/is_in_group)
GROUP_DARK_LORD         # "dark_lord"
GROUP_CIVILIANS         # "civilians"
GROUP_ANIMALS           # "animals"
GROUP_KILLABLE          # "killable" - entities Dark Lord can attack
GROUP_MINIONS           # "minions"
GROUP_THREATS           # "threats" - Dark Lord + minions (civilians flee from)
GROUP_ENEMIES           # "enemies" - police, military, etc.
GROUP_POLICE            # "police"
GROUP_MILITARY          # "military"
GROUP_HEAVY             # "heavy"
GROUP_SPECIAL_FORCES    # "special_forces"
GROUP_BUILDINGS         # "buildings" - all player buildings
GROUP_PORTALS           # "portals"
GROUP_CORRUPTION_NODES  # "corruption_nodes"
GROUP_SPAWNING_PITS     # "spawning_pits"

#region Combat - Dark Lord
DARK_LORD_HP            # 100 - Dark Lord max health
DARK_LORD_DAMAGE        # 10 - damage per attack
DARK_LORD_ATTACK_RANGE  # 16.0 pixels (1 tile)
DARK_LORD_ATTACK_COOLDOWN # 0.5s between attacks

#region Combat - Entities
CIVILIAN_HP             # 10 - keep synced with CivilianData.HP
ANIMAL_HP               # 10 - keep synced with AnimalData.HP

#region Units
MINION_STATS[MinionType] = {cost, upkeep, hp, damage, speed}

#region Buildings
BUILDING_STATS[BuildingType] = {cost, ...}  # Portal uses PortalData.gd instead

#region Corruption Spread
CORRUPTION_SPREAD_INTERVAL      # Seconds between node spread ticks (2.0)
CORRUPTION_NODE_RANGE           # Max tiles from node for spreading (5)
PORTAL_INITIAL_CORRUPTION_RANGE # Corruption radius in Human World (1)

#region Win/Lose
WIN_THRESHOLD           # Corruption % to win (0.8 = 80% Human World)

#region Threat System (modular, float-based 0.0-1.0)
THREAT_LEVEL_THRESHOLDS          # [0.25, 0.5, 0.75] → POLICE, MILITARY, HEAVY
THREAT_CORRUPTION_MIN            # 0.2 - corruption % where threat starts
THREAT_CORRUPTION_MAX            # 0.8 - corruption % where threat maxes out
THREAT_MILITARY_SIGHTING_FLOOR   # 0.5 - floor when military spots Dark Lord
THREAT_ALARM_TOWER_FLOOR         # 0.5 - floor when alarm triggered
THREAT_SOURCE_CORRUPTION         # "corruption" - source ID
THREAT_SOURCE_MILITARY_SIGHTING  # "military_sighting" - source ID
THREAT_SOURCE_ALARM_TOWER        # "alarm_tower" - source ID
THREAT_REPORTING_ENEMY_TYPES     # [MILITARY, HEAVY, SPECIAL_FORCES] - types that report sightings

#region Map Generation
MAP_WIDTH, MAP_HEIGHT   # Default map dimensions
MAP_EDGE_MARGIN         # Min distance from map edge
TILEMAP_SOURCE_ID       # Atlas source index (0)

BUILDING_COUNT_MIN/MAX  # Building count range
BUILDING_SIZE_MIN/MAX   # Building size range (Vector2i)
BUILDING_PADDING        # Min space between buildings
BUILDING_PLACEMENT_ATTEMPTS  # Retries per building

FLOOR_WEIGHT_MAIN       # Main tile probability
FLOOR_WEIGHT_ALT        # Alt tile probability
FLOOR_WEIGHT_VARIATION  # Variation tile probability

PROP_COUNT              # Number of props to place
PROP_SCATTER_ATTEMPTS_MULTIPLIER  # Max attempts = count * this

#region Display
VIEWPORT_WIDTH          # Game viewport width (480)
VIEWPORT_HEIGHT         # Game viewport height (270)
CAMERA_CENTER           # Camera center position (Vector2)

#region Camera
TILE_SIZE               # Tile size in pixels (16)
CAMERA_PAN_SPEED        # Camera movement speed (200.0)
CAMERA_EDGE_PADDING     # Pixels beyond map edges camera can see (32)
CAMERA_DRAG_BUTTONS     # [MouseButton] - buttons that trigger camera drag
CAMERA_PAN_LEFT_KEYS    # [Key] - keys for panning left (default: [KEY_A])
CAMERA_PAN_RIGHT_KEYS   # [Key] - keys for panning right (default: [KEY_D])
CAMERA_PAN_UP_KEYS      # [Key] - keys for panning up (default: [KEY_W])
CAMERA_PAN_DOWN_KEYS    # [Key] - keys for panning down (default: [KEY_S])
CAMERA_ZOOM_MIN         # float - minimum zoom level (0.5 = zoomed out)
CAMERA_ZOOM_MAX         # float - maximum zoom level (2.0 = zoomed in)
CAMERA_ZOOM_STEP        # float - zoom change per scroll tick (0.1)

#region Input Keys
KEY_PLACE_PORTAL        # Key for placing portals (KEY_P)
KEY_SWITCH_WORLD        # Key for debug world switching (KEY_TAB)

#region Corruption Visual
CORRUPTION_COLOR        # Color for corruption overlay

#region Cursor Preview
CURSOR_PREVIEW_COLOR    # Color(1.0, 1.0, 1.0, 0.7) - semi-transparent preview
CURSOR_PREVIEW_Z_INDEX  # 50 - above world, below UI
ORDER_CURSOR_COLOR      # Color(1.0, 0.3, 0.3, 0.8) - red for attack orders
ORDER_CURSOR_DEFEND_COLOR  # Color(0.3, 0.5, 1.0, 0.8) - blue for defend
ORDER_CURSOR_SCOUT_COLOR   # Color(0.3, 1.0, 0.5, 0.8) - green for scout
ORDER_CURSOR_SIZE       # 12.0 - diameter of order cursor circle

#region Directions
ORTHOGONAL_DIRS         # [Vector2i] - 4 cardinal directions
ALL_DIRS                # [Vector2i] - 8 directions including diagonals

#region Dual World
HUMAN_WORLD_TINT        # Color(1.0, 1.0, 1.0, 1.0) - normal colors
CORRUPTED_WORLD_TINT    # Color(0.4, 0.2, 0.5, 1.0) - dark purple
CORRUPTED_PARTICLES_AMOUNT    # 50 - atmosphere particles
CORRUPTED_PARTICLES_LIFETIME  # 3.0s
CORRUPTED_PARTICLES_COLOR     # Purple particle color
CORRUPTED_PARTICLES_DIRECTION # Vector3(0, -1, 0) - downward falling
CORRUPTED_PARTICLES_SPREAD    # 45.0 - particle spread angle
CORRUPTED_PARTICLES_GRAVITY   # Vector3(0, 10, 0)
CORRUPTED_PARTICLES_VELOCITY_MIN/MAX  # 5.0 / 15.0
CORRUPTED_PARTICLES_SCALE_MIN/MAX     # 0.3 / 0.6
CORRUPTED_PARTICLES_TEXTURE_SIZE      # 8 - pixel size of radial gradient texture
PORTAL_CORRUPTION_RADIUS     # 5 tiles - corruption spread range from portals
PORTAL_TRAVEL_COOLDOWN       # 1.0s - delay between world switches

#region Fog of War
FOG_ENABLED                  # true - toggle fog system
FOG_COLOR                    # Color(0, 0, 0, 0.95) - unexplored fog opacity
INITIAL_CORRUPTION_REVEAL_RADIUS  # 3 tiles - starting revealed area

#region World Collision Layers
## Each world uses separate collision layers so entities don't collide across worlds
COLLISION_LAYER_WALLS            # 1 - shared walls/structures
COLLISION_LAYER_THREATS          # 2 - Dark Lord + minions (flee behavior detection)
COLLISION_LAYER_CORRUPTED_WORLD  # 4 - physics for Corrupted World entities
COLLISION_LAYER_HUMAN_WORLD      # 5 - physics for Human World entities

COLLISION_MASK_WALLS             # Layer 1 only - for friendly units that don't block each other
COLLISION_MASK_THREATS           # Layer 2 only - for enemy detection areas
COLLISION_MASK_CORRUPTED_WORLD   # 1 + 4 - walls + Corrupted World
COLLISION_MASK_HUMAN_WORLD       # 1 + 5 - walls + Human World

#region Spatial Grid (performance optimization)
SPATIAL_GRID_CELL_SIZE           # 32.0 - grid cell size (>= separation distance)
SPATIAL_GRID_CLEANUP_INTERVAL    # 1.0s - dead entity cleanup frequency

#region Health Bar (visual feedback)
HEALTH_BAR_WIDTH                 # 12.0 - pixels wide
HEALTH_BAR_HEIGHT                # 2.0 - pixels tall
HEALTH_BAR_OFFSET_Y              # -10.0 - pixels above entity center
HEALTH_BAR_BORDER_WIDTH          # 1.0 - border thickness
HEALTH_BAR_BG_COLOR              # Dark background color
HEALTH_BAR_BORDER_COLOR          # Black border color
HEALTH_BAR_HIGH_THRESHOLD        # 0.6 - above this = green
HEALTH_BAR_LOW_THRESHOLD         # 0.3 - below this = red, between = yellow
HEALTH_BAR_HIGH_COLOR            # Green (healthy)
HEALTH_BAR_MED_COLOR             # Yellow (damaged)
HEALTH_BAR_LOW_COLOR             # Red (critical)
```

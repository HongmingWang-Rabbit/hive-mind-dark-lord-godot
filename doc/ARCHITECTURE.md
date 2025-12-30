# Technical Architecture

## Autoload Dependency Graph

```
Enums (no deps)
    ↓
GameConstants (uses Enums)
    ↓
EventBus (no deps)
    ↓
WorldManager (uses Enums, GameConstants, EventBus)
    ↓
Essence (uses GameConstants)
    ↓
HivePool (uses Enums, GameConstants, Essence)
    ↓
GameManager (uses all above, including WorldManager)
```

## Data Scripts

### TileData (preload, not autoload)
Tile atlas coordinates for the current tileset. Uses preload pattern for reliable
constant access at parse time. Change this file to swap tilesets.

```gdscript
# At top of script that needs tile data:
const Tiles := preload("res://scripts/data/tile_data.gd")

# Then use via the const:
var floor_tile := Tiles.FLOOR_MAIN
var skeleton := Tiles.CHAR_SKELETON
var random_prop := Tiles.get_random_prop()
```

**Why preload instead of autoload?**
- Constants available at parse time (no runtime dependency issues)
- Explicit dependency declaration in each file that uses it
- Avoids Godot editor caching issues with class_name + autoload

## Enums Reference

```gdscript
# Game flow
Enums.GameState {MENU, PLAYING, PAUSED, WON, LOST}

# Units
Enums.MinionType {CRAWLER, BRUTE, STALKER}
Enums.MinionAssignment {IDLE, ATTACKING, DEFENDING}
Enums.Stance {AGGRESSIVE, HOLD, RETREAT}

# World
Enums.BuildingType {CORRUPTION_NODE, SPAWNING_PIT, PORTAL}
Enums.ThreatLevel {NONE, POLICE, MILITARY, HEAVY}
Enums.TileType {FLOOR, WALL, PROP, EMPTY}
Enums.WorldType {CORRUPTED, HUMAN}
```

## EventBus Signals

```gdscript
# Corruption
signal tile_corrupted(tile_pos: Vector2i)
signal corruption_changed(new_percent: float)

# Combat
signal human_killed(position: Vector2)
signal human_possessed(position: Vector2)
signal enemy_spotted(position: Vector2, threat_type: int)

# Buildings
signal building_placed(building_type: Enums.BuildingType, position: Vector2)
signal building_destroyed(building_type: Enums.BuildingType, position: Vector2)

# Commands
signal attack_ordered(target_pos: Vector2, minion_percent: float, stance: Enums.Stance)
signal retreat_ordered()

# Game State
signal threat_level_changed(new_level: Enums.ThreatLevel)
signal game_won()
signal game_lost()

# World Dimension
signal world_switched(new_world: Enums.WorldType)
signal portal_placed(tile_pos: Vector2i, world: Enums.WorldType)
signal portal_activated(tile_pos: Vector2i)
signal corruption_cleared(tile_pos: Vector2i)
```

## GameConstants Reference

```gdscript
#region Essence
STARTING_ESSENCE        # Initial essence amount
DARK_LORD_UPKEEP        # Passive drain rate
ESSENCE_PER_TILE        # Income per corrupted tile
ESSENCE_PER_KILL        # Bonus for kills
ESSENCE_PER_POSSESS     # Bonus for possession

#region Units
MINION_STATS[MinionType] = {cost, upkeep, hp, damage, speed}

#region Buildings
BUILDING_STATS[BuildingType] = {cost, ...}  # Portal uses PortalData.gd instead

#region Win/Lose
WIN_THRESHOLD           # Corruption % to win (0.8)
THREAT_THRESHOLDS       # Array of corruption % triggers

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

#region Input Keys
KEY_PLACE_PORTAL        # Key for placing portals (KEY_P)
KEY_SWITCH_WORLD        # Key for debug world switching (KEY_TAB)

#region Corruption Visual
CORRUPTION_COLOR        # Color for corruption overlay

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
```

## Scene Tree (main.tscn)

```
Main (World.gd)
├── HumanWorld [Node2D] - Normal world, corruption spreads near portals
│   ├── FloorMap [TileMapLayer]
│   ├── StructureMap [TileMapLayer]
│   ├── CorruptionMap [TileMapLayer]
│   └── Entities [Node2D] - Entities in Human World
├── CorruptedWorld [Node2D] - Dark world, fully corrupted, particles
│   ├── FloorMap [TileMapLayer]
│   ├── StructureMap [TileMapLayer]
│   ├── CorruptionMap [TileMapLayer]
│   ├── Entities [Node2D] - Entities in Corrupted World (Dark Lord spawns here)
│   └── AtmosphereParticles [GPUParticles2D]
├── UI [CanvasLayer]
│   └── HUD (HUDController.gd)
│       ├── TopBar [HBoxContainer]
│       │   ├── EssenceLabel
│       │   ├── CorruptionLabel
│       │   ├── ThreatLabel
│       │   └── WorldButton
│       ├── SidePanel [VBoxContainer]
│       └── ContextPanel
└── Camera2D (CameraController.gd)
```

Both worlds have identical terrain layout but **separate entities**. Each world has its own Entities container. Entities exist in exactly one world at a time and must travel through portals to move between worlds. Only one world is visible at a time (view toggle), but entities remain in their world.

## HUDController.gd

Manages UI elements and player interactions.

### Features
- **Essence display**: Updates when `Essence.essence_changed` fires
- **Corruption display**: Updates when `EventBus.corruption_changed` fires
- **Threat display**: Updates when `EventBus.threat_level_changed` fires
- **World switch button**: Toggles visibility between Corrupted/Human world (view only, does not move entities)

### UI Text Constants
```gdscript
WORLD_BUTTON_CORRUPTED  # "View: Corrupted"
WORLD_BUTTON_HUMAN      # "View: Human"
ESSENCE_FORMAT          # "Essence: %d"
CORRUPTION_FORMAT       # "Corruption: %d%%"
THREAT_FORMAT           # "Threat: %s"
THREAT_LEVEL_NAMES      # ["None", "Police", "Military", "Heavy"]
```

### Connected Signals
```gdscript
EventBus.corruption_changed
EventBus.threat_level_changed
EventBus.world_switched
Essence.essence_changed
```

## System Reset Flow

```gdscript
GameManager.reset_game()  # Resets all systems
    → Essence.reset()     # Reset to STARTING_ESSENCE
    → HivePool.reset()    # Clear all minion pools
    → WorldManager.reset() # Reset to CORRUPTED world, clear portals
```

## CameraController.gd

Standalone camera script attached to Camera2D node. Handles all camera movement.

### Features
- **Keyboard pan**: Arrow keys (built-in) + configurable keys (default: WASD)
- **Mouse drag**: Configurable buttons (default: left/middle)
- **Touch drag**: Single finger drag support
- **Bounds clamping**: Prevents camera from leaving map area
- **Fully configurable**: All inputs defined in GameConstants

### Public API
```gdscript
set_map_bounds(map_width: int, map_height: int)  # Configure bounds after map generation
center_on_tile(tile_pos: Vector2i)               # Center camera on a tile position
```

### Swapping Camera System
To replace with a different camera:
1. Create new script extending Camera2D
2. Implement `set_map_bounds()` and `center_on_tile()` methods
3. Attach to Camera2D node in main.tscn

## WorldManager.gd

Autoload that manages dual-world state and portal tracking.

### Public API
```gdscript
var active_world: Enums.WorldType  # Current visible world

switch_world(target_world)           # Switch between CORRUPTED/HUMAN
register_portal(tile_pos, world)     # Add portal at position
has_portal_at(tile_pos, world)       # Check if portal exists
is_portal_linked(tile_pos)           # True if portal in both worlds
can_corrupt_in_human_world(tile_pos) # True if near a portal
get_portals_in_world(world)          # Get all portal positions
reset()                              # Reset to initial state
```

## World.gd Responsibilities

1. **Dual World Management** - Two parallel worlds with identical terrain
2. **Map Generation** - Procedural floor, buildings, props (same in both worlds)
3. **Corruption System** - Per-world corruption tracking
4. **World Switching** - Toggle visibility based on WorldManager.active_world
5. **Entity Management** - Per-world entity containers, entity transfer between worlds
6. **Atmosphere Particles** - Visual effects in Corrupted World

### Tile Layers (per world)
| Layer | Human World | Corrupted World |
|-------|-------------|-----------------|
| FloorMap | `human_floor_map` | `corrupted_floor_map` |
| StructureMap | `human_structure_map` | `corrupted_structure_map` |
| CorruptionMap | `human_corruption_map` | `corrupted_corruption_map` |
| Entities | `human_entities` | `corrupted_entities` |

### Entity Management
- `human_entities: Node2D` - Container for entities in Human World
- `corrupted_entities: Node2D` - Container for entities in Corrupted World (Dark Lord spawns here)

Entities exist in exactly one world at a time. When the view switches, entities remain in their world (they don't follow the camera). Entities must travel through linked portals to move between worlds.

### Corruption Tracking
- `human_corrupted_tiles: Dictionary` - Corruption in Human World (spreads near portals)
- `corrupted_corrupted_tiles: Dictionary` - Corruption in Corrupted World (starts full)

Corruption spreads on floor tiles; structures render above corruption.

### Key Functions
```gdscript
generate_map()           # Full procedural generation
corrupt_tile(pos)        # Corrupt single tile
spread_corruption()      # Expand to random adjacent tile
get_entities_container(world)                    # Get Entities node for a world
transfer_entity_to_world(entity, target_world)   # Move entity between worlds (preserves position)
```

### Export Variables
```gdscript
@export var use_procedural_generation := true
@export var override_map_size := false
@export var custom_map_width := GameConstants.MAP_WIDTH
@export var custom_map_height := GameConstants.MAP_HEIGHT
```

## Dark Lord Entity

Player's avatar entity. Spawns in Corrupted World at initial corruption point. Must travel through linked portals to enter Human World.

### File Organization
```
scripts/entities/dark_lord/
├── DarkLordData.gd       # Entity-specific constants (preload pattern)
└── DarkLordController.gd # Behavior script

scenes/entities/dark_lord/
└── dark_lord.tscn        # Scene file
```

### Data Script (preload pattern)
```gdscript
const Data := preload("res://scripts/entities/dark_lord/DarkLordData.gd")

# DarkLordData.gd constants:
COLLISION_RADIUS    # float - physics collision size (also drives sprite scale)
SPRITE_SIZE_RATIO   # float - sprite size relative to collision (1.0 = match)
WANDER_SPEED        # float - movement speed
WANDER_INTERVAL_MIN # float - min wait between moves
WANDER_INTERVAL_MAX # float - max wait between moves
```

### Current Behavior
- Wanders randomly in 8 directions
- Moves one tile at a time
- Waits random interval between moves

### Scene Structure (dark_lord.tscn)
```
DarkLord [CharacterBody2D] (DarkLordController.gd)
├── Sprite2D - Visual representation (scale derived from COLLISION_RADIUS)
├── CollisionShape2D - Physics collision (radius from Data.COLLISION_RADIUS)
└── WanderTimer - Controls movement timing
```

## Portal Entity

Player-placeable buildings that allow travel between worlds when linked.

### File Organization
```
scripts/entities/buildings/
├── PortalData.gd       # Portal-specific constants (preload pattern)
└── PortalController.gd # Portal behavior script

scenes/entities/buildings/
└── portal.tscn         # Scene file
```

### Data Script (preload pattern)
```gdscript
const Data := preload("res://scripts/entities/buildings/PortalData.gd")

# PortalData.gd constants:
COLLISION_RADIUS        # float - physics collision size
TRAVEL_TRIGGER_RADIUS   # float - area for travel detection
SPRITE_SIZE_RATIO       # float - sprite size relative to collision
ACTIVE_COLOR            # Color - visual when linked
INACTIVE_COLOR          # Color - visual when not linked
PLACEMENT_COST          # int - essence cost to place
```

### Portal States
- **Inactive**: Portal exists in only one world (gray tint)
- **Active/Linked**: Portals exist at same tile in both worlds (purple glow)

### Scene Structure (portal.tscn)
```
Portal [StaticBody2D] (PortalController.gd)
├── Sprite2D - Visual representation
├── CollisionShape2D - Physics collision
└── TravelArea [Area2D] - Detects Dark Lord for travel
    └── CollisionShape2D - Travel trigger radius
```

### Travel Mechanic
1. Dark Lord enters active portal's TravelArea
2. Portal checks if linked (exists in both worlds)
3. If linked:
   - Portal calls `World.transfer_entity_to_world()` to physically move entity to target world's Entities container
   - Portal then calls `WorldManager.switch_world()` to change the camera view to follow
4. Cooldown prevents rapid world-hopping

**Key distinction**: World view switching (UI button, debug key) only changes which world is visible. Portal travel actually moves the entity between worlds.

---

## Adding New Features

### New Entity Type
1. Create folder `scripts/entities/your_entity/`
2. Create `YourEntityData.gd` with entity-specific constants (extends RefCounted)
3. Create `YourEntityController.gd` with behavior script
4. Create folder `scenes/entities/your_entity/`
5. Create `your_entity.tscn` scene with script attached
6. Use preload pattern: `const Data := preload("res://scripts/entities/your_entity/YourEntityData.gd")`
7. Set all configurable values (scale, collision, speeds) from Data in `_ready()`

### New Minion Type
1. Add to `Enums.MinionType`
2. Add stats to `GameConstants.MINION_STATS`
3. Add sprite to `TileData.CHAR_*`
4. HivePool automatically handles new type

### New Building Type
1. Add to `Enums.BuildingType`
2. Add stats to `GameConstants.BUILDING_STATS`
3. Add tiles to `TileData.PROP_*`

### New Tileset
1. Replace `TileData` coordinates
2. Update `resources/dungeon_tileset.tres` atlas
3. No other code changes needed

### New Balance Values
1. Add constant to `GameConstants`
2. Reference via `GameConstants.YOUR_CONSTANT`
3. Never hardcode numbers in logic files

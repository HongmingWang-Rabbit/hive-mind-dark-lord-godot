# Technical Architecture

## Autoload Dependency Graph

```
Enums (no deps)
    ↓
GameConstants (uses Enums)
    ↓
EventBus (no deps)
    ↓
Essence (uses GameConstants)
    ↓
HivePool (uses Enums, GameConstants, Essence)
    ↓
GameManager (uses all above)
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
BUILDING_STATS[BuildingType] = {cost, ...}

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

#region Corruption Visual
CORRUPTION_COLOR        # Color for corruption overlay

#region Directions
ORTHOGONAL_DIRS         # [Vector2i] - 4 cardinal directions
ALL_DIRS                # [Vector2i] - 8 directions including diagonals
```

## Scene Tree (main.tscn)

```
Main (World.gd)
├── FloorMap [TileMapLayer] - Base floor tiles
├── StructureMap [TileMapLayer] - Buildings, walls, props
├── CorruptionMap [TileMapLayer] - Purple overlay
├── Buildings [Node2D]
├── Entities [Node2D]
├── UI [CanvasLayer]
│   └── HUD
└── Camera2D (CameraController.gd) - Pan via keyboard/mouse
```

## System Reset Flow

```gdscript
GameManager.reset_game()  # Resets all systems
    → Essence.reset()     # Reset to STARTING_ESSENCE
    → HivePool.reset()    # Clear all minion pools
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

## World.gd Responsibilities

1. **Map Generation** - Procedural floor, buildings, props
2. **Corruption System** - Spreading, tracking, percentage
3. **Tile Layer Management** - Three TileMapLayers for proper rendering order

### Tile Layers (bottom to top)
| Layer | Variable | Content |
|-------|----------|---------|
| FloorMap | `floor_map` | Base floor tiles |
| StructureMap | `structure_map` | Buildings, walls, props |
| CorruptionMap | `corruption_map` | Purple corruption overlay |

Corruption spreads on floor tiles; structures render above corruption.

### Key Functions
```gdscript
generate_map()           # Full procedural generation
corrupt_tile(pos)        # Corrupt single tile
spread_corruption()      # Expand to random adjacent tile
```

### Export Variables
```gdscript
@export var use_procedural_generation := true
@export var override_map_size := false
@export var custom_map_width := GameConstants.MAP_WIDTH
@export var custom_map_height := GameConstants.MAP_HEIGHT
```

## Adding New Features

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

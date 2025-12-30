# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Hive Mind Dark Lord is a real-time strategy game built in Godot 4.5 where the player controls a dark lord spreading corruption across a city. 7-day game jam scope.

## Running the Project

Open in Godot 4.5 and run. No external build tools required.

## Architecture

### Autoload Order
```
Enums          → Global enums (GameState, MinionType, WorldType, etc.)
GameConstants  → All balance values and settings
EventBus       → Signal-based decoupling
WorldManager   → Dual-world state and portal tracking
Essence        → Resource system (income/drain)
HivePool       → Minion pool tracking
GameManager    → Game state, win/lose conditions
```

### Data Scripts (preload pattern)
- `TileData` - Tile atlas coordinates, access via preload:
  ```gdscript
  const Tiles := preload("res://scripts/data/tile_data.gd")
  var floor := Tiles.FLOOR_MAIN
  ```
- Entity-specific data - Each entity type has its own Data script:
  ```gdscript
  const Data := preload("res://scripts/entities/dark_lord/DarkLordData.gd")
  var speed := Data.WANDER_SPEED
  ```

### Communication Pattern
- **Events:** Systems communicate via `EventBus` signals
- **Queries:** Direct autoload access for state (e.g., `Essence.can_afford(cost)`)
- **Constants:** All magic numbers in `GameConstants`
- **Tiles:** All tile coordinates via preloaded `Tiles` constant

## Key Design Principles

1. **No hardcoded values** - Shared values in `GameConstants`, entity-specific in `EntityData.gd`
2. **Tile data separation** - Change `TileData` to swap tilesets
3. **Entity data separation** - Each entity type has its own `Data.gd` for configurable values
4. **Enum-based types** - Use `Enums.*` for type safety
5. **Signal decoupling** - Systems communicate via EventBus
6. **Reset pattern** - `GameManager.reset_game()` resets all systems

## Directory Structure

```
scripts/
  data/         # Enums, GameConstants, TileData
  systems/      # Autoloads (GameManager, Essence, HivePool, EventBus, WorldManager)
  world/        # World.gd, CameraController.gd
  entities/     # Entity scripts organized by entity type
    dark_lord/  # DarkLordData.gd, DarkLordController.gd
    buildings/  # PortalData.gd, PortalController.gd
  ui/           # UI controller scripts
    HUDController.gd
scenes/
  world/        # main.tscn
  entities/     # Entity scenes organized by entity type
    dark_lord/  # dark_lord.tscn
    buildings/  # portal.tscn
  ui/           # hud.tscn
resources/      # Tilesets, Kenney assets
doc/            # Design docs
```

## Display Settings

- Viewport: 480x270 (pixel art)
- Window: 1440x810 (3x scale)
- Texture filter: Nearest

## Documentation

- `doc/GAME_DESIGN.md` - Mechanics, units, win/lose
- `doc/ARCHITECTURE.md` - System dependencies, signals, constants reference
- `doc/TILE_REFERENCE.md` - Atlas coordinates
- `doc/JAM_SCOPE.md` - 7-day priorities

## Controls

- **Arrow keys / WASD**: Pan camera
- **Mouse drag (left/middle)**: Pan camera
- **Touch drag**: Pan camera
- **Space**: Spread corruption
- **P**: Place portal at Dark Lord position
- **World Button (UI)**: Switch between Corrupted/Human world view
- **Tab**: Switch between Corrupted/Human world (debug)

## Modifying Game Balance

Edit `scripts/data/game_constants.gd`:
```gdscript
# Essence & Economy
STARTING_ESSENCE, DARK_LORD_UPKEEP
ESSENCE_PER_TILE, ESSENCE_PER_KILL

# Win/Lose
WIN_THRESHOLD, THREAT_THRESHOLDS

# Map Generation
MAP_WIDTH, MAP_HEIGHT, MAP_EDGE_MARGIN
BUILDING_COUNT_MIN/MAX, PROP_COUNT
FLOOR_WEIGHT_MAIN/ALT/VARIATION
TILEMAP_SOURCE_ID

# Display & Camera
VIEWPORT_WIDTH, VIEWPORT_HEIGHT, CAMERA_CENTER
TILE_SIZE, CAMERA_PAN_SPEED, CAMERA_EDGE_PADDING
CAMERA_DRAG_BUTTONS, CAMERA_PAN_*_KEYS

# Input Keys
KEY_PLACE_PORTAL, KEY_SWITCH_WORLD

# Visuals
CORRUPTION_COLOR
HUMAN_WORLD_TINT, CORRUPTED_WORLD_TINT
CORRUPTED_PARTICLES_* (AMOUNT, LIFETIME, COLOR, DIRECTION, SPREAD, GRAVITY, VELOCITY, SCALE)
PORTAL_CORRUPTION_RADIUS, PORTAL_TRAVEL_COOLDOWN
```

## Changing Tileset

Edit `scripts/data/tile_data.gd`:
```gdscript
# Update coordinates to match new atlas
const FLOOR_MAIN := Vector2i(0, 4)
const WALL := Vector2i(1, 3)
const CHAR_SKELETON := Vector2i(3, 7)
```

## Code Standards

- Use `GameConstants.*` for shared numeric values (map size, tile size, etc.)
- Use `Data.*` for entity-specific values (preload EntityData.gd at top of script)
- Use `Tiles.*` for tile coordinates (preload TileData at top of script)
- Use `Enums.*` for type safety
- Use `EventBus.*` for system communication
- Use `randi_range()` instead of `randi() %` for random numbers
- Call `GameManager.reset_game()` to reset all systems
- Set configurable scene values (scale, collision shapes) from Data in `_ready()`

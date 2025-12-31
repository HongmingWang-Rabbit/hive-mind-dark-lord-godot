# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Hive Mind Dark Lord is a real-time strategy game built in Godot 4.5. Two parallel maps - Dark World and Human World with identical terrain but different states. You are the Dark Lord trying to corrupt the Human World from the Dark World.

**Key mechanic:** You must enter Human World to harvest resources (essence from killing civilians/animals), but this raises threat level. At high threat, military opens their own portals and invades YOUR Dark World to cleanse corruption. You can't hide forever.

**Win:** Corrupt 100% of Human World
**Lose:** Dark Lord dies OR all Dark World corruption cleansed

7-day game jam scope.

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
- Building Data scripts include sprite paths and UI display info:
  ```gdscript
  const Data := preload("res://scripts/entities/buildings/PortalData.gd")
  var texture := load(Data.SPRITE_PATH)
  var name := Data.NAME          # "Portal"
  var desc := Data.DESCRIPTION   # "Travel between Dark and Human worlds"
  ```
- Human entity data - Civilians and animals:
  ```gdscript
  const Data := preload("res://scripts/entities/humans/CivilianData.gd")
  _hp = Data.HP
  ```
- `UITheme` - UI colors and styling constants:
  ```gdscript
  const UI := preload("res://scripts/ui/UITheme.gd")
  label.add_theme_color_override("font_color", UI.ESSENCE_COLOR)
  ```
- `FogUtils` - Fog of war utility functions:
  ```gdscript
  const FogUtils := preload("res://scripts/utils/fog_utils.gd")
  var tiles := FogUtils.get_tiles_in_sight_range(center, range)
  ```

### Communication Pattern
- **Events:** Systems communicate via `EventBus` signals
- **Queries:** Direct autoload access for state (e.g., `Essence.can_afford(cost)`)
- **Constants:** All magic numbers in `GameConstants`
- **Tiles:** All tile coordinates via preloaded `Tiles` constant

## Key Design Principles

1. **No hardcoded values** - Balance values in `GameConstants`, entity-specific config in `EntityData.gd`, UI in `UITheme.gd`
2. **Data vs GameConstants separation**:
   - **GameConstants**: Balance values (HP, damage, rewards), shared config (tile size, directions), visual constants (cursor preview)
   - **Data files**: Entity-specific config (collision, sprite scale, movement speed, sprite paths)
3. **Tile data separation** - Change `TileData` to swap tilesets
4. **Entity data separation** - Each entity type has its own `Data.gd` for non-balance values
5. **UI theme separation** - All UI colors/styles in `UITheme.gd`, applied programmatically
6. **Enum-based types** - Use `Enums.*` for type safety
7. **Signal decoupling** - Systems communicate via EventBus
8. **Reset pattern** - `GameManager.reset_game()` resets all systems

## Directory Structure

```
scripts/
  data/         # Enums, GameConstants, TileData
  systems/      # Autoloads (GameManager, Essence, HivePool, EventBus, WorldManager)
  world/        # World.gd, CameraController.gd
  entities/     # Entity scripts organized by entity type
    dark_lord/  # DarkLordData.gd, DarkLordController.gd
    buildings/  # PortalData/Controller, CorruptionNodeData/Controller, SpawningPitData/Controller
    humans/     # CivilianData.gd, CivilianController.gd, AnimalData.gd, AnimalController.gd
    minions/    # MinionData.gd, MinionController.gd
    enemies/    # EnemyData.gd, EnemyController.gd
  ui/           # UI controller scripts
    HUDController.gd
    UITheme.gd     # UI colors and styling constants
    EvolveModal.gd # Placeholder evolution modal
    GameOverScreen.gd
  utils/        # Utility scripts (preload pattern)
    fog_utils.gd  # Fog of war visibility calculations
scenes/
  world/        # main.tscn
  entities/     # Entity scenes organized by entity type
    dark_lord/  # dark_lord.tscn
    buildings/  # portal.tscn, corruption_node.tscn, spawning_pit.tscn
    humans/     # civilian.tscn, animal.tscn
    minions/    # minion.tscn
    enemies/    # enemy.tscn
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

### Camera
- **Arrow keys / WASD**: Pan camera
- **Middle-mouse drag**: Pan camera
- **Touch drag**: Pan camera

### Gameplay
- **Left-click**: Move Dark Lord to position (when no mode active)
- **Space**: Spread corruption
- **P**: Place portal at Dark Lord position
- **1**: Spawn Crawler minion (costs 20 essence)
- **2**: Spawn Brute minion (costs 50 essence)
- **3**: Spawn Stalker minion (costs 40 essence)
- **Tab**: Switch between Corrupted/Human world (debug)

### UI Interaction Mode (Priority-Based)
Input is handled in priority order:
1. **UI buttons** (handled by Godot Control system)
2. **ESC / Right-click**: Cancel current interaction mode
3. **Left-click**: Execute current mode or move Dark Lord
4. **Keyboard shortcuts**: Minion spawning, world switch

- **Building buttons (toolbar)**: Enter build mode - cursor shows building preview
- **Order buttons (toolbar)**: Enter order mode - cursor shows colored target indicator
  - Attack (red), Defend (blue), Scout (green)
- **Left-click (build mode)**: Place building at tile
- **Left-click (order mode)**: Issue order to minions at position
- **Left-click (no mode)**: Move Dark Lord to position
- **Right-click / ESC**: Cancel current mode
- **World Button**: Switch between Corrupted/Human world view
- **Evolve Button**: Open evolution modal (placeholder)

## Modifying Game Balance

Edit `scripts/data/game_constants.gd`:
```gdscript
# Essence & Economy
STARTING_ESSENCE, DARK_LORD_UPKEEP
ESSENCE_PER_TILE, ESSENCE_PER_KILL
ESSENCE_PER_CIVILIAN, ESSENCE_PER_ANIMAL

# Human World Entities
CIVILIAN_COUNT, ANIMAL_COUNT
ENTITY_SPAWN_ATTEMPTS

# Combat - Dark Lord
DARK_LORD_HP, DARK_LORD_DAMAGE
DARK_LORD_ATTACK_RANGE, DARK_LORD_ATTACK_COOLDOWN

# Combat - Entities
CIVILIAN_HP, ANIMAL_HP

# Entity Groups (use for add_to_group/is_in_group)
GROUP_DARK_LORD, GROUP_CIVILIANS, GROUP_ANIMALS
GROUP_KILLABLE, GROUP_MINIONS, GROUP_THREATS
GROUP_ENEMIES, GROUP_POLICE, GROUP_MILITARY
GROUP_BUILDINGS, GROUP_PORTALS, GROUP_CORRUPTION_NODES, GROUP_SPAWNING_PITS

# Combat - Enemies
POLICE_HP, POLICE_DAMAGE, POLICE_SPEED
MILITARY_HP, MILITARY_DAMAGE, MILITARY_SPEED
HEAVY_HP, HEAVY_DAMAGE, HEAVY_SPEED
SPECIAL_FORCES_HP, SPECIAL_FORCES_DAMAGE, SPECIAL_FORCES_SPEED

# Enemy Spawning
POLICE_SPAWN_INTERVAL, MILITARY_SPAWN_INTERVAL, HEAVY_SPAWN_INTERVAL
MAX_POLICE, MAX_MILITARY, MAX_HEAVY, MAX_SPECIAL_FORCES
ENEMY_SPAWN_MARGIN

# Input Keys - Minion Spawning
KEY_SPAWN_CRAWLER, KEY_SPAWN_BRUTE, KEY_SPAWN_STALKER

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
CURSOR_PREVIEW_COLOR, CURSOR_PREVIEW_Z_INDEX
ORDER_CURSOR_COLOR, ORDER_CURSOR_DEFEND_COLOR, ORDER_CURSOR_SCOUT_COLOR, ORDER_CURSOR_SIZE
HUMAN_WORLD_TINT, CORRUPTED_WORLD_TINT
CORRUPTED_PARTICLES_* (AMOUNT, LIFETIME, COLOR, DIRECTION, SPREAD, GRAVITY, VELOCITY, SCALE)
PORTAL_CORRUPTION_RADIUS, PORTAL_TRAVEL_COOLDOWN

# Fog of War
FOG_ENABLED, FOG_COLOR
INITIAL_CORRUPTION_REVEAL_RADIUS
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

- Use `GameConstants.*` for balance values (HP, damage, rewards, spawn counts)
- Use `GameConstants.GROUP_*` for entity groups (never hardcode group strings)
- Use `Data.*` for entity-specific config (collision, movement, visuals)
- Use `Tiles.*` for tile coordinates (preload TileData at top of script)
- Use `Enums.*` for type safety
- Use `_unhandled_input()` for world/game input (not `_input()`) so UI gets priority
- Set `mouse_filter = MOUSE_FILTER_IGNORE` on full-screen UI containers so clicks pass through
- Use `EventBus.*` for system communication
- Use `randi_range()` instead of `randi() %` for random numbers
- Call `GameManager.reset_game()` to reset all systems
- Set configurable scene values (scale, collision shapes) from Data in `_ready()`
- For entity visibility (fog), implement `get_visible_tiles()` using `FogUtils.get_tiles_in_sight_range()`
- For killable entities: init HP from `GameConstants.*_HP`, implement `take_damage()`, add to `GROUP_KILLABLE`

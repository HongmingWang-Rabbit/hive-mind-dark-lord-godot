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

### FogUtils (preload utility)
Fog of war utility functions. Used by entities to calculate visible tiles.

```gdscript
const FogUtils := preload("res://scripts/utils/fog_utils.gd")

# Get tiles within circular distance:
var tiles := FogUtils.get_tiles_in_sight_range(center, range)
```

**Why preload instead of autoload?**
- Constants available at parse time (no runtime dependency issues)
- Explicit dependency declaration in each file that uses it
- Avoids Godot editor caching issues with class_name + autoload

## Enums Reference

```gdscript
# Game flow
Enums.GameState {MENU, PLAYING, PAUSED, WON, LOST}

# Units - Player
Enums.MinionType {CRAWLER, BRUTE, STALKER}
Enums.MinionAssignment {IDLE, ATTACKING, DEFENDING, SCOUTING}
Enums.Stance {AGGRESSIVE, HOLD, RETREAT}

# Units - Human World
Enums.HumanType {CIVILIAN, ANIMAL, POLICE, MILITARY, HEAVY, SPECIAL}

# Units - Special Forces (invade Dark World)
Enums.SpecialForcesType {SCOUT, CLEANSER, STRIKE_TEAM}

# World
Enums.BuildingType {CORRUPTION_NODE, SPAWNING_PIT, PORTAL, MILITARY_PORTAL}
Enums.ThreatLevel {NONE, LOW, MEDIUM, HIGH, CRITICAL}
Enums.TileType {FLOOR, WALL, PROP, EMPTY}
Enums.WorldType {CORRUPTED, HUMAN}

# Portal ownership
Enums.PortalOwner {DARK_LORD, MILITARY}
```

## EventBus Signals

```gdscript
# Corruption
signal tile_corrupted(tile_pos: Vector2i, world: Enums.WorldType)
signal corruption_changed(new_percent: float, world: Enums.WorldType)
signal corruption_cleansed(tile_pos: Vector2i, world: Enums.WorldType)

# Combat - Human World
signal entity_killed(position: Vector2, entity_type: Enums.HumanType)
signal human_possessed(position: Vector2)
signal enemy_spotted(position: Vector2, threat_type: Enums.ThreatLevel)

# Combat - Dark World Invasion
signal dark_world_invaded(portal_pos: Vector2i)
signal special_forces_spawned(position: Vector2, force_type: Enums.SpecialForcesType)
signal dark_lord_attacked(attacker_pos: Vector2)

# Buildings
signal building_placed(building_type: Enums.BuildingType, position: Vector2, world: Enums.WorldType)
signal building_destroyed(building_type: Enums.BuildingType, position: Vector2)

# Portals
signal portal_placed(tile_pos: Vector2i, world: Enums.WorldType, owner: Enums.PortalOwner)
signal portal_activated(tile_pos: Vector2i)
signal portal_closed(tile_pos: Vector2i, world: Enums.WorldType)
signal military_portal_opened(tile_pos: Vector2i)  # AI-controlled, player cannot prevent

# Commands
signal attack_ordered(target_pos: Vector2, minion_percent: float, stance: Enums.Stance)
signal retreat_ordered()

# Game State
signal threat_level_changed(new_level: Enums.ThreatLevel)
signal game_won()
signal game_lost(reason: String)  # "dark_lord_died" or "corruption_wiped"

# World Dimension
signal world_switched(new_world: Enums.WorldType)

# Fog of War
signal fog_update_requested(world: Enums.WorldType)

# Toolbar
signal building_requested(building_type: Enums.BuildingType)
signal order_requested(assignment: Enums.MinionAssignment)

# Resources
signal essence_harvested(amount: int, source: Enums.HumanType)
signal evolution_points_gained(amount: int, source: String)
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
WIN_THRESHOLD           # Corruption % to win (1.0 = 100% Human World)
THREAT_THRESHOLDS       # Array of corruption % triggers for each threat level

#region Resource Rates (per world)
DARK_WORLD_PASSIVE_INCOME   # Limited income in Dark World
HUMAN_WORLD_TILE_INCOME     # Income per corrupted tile in Human World
ESSENCE_PER_CIVILIAN        # +10
ESSENCE_PER_ANIMAL          # +5
ESSENCE_PER_MILITARY_KILL   # +15
EVOLUTION_PER_SPECIAL       # Points for consuming special humans

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

#region Fog of War
FOG_ENABLED                  # true - toggle fog system
FOG_COLOR                    # Color(0, 0, 0, 0.95) - unexplored fog opacity
INITIAL_CORRUPTION_REVEAL_RADIUS  # 3 tiles - starting revealed area
```

## Scene Tree (main.tscn)

```
Main (World.gd)
├── HumanWorld [Node2D] - Normal world, corruption spreads near portals
│   ├── FloorMap [TileMapLayer]
│   ├── StructureMap [TileMapLayer]
│   ├── CorruptionMap [TileMapLayer]
│   ├── Entities [Node2D] - Entities in Human World
│   └── FogMap [TileMapLayer, z_index=100] - Fog of war overlay
├── CorruptedWorld [Node2D] - Dark world, small initial corruption
│   ├── FloorMap [TileMapLayer]
│   ├── StructureMap [TileMapLayer]
│   ├── CorruptionMap [TileMapLayer]
│   ├── Entities [Node2D] - Entities in Corrupted World (Dark Lord spawns here)
│   ├── FogMap [TileMapLayer, z_index=100] - Fog of war overlay
│   └── AtmosphereParticles [GPUParticles2D]
├── UI [CanvasLayer]
│   └── HUD (HUDController.gd)
│       ├── TopBar [HBoxContainer]
│       │   ├── EssenceLabel
│       │   ├── CorruptionLabel
│       │   ├── ThreatLabel
│       │   └── WorldButton
│       ├── SidePanel [VBoxContainer]
│       ├── ContextPanel
│       └── BottomToolbar [PanelContainer]
│           └── HBox [HBoxContainer]
│               ├── BuildingsSection (N:50, P:100, O:20)
│               ├── OrdersSection (Atk, Sct, Def, Ret)
│               └── EvolveSection (Evo)
└── Camera2D (CameraController.gd)
```

Both worlds have identical terrain layout but **separate entities and fog**. Each world has its own Entities container and FogMap. Entities exist in exactly one world at a time and must travel through portals to move between worlds. Only one world is visible at a time (view toggle), but entities remain in their world.

**Key difference:** Dark World has limited resources (forces expansion). Human World has abundant resources but raises threat when harvested. At high threat, military opens their own portals and invades Dark World.

## Threat System

### Threat Level Responses
| Level    | Human World                   | Dark World                              |
|----------|-------------------------------|-----------------------------------------|
| NONE     | Peaceful                      | Safe                                    |
| LOW      | Police investigate            | Safe                                    |
| MEDIUM   | Military patrols              | Special forces scout near portals       |
| HIGH     | Heavy military deployed       | Military opens own portals, invades     |
| CRITICAL | Full war, all units attack    | Coordinated assault to kill Dark Lord   |

### Threat Triggers
- Corruption % in Human World
- Civilians killed
- Military casualties
- Time spent in Human World by Dark Lord

## HUDController.gd

Manages UI elements and player interactions. Applies visual theme from UITheme.gd.

### Features
- **Essence display**: Updates when `Essence.essence_changed` fires
- **Corruption display**: Updates when `EventBus.corruption_changed` fires
- **Threat display**: Updates when `EventBus.threat_level_changed` fires
- **World switch button**: Toggles visibility between Corrupted/Human world (view only, does not move entities)
- **Bottom toolbar**: Buildings, Orders, and Evolve sections with cost display and disabled states
- **Themed styling**: All colors and styles applied programmatically from UITheme.gd

### Bottom Toolbar Sections
| Section | Buttons | Emits |
|---------|---------|-------|
| Buildings | N:50, P:100, O:20 | `building_requested(BuildingType)` |
| Orders | Atk, Sct, Def, Ret | `order_requested(MinionAssignment)`, `retreat_ordered()` |
| Evolve | Evo | Placeholder for future |

Building buttons auto-disable when player can't afford the cost. Costs are retrieved via `_get_building_cost()` helper which routes to either `GameConstants.BUILDING_STATS` or `PortalData.PLACEMENT_COST`.

### UI Text Constants
```gdscript
WORLD_BUTTON_CORRUPTED  # "Corrupt"
WORLD_BUTTON_HUMAN      # "Human"
ESSENCE_FORMAT          # "E:%d" (compact for 480x270 viewport)
CORRUPTION_FORMAT       # "C:%d%%"
THREAT_FORMAT           # "T:%s"
THREAT_LEVEL_NAMES      # ["None", "Police", "Military", "Heavy"]
NODE_BTN_FORMAT         # "N:%d" (Corruption Node)
PIT_BTN_FORMAT          # "P:%d" (Spawning Pit)
PORTAL_BTN_FORMAT       # "O:%d" (Portal)
```

### Connected Signals
```gdscript
EventBus.corruption_changed
EventBus.threat_level_changed
EventBus.world_switched
Essence.essence_changed
```

## UITheme.gd

UI theme data script containing all visual constants for the HUD. Uses preload pattern.

### Usage
```gdscript
const UI := preload("res://scripts/ui/UITheme.gd")
label.add_theme_color_override("font_color", UI.ESSENCE_COLOR)
```

### Constants
```gdscript
#region Panel Colors
PANEL_BG_COLOR, PANEL_BORDER_COLOR
PANEL_BORDER_WIDTH, PANEL_CORNER_RADIUS
PANEL_MARGIN, PANEL_MARGIN_SMALL

#region Button Colors
BUTTON_BG_COLOR, BUTTON_BG_HOVER_COLOR
BUTTON_BORDER_COLOR, BUTTON_BORDER_HOVER_COLOR
BUTTON_FONT_COLOR, BUTTON_FONT_HOVER_COLOR
BUTTON_DISABLED_COLOR               # Grayed out when disabled
BUTTON_CORNER_RADIUS, BUTTON_BORDER_WIDTH
BUTTON_MARGIN_H, BUTTON_MARGIN_V

#region Label Colors - Stats
ESSENCE_COLOR, ESSENCE_SHADOW_COLOR
CORRUPTION_COLOR, CORRUPTION_SHADOW_COLOR
THREAT_COLOR, THREAT_SHADOW_COLOR

#region Label Colors - Minions
HEADER_COLOR, HEADER_SHADOW_COLOR
CRAWLER_COLOR, BRUTE_COLOR, STALKER_COLOR

#region Layout
SHADOW_OFFSET
TOP_BAR_SEPARATION, SIDE_PANEL_SEPARATION, SEPARATOR_WIDTH

#region Font
FONT_SIZE, FONT_SIZE_HEADER  # 8px for pixel art viewport

#region Bottom Toolbar
TOOLBAR_HEIGHT              # 24px
TOOLBAR_SECTION_SEPARATION  # 4px between sections
TOOLBAR_LABEL_COLOR         # Light purple section headers
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
3. **Corruption System** - Per-world corruption tracking (both worlds start with small initial area)
4. **World Switching** - Toggle visibility based on WorldManager.active_world
5. **Entity Management** - Per-world entity containers, entity transfer between worlds
6. **Atmosphere Particles** - Visual effects in Corrupted World
7. **Fog of War** - Per-world fog that reveals via entity sight and corruption spread

### Tile Layers (per world)
| Layer | Human World | Corrupted World |
|-------|-------------|-----------------|
| FloorMap | `human_floor_map` | `corrupted_floor_map` |
| StructureMap | `human_structure_map` | `corrupted_structure_map` |
| CorruptionMap | `human_corruption_map` | `corrupted_corruption_map` |
| Entities | `human_entities` | `corrupted_entities` |
| FogMap | `human_fog_map` | `corrupted_fog_map` |

### Entity Management
- `human_entities: Node2D` - Container for entities in Human World
- `corrupted_entities: Node2D` - Container for entities in Corrupted World (Dark Lord spawns here)

Entities exist in exactly one world at a time. When the view switches, entities remain in their world (they don't follow the camera). Entities must travel through linked portals to move between worlds.

### Corruption Tracking
- `human_corrupted_tiles: Dictionary` - Corruption in Human World (spreads near portals)
- `corrupted_corrupted_tiles: Dictionary` - Corruption in Corrupted World (starts small, must expand)

Both worlds start with small initial corruption around spawn point. Corruption spreads on floor tiles; structures render above corruption.

### Fog of War Tracking
- `_human_explored_tiles: Dictionary` - Revealed tiles in Human World
- `_corrupted_explored_tiles: Dictionary` - Revealed tiles in Corrupted World

Fog clears permanently when explored (no re-fogging for jam scope). In Corrupted World, corruption spread auto-reveals tiles.

### Key Functions
```gdscript
generate_map()           # Full procedural generation
corrupt_tile(pos)        # Corrupt single tile (auto-reveals fog in Corrupted World)
spread_corruption()      # Expand to random adjacent tile
get_entities_container(world)                    # Get Entities node for a world
transfer_entity_to_world(entity, target_world)   # Move entity between worlds (preserves position)
update_fog(world)        # Reveal tiles based on entity sight ranges
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
SIGHT_RANGE         # int - tiles visible around Dark Lord (fog of war)
MAX_HP              # int - Dark Lord health (strong monster, can fight)
DAMAGE              # int - attack damage
ATTACK_COOLDOWN     # float - seconds between attacks
```

### Current Behavior
- Wanders randomly in 8 directions
- Moves one tile at a time
- Waits random interval between moves
- Reveals fog in sight range when moving (via `get_visible_tiles()`)

### Combat (TODO)
- Has HP - can take damage and die (Game Over)
- Strong monster - can fight police/military directly
- Should avoid being overwhelmed by large groups
- Death triggers `game_lost("dark_lord_died")`

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
SIGHT_RANGE             # int - tiles visible around portal (fog of war)
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

## Entity Visibility Interface (Fog of War)

Entities that reveal fog implement `get_visible_tiles() -> Array[Vector2i]`. Called by `World.update_fog()` to determine which tiles to reveal.

### FogUtils.gd (preload utility)
```gdscript
const FogUtils := preload("res://scripts/utils/fog_utils.gd")

# Static function for circular (Euclidean) distance tile calculation
FogUtils.get_tiles_in_sight_range(center: Vector2i, sight_range: int) -> Array[Vector2i]
```

### Implementing on New Entities
```gdscript
const FogUtils := preload("res://scripts/utils/fog_utils.gd")

func get_visible_tiles() -> Array[Vector2i]:
    var center := Vector2i(global_position / GameConstants.TILE_SIZE)
    return FogUtils.get_tiles_in_sight_range(center, Data.SIGHT_RANGE)
```

### Visibility Shape
Uses Euclidean distance (circular reveal) via squared distance comparison for efficiency.

### Fog Reveal Triggers
- **Entity movement**: Emit `EventBus.fog_update_requested.emit(WorldManager.active_world)`
- **Entity spawned/placed**: Same as movement
- **Corruption spread** (Corrupted World only): Auto-reveals in `corrupt_tile()`

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

### New Human World Entity (Civilian, Animal, etc.)
1. Add to `Enums.HumanType`
2. Create entity following "New Entity Type" pattern
3. Add essence value to `GameConstants.ESSENCE_PER_*`
4. Add spawn logic to Human World entity spawner
5. If special: add evolution points to `GameConstants.EVOLUTION_PER_SPECIAL`

**Note:** Animals use generic `HumanType.ANIMAL` but the system is extensible.
Future special creatures (e.g., rare monsters, easter eggs) can have their own
type and custom rewards. Just add new enum value and configure rewards.

### New Special Forces Type (Invade Dark World)
1. Add to `Enums.SpecialForcesType`
2. Create entity following "New Entity Type" pattern
3. Add behavior: SCOUT (report), CLEANSER (remove corruption), STRIKE_TEAM (attack)
4. Add spawn trigger at appropriate threat level

### New Minion Type
1. Add to `Enums.MinionType`
2. Add stats to `GameConstants.MINION_STATS`
3. Add sprite to `TileData.CHAR_*`
4. HivePool automatically handles new type

### New Building Type
1. Add to `Enums.BuildingType`
2. Add stats to `GameConstants.BUILDING_STATS`
3. Add tiles to `TileData.PROP_*`

### Military Portal System
Military portals are AI-controlled and open at HIGH+ threat:
1. Listen for `threat_level_changed` signal
2. At HIGH threat, spawn military portals **dynamically near player corruption** (not fixed)
3. Emit `military_portal_opened` signal
4. Special forces enter through military portals
5. Player CANNOT close or prevent military portals

### New Tileset
1. Replace `TileData` coordinates
2. Update `resources/dungeon_tileset.tres` atlas
3. No other code changes needed

### New Balance Values
1. Add constant to `GameConstants`
2. Reference via `GameConstants.YOUR_CONSTANT`
3. Never hardcode numbers in logic files

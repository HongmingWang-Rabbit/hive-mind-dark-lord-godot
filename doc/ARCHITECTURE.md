# Technical Architecture

## Autoload Dependency Graph

```
Enums (no deps)
	↓
GameConstants (uses Enums)
	↓
EventBus (no deps)
	↓
SpatialGrid (no deps) - Spatial partitioning for efficient neighbor queries
	↓
WorldManager (uses Enums, GameConstants, EventBus)
	↓
Essence (uses GameConstants)
	↓
HivePool (uses Enums, GameConstants, Essence)
	↓
GameManager (uses all above, including WorldManager, SpatialGrid)
```

## Data Scripts

### Data vs GameConstants Separation

**GameConstants** (autoload) contains:
- Balance values that affect gameplay (HP, damage, essence rewards, spawn counts)
- Shared configuration (tile size, map dimensions, directions)
- Values you'd tweak when balancing the game

**Data files** (preload) contain:
- Entity-specific configuration (collision radius, sprite scale, movement speed)
- Sprite asset paths (e.g., `SPRITE_PATH := "res://assets/sprites/buildings/dark_portal.png"`)
- UI display info for buildings (NAME, DESCRIPTION)
- Values specific to how an entity looks/moves, not its combat stats
- Non-balance values that define entity behavior

**Example:**
```gdscript
# GameConstants - balance values
CIVILIAN_HP := 10          # How much damage to kill
ESSENCE_PER_CIVILIAN := 10 # Reward for killing

# CivilianData - entity-specific config
COLLISION_RADIUS := 5.0    # How big the hitbox is
WANDER_SPEED := 25.0       # How fast it moves
```

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

### Components (composition pattern)
Reusable components that can be added to any entity.

#### HealthComponent
Tracks HP and displays a health bar. Used by all combat entities.

```gdscript
const HealthComponent := preload("res://scripts/components/HealthComponent.gd")

var _health: Node2D

func _ready() -> void:
    _setup_health_component()

func _setup_health_component() -> void:
    _health = HealthComponent.new()
    add_child(_health)
    _health.setup(max_hp)
    _health.died.connect(_die)

func take_damage(amount: int) -> void:
    _health.take_damage(amount)
```

**HealthComponent API:**
- `setup(max_hp, current_hp)` - Initialize health (current defaults to max)
- `take_damage(amount)` - Apply damage, emit signals, trigger death
- `heal(amount)` - Heal up to max HP
- `get_hp()` / `get_max_hp()` / `is_alive()` - Queries
- Signal `died` - Emitted when HP reaches 0
- Signal `health_changed(current, max)` - Emitted on any HP change

**HealthBar (internal):**
The HealthComponent automatically creates a HealthBar child that displays:
- Hidden when HP = 100% (only shows when damaged)
- Green bar when HP > 60%
- Yellow bar when HP 30-60%
- Red bar when HP < 30%
All visual constants in GameConstants (HEALTH_BAR_*)

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
Enums.HumanType {CIVILIAN, ANIMAL, POLICEMAN}

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
signal dark_lord_move_ordered(target_pos: Vector2)  # Player clicked to move Dark Lord

# Game State
signal threat_level_changed(new_level: Enums.ThreatLevel)
signal game_won()
signal game_lost(reason: String)  # "dark_lord_died" or "corruption_wiped"

# World Dimension
signal world_switched(new_world: Enums.WorldType)

# Fog of War
signal fog_update_requested(world: Enums.WorldType)

# Interaction Mode
signal interaction_mode_changed(mode: Enums.InteractionMode, data: Variant)
signal build_mode_entered(building_type: Enums.BuildingType)
signal order_mode_entered(assignment: Enums.MinionAssignment)
signal interaction_cancelled()

# UI
signal evolve_modal_requested()

# Alarm System
signal alarm_triggered(position: Vector2)  # Civilian triggered alarm tower

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
ESSENCE_PER_CIVILIAN    # +10 - reward for killing civilians
ESSENCE_PER_ANIMAL      # +5 - reward for killing animals
ESSENCE_PER_POLICEMAN   # +15 - reward for killing policemen

#region Human World Entities
ANIMAL_COUNT            # Number of animals to spawn (8)
ENTITY_SPAWN_ATTEMPTS   # Max attempts to find valid spawn position (50)
# Note: Civilians spawned by civilian houses, policemen spawned by police stations

#region Civilian Houses (Human World)
CIVILIAN_HOUSE_COUNT            # Number of civilian houses to spawn (4)
MAX_CIVILIANS_PER_HOUSE         # Max civilians each house can maintain (3)
CIVILIAN_HOUSE_SPAWN_INTERVAL   # Seconds between civilian spawn attempts (8.0)

#region Police Stations (Human Defense)
POLICE_STATION_COUNT            # Number of police stations to spawn (2)
MAX_POLICEMEN_PER_STATION       # Max policemen each station can maintain (5)
POLICE_STATION_SPAWN_INTERVAL   # Seconds between policeman spawn attempts (5.0)

#region Military Portals (Human Defense)
MILITARY_PORTAL_THREAT_THRESHOLD  # Threat level (70%) to start spawning portals
MILITARY_PORTAL_SPAWN_INTERVAL    # Seconds between portal spawns (30.0)
MILITARY_PORTAL_MAX_COUNT         # Max military portals on map (3)

#region Entity Groups (use for add_to_group/is_in_group)
GROUP_DARK_LORD         # "dark_lord"
GROUP_CIVILIANS         # "civilians"
GROUP_ANIMALS           # "animals"
GROUP_POLICEMEN         # "policemen"
GROUP_KILLABLE          # "killable" - entities Dark Lord can attack
GROUP_MINIONS           # "minions"
GROUP_THREATS           # "threats" - Dark Lord + minions (civilians flee from)
GROUP_ENEMIES           # "enemies" - police, military, etc.
GROUP_SWAT              # "swat"
GROUP_MILITARY          # "military"
GROUP_HEAVY             # "heavy"
GROUP_SPECIAL_FORCES    # "special_forces"
GROUP_BUILDINGS         # "buildings" - all player buildings
GROUP_PORTALS           # "portals"
GROUP_CORRUPTION_NODES  # "corruption_nodes"
GROUP_SPAWNING_PITS     # "spawning_pits"
GROUP_ALARM_TOWERS      # "alarm_towers" - human defense structures
GROUP_POLICE_STATIONS   # "police_stations" - human defense structures
GROUP_MILITARY_PORTALS  # "military_portals" - human military portals
GROUP_CIVILIAN_HOUSES   # "civilian_houses" - human dwellings

#region Alarm Towers (Human Defense)
ALARM_TOWER_COUNT           # 3 - towers spawned per map
ALARM_THREAT_INCREASE       # 1 - threat levels gained when triggered
ALARM_ENEMY_ATTRACT_RADIUS  # 128.0px - enemies within this respond

#region Combat - Dark Lord
DARK_LORD_HP            # 100 - Dark Lord max health
DARK_LORD_DAMAGE        # 10 - damage per attack
DARK_LORD_ATTACK_RANGE  # 16.0 pixels (1 tile)
DARK_LORD_ATTACK_COOLDOWN # 0.5s between attacks

#region Human World Entities
HUMAN_ENTITY_STATS[HumanType] = {hp, damage, essence_reward, group}  # Unified human entity stats

#region Units
MINION_STATS[MinionType] = {cost, upkeep, hp, damage, speed}

#region Combat - Enemies
ENEMY_STATS[EnemyType] = {hp, damage, speed, group, spawn_interval, max_count, min_threat}  # Complete enemy config

#region Buildings
BUILDING_STATS[BuildingType] = {cost, hp, ...}  # Buildings have HP, can be destroyed by enemies

#region Corruption Spread
CORRUPTION_SPREAD_INTERVAL      # Seconds between node spread ticks (2.0)
CORRUPTION_NODE_RANGE           # Max tiles from node for spreading (5)
PORTAL_INITIAL_CORRUPTION_RANGE # Corruption radius in Human World (1)

#region Win/Lose
WIN_THRESHOLD           # Corruption % to win (1.0 = 100% Human World)
THREAT_THRESHOLDS       # Array of corruption % triggers for each threat level

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
SPAWN_HOTKEYS[Key] = MinionType  # Data-driven hotkey mapping (KEY_1 -> CRAWLER, etc.)

#region Corruption Visual
CORRUPTION_COLOR        # Color for corruption overlay

#region Cursor Preview
CURSOR_PREVIEW_COLOR    # Color(1.0, 1.0, 1.0, 0.7) - semi-transparent preview
CURSOR_PREVIEW_Z_INDEX  # 50 - above world, below UI
ORDER_CURSOR_COLORS[MinionAssignment] = Color  # Data-driven cursor colors
ORDER_STANCES[MinionAssignment] = Stance  # Data-driven order stances
ORDER_CURSOR_SIZE       # 12.0 - diameter of order cursor circle
ORDER_CURSOR_RING_WIDTH # 2.0 - width of the ring outline
ORDER_CURSOR_CENTER_ALPHA  # 0.3 - alpha of center fill

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
│       ├── BottomToolbar [PanelContainer]
│       │   └── HBox [HBoxContainer]
│       │       ├── BuildingsSection (icon buttons with tooltips)
│       │       ├── OrdersSection (Atk, Sct, Def, Ret)
│       │       └── EvolveSection (Evo)
│       └── ModeIndicator [Label] - Shows "Click to place/target"
├── GameOverScreen (GameOverScreen.gd)
├── EvolveModal (EvolveModal.gd) - Placeholder modal for evolution
└── Camera2D (CameraController.gd)
```

Both worlds have identical terrain layout but **separate entities and fog**. Each world has its own Entities container and FogMap. Entities exist in exactly one world at a time and must travel through portals to move between worlds. Only one world is visible at a time (view toggle), but entities remain in their world.

**Key difference:** Dark World has limited resources (forces expansion). Human World has abundant resources but raises threat when harvested. At high threat, military opens their own portals and invades Dark World.

## Threat System

### Threat Level Responses
| Level    | Human World                   | Dark World                              |
|----------|-------------------------------|-----------------------------------------|
| NONE     | Peaceful                      | Safe                                    |
| LOW      | SWAT investigate              | Safe                                    |
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

### Mouse Filter Configuration
The HUD root Control and non-interactive labels use `mouse_filter = MOUSE_FILTER_IGNORE` (2) so mouse clicks pass through to the world below. Only interactive elements (buttons, panels) capture mouse events.

```gdscript
# In hud.tscn - root HUD node
mouse_filter = 2  # MOUSE_FILTER_IGNORE - clicks pass through

# Interactive elements (buttons, panels) use default MOUSE_FILTER_STOP
```

### Features
- **Essence display**: Updates when `Essence.essence_changed` fires
- **Corruption display**: Updates when `EventBus.corruption_changed` fires
- **Threat display**: Updates when `EventBus.threat_level_changed` fires
- **World switch button**: Toggles visibility between Corrupted/Human world (view only, does not move entities)
- **Bottom toolbar**: Buildings, Orders, and Evolve sections with cost display and disabled states
- **Mode indicator**: Shows "Click to place/target" when in build/order mode (mouse_filter = IGNORE)
- **Themed styling**: All colors and styles applied programmatically from UITheme.gd

### Interaction Mode System
Priority-based input handling (World.gd `_unhandled_input`):
1. **UI buttons** (handled by Godot Control system - highest priority)
2. **ESC** cancels current interaction mode
3. **Mouse clicks** (with UI overlap check via `_is_mouse_over_ui()`)
4. **Keyboard shortcuts** (minion spawning, world switch)

Flow:
1. User clicks building/order button → enters build/order mode
2. Mode indicator appears: "Click to place" or "Click to target"
3. Cursor preview: building sprite (build mode) or colored circle (order mode)
   - Build cursor: scaled by `Data.SPRITE_SIZE_RATIO`, snaps to tile
   - Order cursor: `ORDER_CURSOR_COLOR` (attack), `ORDER_CURSOR_DEFEND_COLOR`, `ORDER_CURSOR_SCOUT_COLOR`
4. User left-clicks on map → action executed at clicked position
5. Left-click with no mode → moves Dark Lord to position
6. ESC or right-click cancels current mode

### Bottom Toolbar Sections
| Section | Buttons | Emits |
|---------|---------|-------|
| Buildings | Icon buttons (sprites from Data.SPRITE_PATH) | `build_mode_entered(BuildingType)` |
| Orders | Atk, Sct, Def, Ret | `order_mode_entered(MinionAssignment)`, `retreat_ordered()` |
| Evolve | Evo | `evolve_modal_requested()` |

Building buttons display sprites from Data files with tooltips showing "Name (cost)\nDescription". Buttons auto-disable when player can't afford the cost. Costs are retrieved via `_get_building_cost()` helper which routes to either `GameConstants.BUILDING_STATS` or `PortalData.PLACEMENT_COST`.

### UI Text Constants
```gdscript
WORLD_BUTTON_CORRUPTED  # "Corrupt"
WORLD_BUTTON_HUMAN      # "Human"
ESSENCE_FORMAT          # "E:%d" (compact for 480x270 viewport)
CORRUPTION_FORMAT       # "C:%d%%"
THREAT_FORMAT           # "T:%s"
THREAT_LEVEL_NAMES      # ["None", "SWAT", "Military", "Heavy"]
BUILDING_TOOLTIP_FORMAT # "%s (%d)\n%s" - "Name (cost)\nDescription"
MODE_BUILD              # "Click to place"
MODE_ORDER              # "Click to target"
```

### Connected Signals
```gdscript
EventBus.corruption_changed
EventBus.threat_level_changed
EventBus.world_switched
EventBus.interaction_mode_changed
EventBus.interaction_cancelled
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
FONT_SIZE_TITLE              # 10px for modal titles

#region Modal
MODAL_CONTENT_COLOR          # Color for modal text content
MODAL_OVERLAY_COLOR          # Semi-transparent overlay color

#region Bottom Toolbar
TOOLBAR_HEIGHT              # 24px
TOOLBAR_SECTION_SEPARATION  # 4px between sections
TOOLBAR_LABEL_COLOR         # Light purple section headers
BUILDING_BUTTON_ICON_SIZE   # Vector2i(16, 16) - icon size for building buttons
```

## SpatialGrid.gd

Autoload for efficient spatial queries. Reduces O(n²) neighbor checks to O(n).

### Public API
```gdscript
update_entity(entity: Node2D)                    # Update entity's grid position (call when moving)
remove_entity(entity: Node2D)                    # Remove entity from grid (call when dying)
get_nearby_entities(pos: Vector2, radius: float) # Get entities within radius
reset()                                          # Clear all data
```

### How It Works
- Divides world into cells of `SPATIAL_GRID_CELL_SIZE` pixels
- Entities register their cell when moving
- Neighbor queries only check relevant cells instead of all entities
- Dead entities cleaned up every `SPATIAL_GRID_CLEANUP_INTERVAL` seconds

### Usage Pattern
```gdscript
# In _physics_process:
SpatialGrid.update_entity(self)

# When querying neighbors:
var nearby := SpatialGrid.get_nearby_entities(global_position, radius)

# In _die():
SpatialGrid.remove_entity(self)
```

## System Reset Flow

```gdscript
GameManager.reset_game()  # Resets all systems
    → Essence.reset()     # Reset to STARTING_ESSENCE
    → HivePool.reset()    # Clear all minion pools
    → WorldManager.reset() # Reset to CORRUPTED world, clear portals
    → SpatialGrid.reset() # Clear spatial grid
```

## CameraController.gd

Standalone camera script attached to Camera2D node. Handles all camera movement.

### Features
- **Keyboard pan**: Arrow keys (built-in) + configurable keys (default: WASD)
- **Mouse drag**: Configurable buttons (default: left/middle)
- **Touch drag**: Single finger drag support
- **Scroll wheel zoom**: Zoom in/out with mouse wheel (min/max configurable)
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

## World.gd Architecture

World.gd is an orchestrator that delegates to specialized managers (RefCounted classes).

### Manager Structure
```
scripts/world/
├── World.gd              # Orchestrator (~400 lines)
├── MapGenerator.gd       # Procedural map generation
├── CorruptionManager.gd  # Corruption spreading and tracking
├── FogManager.gd         # Fog of war visibility
├── InputManager.gd       # Input handling, cursor preview, interaction modes
├── EntitySpawner.gd      # Entity spawning (Dark Lord, civilians, animals, minions)
└── EnemySpawner.gd       # Threat-based enemy spawning
```

### Manager Pattern
Managers extend `RefCounted` (lightweight, script-only) and receive World reference via `setup()`:
```gdscript
# Manager pattern
extends RefCounted
## Description of manager

var _world: Node2D

func setup(world: Node2D, ...) -> void:
    _world = world
```

### World.gd Orchestration
```gdscript
# Preload managers
const MapGenerator := preload("res://scripts/world/MapGenerator.gd")
# ... other managers

var _map_generator: RefCounted
# ... other manager references

func _ready() -> void:
    _init_managers()  # Create and wire up managers
    _map_generator.generate_map()
    # ...

func _process(delta: float) -> void:
    _enemy_spawner.process(delta)  # Delegate processing
    _input_manager.update_cursor_preview()

func _unhandled_input(event: InputEvent) -> void:
    _input_manager.handle_input(event)  # Delegate input
```

### Responsibilities
| Component | Responsibility |
|-----------|----------------|
| World.gd | Orchestrator, node references, world switching, building placement |
| MapGenerator | Procedural terrain, buildings, props |
| CorruptionManager | Corruption spreading, tracking, win condition |
| FogManager | Fog of war visibility, reveal on movement/corruption |
| InputManager | Input handling, cursor preview, interaction modes |
| EntitySpawner | Dark Lord, civilians, animals, minions |
| EnemySpawner | Threat-based enemy spawning |

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

### World Collision Separation
Each world uses separate collision layers so entities don't physically interact across worlds:
- **Layer 4**: Corrupted World entities
- **Layer 5**: Human World entities
- **Layer 2**: Threat detection (Dark Lord, minions - for flee behavior)

Entities implement `set_world_collision(world)` to update their collision layer/mask. Called on:
- Spawn (in `_ready()` or after adding to scene)
- Portal transfer (`transfer_entity_to_world()` calls it automatically)

For entities with AttackRange (Dark Lord, minions), `set_world_collision()` also updates `attack_range.collision_mask` to detect enemies in the current world.

### Corruption Tracking
- `human_corrupted_tiles: Dictionary` - Corruption in Human World (spreads from nodes near portals)
- `corrupted_corrupted_tiles: Dictionary` - Corruption in Corrupted World (starts with one node)

**Corruption System:**
- Game starts with one Corruption Node in Corrupted World at center
- Corruption Nodes auto-spread corruption every `CORRUPTION_SPREAD_INTERVAL` seconds
- Spread is limited to `CORRUPTION_NODE_RANGE` tiles (Manhattan distance) from each node
- Buildings can only be placed on corrupted tiles
- Portals create `PORTAL_INITIAL_CORRUPTION_RANGE` tiles of corruption in Human World

**Helper Functions:**
- `is_tile_corrupted(pos, world)` - Check if tile is corrupted
- `can_corrupt_tile(pos, world)` - Check if tile can be corrupted
- `corrupt_area_around(center, world, radius)` - Corrupt area around position

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

# DarkLordData.gd constants (entity-specific, non-balance):
COLLISION_RADIUS    # float - physics collision size (also drives sprite scale)
SPRITE_SIZE_RATIO   # float - sprite size relative to collision (1.0 = match)
WANDER_SPEED        # float - movement speed when wandering (30.0)
MOVE_SPEED          # float - movement speed when player commands (80.0)
CHASE_SPEED         # float - movement speed when chasing enemies (70.0)
WANDER_INTERVAL_MIN # float - min wait between moves
WANDER_INTERVAL_MAX # float - max wait between moves
DETECTION_RADIUS    # float - range to detect and chase enemies (64px, ~4 tiles)
SIGHT_RANGE         # int - tiles visible around Dark Lord (fog of war)
INVALID_TILE_POS    # Vector2i - marker for uninitialized tile position

# Combat balance values are in GameConstants:
# DARK_LORD_HP, DARK_LORD_DAMAGE, DARK_LORD_ATTACK_RANGE, DARK_LORD_ATTACK_COOLDOWN
```

### State Machine
The Dark Lord uses a state machine for behavior:

| State | Description |
|-------|-------------|
| IDLE | Stationary, checking for targets, waiting to wander |
| WANDER | Moving to random adjacent tile (uses `WANDER_SPEED`) |
| MOVE_TO | Player-commanded movement (uses `MOVE_SPEED`, ignores enemies) |
| CHASE | Pursuing detected enemy (uses `CHASE_SPEED`) |
| ATTACK | Attacking target in range (stationary) |

**State Transitions:**
- IDLE/WANDER → ATTACK: Target enters attack range
- IDLE/WANDER → CHASE: Enemy detected in detection range (no attack target)
- CHASE → ATTACK: Chase target enters attack range
- ATTACK → CHASE: Target moves out of attack range
- ATTACK → IDLE: Target dies, no other targets
- MOVE_TO → ATTACK: Arrived at destination with target in range
- MOVE_TO → IDLE: Arrived at destination, no targets

### Detection vs Attack Range
Two separate Area2D zones:

| Area | Radius | Purpose |
|------|--------|---------|
| DetectionArea | `Data.DETECTION_RADIUS` (64px, ~4 tiles) | Detects enemies to chase |
| AttackRange | `GameConstants.DARK_LORD_ATTACK_RANGE` (16px, 1 tile) | Detects targets to attack |

**Detection targets:** `GROUP_ENEMIES` (military, police, etc.)
**Attack targets:** `GROUP_KILLABLE` (civilians, animals) + `GROUP_ENEMIES`

### Combat System
- Attack cooldown controlled by `GameConstants.DARK_LORD_ATTACK_COOLDOWN`
- Damage dealt: `GameConstants.DARK_LORD_DAMAGE`
- Calls `take_damage()` on target entities
- When target HP depletes: entity dies, Dark Lord gains essence (for killables)
- Listens to `EventBus.dark_lord_move_ordered` for player commands

### Scene Structure (dark_lord.tscn)
```
DarkLord [CharacterBody2D] (DarkLordController.gd)
├── Sprite2D - Visual representation (scale derived from COLLISION_RADIUS)
├── CollisionShape2D - Physics collision (radius from Data.COLLISION_RADIUS)
├── WanderTimer - Controls movement timing
├── AttackTimer - Cooldown between attacks (one_shot)
├── AttackRange [Area2D] - Detects attack targets (GROUP_KILLABLE + GROUP_ENEMIES)
│   └── CollisionShape2D - Attack detection radius (DARK_LORD_ATTACK_RANGE)
└── DetectionArea [Area2D] (created dynamically) - Detects enemies for chasing
	└── CollisionShape2D - Detection radius (Data.DETECTION_RADIUS)
```

## Human World Entities

Civilians, animals, and policemen spawn in Human World. Civilians and animals wander randomly and provide essence when killed. Policemen randomly fight or flee when detecting threats.

### File Organization
```
scripts/entities/humans/
├── CivilianData.gd       # Civilian constants (preload pattern)
├── CivilianController.gd # Civilian behavior
├── AnimalData.gd         # Animal constants (preload pattern)
├── AnimalController.gd   # Animal behavior
├── PolicemanData.gd      # Policeman constants (preload pattern)
└── PolicemanController.gd # Policeman behavior (fight/flight)

scenes/entities/humans/
├── civilian.tscn         # Civilian scene
├── animal.tscn           # Animal scene
└── policeman.tscn        # Policeman scene
```

### Entity Data Pattern
```gdscript
# Data files use preload pattern and contain entity-specific (non-balance) constants:
const Data := preload("res://scripts/entities/humans/CivilianData.gd")

# Data constants (entity-specific, non-balance):
COLLISION_RADIUS    # float - physics collision size
SPRITE_SIZE_RATIO   # float - sprite size relative to collision
WANDER_SPEED        # float - movement speed (civilians: 25, animals: 15)
WANDER_INTERVAL_MIN # float - min wait between moves
WANDER_INTERVAL_MAX # float - max wait between moves

# Balance values are in GameConstants:
# CIVILIAN_HP, ANIMAL_HP, ESSENCE_PER_CIVILIAN, ESSENCE_PER_ANIMAL
```

### Behavior
- Wander randomly in 8 directions (same pattern as Dark Lord)
- Move one tile at a time
- Wait random interval between moves
- Animals move slower than civilians

### Combat Interface
Combat entities use HealthComponent for HP tracking and health bar display:
```gdscript
const HealthComponent := preload("res://scripts/components/HealthComponent.gd")

var _health: Node2D

func _ready() -> void:
	add_to_group(GameConstants.GROUP_KILLABLE)
	_setup_health_component()

func _setup_health_component() -> void:
	_health = HealthComponent.new()
	add_child(_health)
	_health.setup(GameConstants.CIVILIAN_HP)  # or ANIMAL_HP
	_health.died.connect(_die)

func take_damage(amount: int) -> void:
	_health.take_damage(amount)

func _die() -> void:
	EventBus.entity_killed.emit(global_position, Enums.HumanType.CIVILIAN)
	Essence.modify(GameConstants.ESSENCE_PER_CIVILIAN)
	queue_free()
```

### Groups
Entities add themselves to groups for detection:
```gdscript
add_to_group(GameConstants.GROUP_CIVILIANS)  # or GROUP_ANIMALS
add_to_group(GameConstants.GROUP_KILLABLE)   # Dark Lord targets this group
```

### Scene Structure
```
Civilian/Animal [CharacterBody2D]
├── Sprite2D - Visual representation
├── CollisionShape2D - Physics collision
└── WanderTimer - Controls movement timing
```

### Spawning
World.gd spawns entities in Human World during `_ready()`:
- `_spawn_civilians()` - spawns `GameConstants.CIVILIAN_COUNT` civilians
- `_spawn_animals()` - spawns `GameConstants.ANIMAL_COUNT` animals
- Entities placed at random floor tiles (avoids structures)

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
NAME                    # string - display name for UI ("Portal")
DESCRIPTION             # string - tooltip description
SPRITE_PATH             # string - path to sprite asset
COLLISION_RADIUS        # float - physics collision size
TRAVEL_TRIGGER_RADIUS   # float - area for travel detection
SPRITE_SIZE_RATIO       # float - sprite size relative to collision
ACTIVE_COLOR            # Color - visual when linked
INACTIVE_COLOR          # Color - visual when not linked
PLACEMENT_COST          # int - essence cost to place
SIGHT_RANGE             # int - tiles visible around portal (fog of war)
```

### Portal States
- **Active/Linked**: Portals are always created in both worlds simultaneously (no inactive state)

### Scene Structure (portal.tscn)
```
Portal [StaticBody2D] (PortalController.gd)
├── Sprite2D - Visual representation
├── CollisionShape2D - Physics collision
└── TravelArea [Area2D] - Detects travellable entities
	└── CollisionShape2D - Travel trigger radius
```

### Travel Mechanic
1. Any travellable entity (Dark Lord, minions, civilians, animals, enemies) enters portal's TravelArea
2. Portal grants travel immunity to prevent bounce-back at destination
3. Portal calls `World.transfer_entity_to_world()` to physically move entity to target world
4. If entity is Dark Lord, camera view switches to follow
5. Cooldown prevents rapid world-hopping

**Travellable entities**: Dark Lord, minions, civilians, animals, enemies (checked via group membership)

**Travel immunity**: Static dictionary tracks recently-traveled entities to prevent immediate re-teleport at destination portal.

**Key distinction**: World view switching (UI button, debug key) only changes which world is visible. Portal travel actually moves the entity between worlds.

---

## Building Entities

Player-placeable structures that provide various benefits.

### File Organization
```
scripts/entities/buildings/
├── PortalData.gd              # Portal constants
├── PortalController.gd        # Portal behavior
├── CorruptionNodeData.gd      # Node constants
├── CorruptionNodeController.gd # Node behavior
├── SpawningPitData.gd         # Pit constants
└── SpawningPitController.gd   # Pit behavior

scenes/entities/buildings/
├── portal.tscn
├── corruption_node.tscn
└── spawning_pit.tscn
```

### Building Types
| Type | Cost | HP | Effect |
|------|------|-----|--------|
| Portal | 20 | 100 | Travel between worlds (auto-linked, creates corruption in Human World) |
| Corruption Node | 50 | 50 | Auto-spreads corruption + essence income (+2/s) |
| Spawning Pit | 100 | 80 | Auto-spawns minions every `SPAWN_INTERVAL` seconds |

**Note:** All buildings require corrupted land to place. Buildings have HP and can be destroyed by enemies.

### Building Health
All buildings use HealthComponent for HP tracking:
- Health bars only visible when damaged (hidden at 100% HP)
- Enemies in GROUP_ENEMIES detect and attack buildings
- On destruction: building removed, effects cease (e.g., essence income stops)

### Spawning Pit Behavior
The Spawning Pit auto-spawns minions using HivePool:
- Spawns minion type defined by `Data.SPAWN_TYPE` (default: Crawler)
- Spawn interval from `Data.SPAWN_INTERVAL` (10s)
- Uses HivePool to check capacity and deduct essence cost
- Minions spawn with random offset (`Data.SPAWN_OFFSET_RATIO` of tile size)
- Automatically sets world collision for spawned minions

### Placement Flow
1. Click building button → enters build mode
2. Cursor preview shows building sprite following mouse
3. Left-click on corrupted tile → building placed (fails if not corrupted)
4. ESC or right-click cancels build mode

### Common Building Pattern
All buildings follow the same pattern:
```gdscript
const Data := preload("res://scripts/entities/buildings/YourBuildingData.gd")

func _ready() -> void:
    add_to_group(GameConstants.GROUP_BUILDINGS)
    add_to_group(GameConstants.GROUP_YOUR_BUILDING)

func setup(tile_pos: Vector2i, world: Enums.WorldType) -> void:
    # Position, register, emit signals
```

### Corruption Node Behavior
The Corruption Node auto-spreads corruption within its range:
```gdscript
# CorruptionNodeData.gd constants:
NAME, DESCRIPTION           # UI display info
SPRITE_PATH                 # Path to sprite texture
COLLISION_RADIUS            # float - physics collision size
SPRITE_SIZE_RATIO           # float - sprite size relative to collision
ACTIVE_COLOR                # Color - sprite modulate
SIGHT_RANGE                 # int - fog of war visibility
DEFAULT_COST                # int - fallback cost if not in BUILDING_STATS
DEFAULT_ESSENCE_BONUS       # int - fallback income bonus
```

Spread is controlled by `GameConstants.CORRUPTION_SPREAD_INTERVAL` and limited to `GameConstants.CORRUPTION_NODE_RANGE` tiles (Manhattan distance).

---

## Minion System

Player-controlled units that follow the Dark Lord and attack enemies.

### File Organization
```
scripts/entities/minions/
├── MinionData.gd       # Minion constants (preload pattern)
└── MinionController.gd # Minion behavior script

scenes/entities/minions/
└── minion.tscn         # Scene file
```

### Spawning
- **Hotkeys**: 1 = Crawler, 2 = Brute, 3 = Stalker
- Cost deducted from Essence
- Spawned near Dark Lord's position
- Added to HivePool for tracking

### Data Script Constants
```gdscript
const Data := preload("res://scripts/entities/minions/MinionData.gd")

# MinionData.gd constants:
COLLISION_RADIUS          # float - physics collision size
SPRITE_SIZE_RATIO         # float - sprite size relative to collision
FOLLOW_DISTANCE           # float - stay this far from Dark Lord
FOLLOW_DISTANCE_THRESHOLD # float - multiplier for when to start following again
ATTACK_RANGE              # float - range to attack enemies
ATTACK_RANGE_FACTOR       # float - move closer before attacking
ATTACK_COOLDOWN           # float - seconds between attacks
WANDER_RADIUS             # float - wander radius near Dark Lord
WANDER_SPEED_FACTOR       # float - wander speed as fraction of full speed
WANDER_ARRIVAL_DISTANCE   # float - consider arrived when this close
WANDER_DIRECTION_CHANGE_CHANCE  # int - 1 in N frames to pick new target
ORDER_ARRIVAL_DISTANCE    # float - arrival distance for player orders
SEPARATION_DISTANCE       # float - desired min distance between minions (squad spacing)
SEPARATION_STRENGTH       # float - how strongly to push apart (0-1)
SEPARATION_MOVE_THRESHOLD # float - min separation force to trigger movement
SEPARATION_UPDATE_INTERVAL # float - seconds between separation recalculations (perf)
SEPARATION_MIN_CHECK_DISTANCE # float - skip calc if entities overlap (avoid div by zero)
DEFAULT_HP                # int - fallback if MINION_STATS missing
DEFAULT_SPEED             # float - fallback if MINION_STATS missing
DEFAULT_DAMAGE            # int - fallback if MINION_STATS missing
```

### Behavior States
| State | Description |
|-------|-------------|
| FOLLOW | Move toward Dark Lord, maintain follow distance |
| ATTACK | Chase and attack enemies in range |
| WANDER | Idle movement near Dark Lord |
| MOVE_TO | Moving to player-ordered position |

### Squad Separation
Minions maintain spacing from each other using separation behavior:
- **Separation force** calculated from nearby minions within `SEPARATION_DISTANCE`
- Force strength inversely proportional to distance (closer = stronger push)
- Applied in FOLLOW, WANDER, and MOVE_TO states
- Blended with movement direction to avoid clumping while still reaching targets

### Performance Optimization
Separation uses two optimizations to handle many minions efficiently:
1. **SpatialGrid** - Spatial partitioning for O(1) neighbor lookup instead of O(n)
2. **Cached separation** - Force recalculated every `SEPARATION_UPDATE_INTERVAL` (100ms), not every frame

### Order System
- Listens to `EventBus.attack_ordered` and `EventBus.retreat_ordered` signals
- Order types with stance behavior:
  - **AGGRESSIVE**: Attack enemies while moving, stay at destination
  - **HOLD**: Move to position, stay there, attack only if attacked
  - **RETREAT**: Move to position, then return to following Dark Lord

### Combat
- Auto-attack entities in GROUP_KILLABLE (civilians, animals) and GROUP_ENEMIES (military, police, etc.)
- Damage/speed from GameConstants.MINION_STATS (with Data fallbacks)
- On death: removed from HivePool, upkeep removed

---

## Enemy System

Military forces that respond to threat level and attack the player.

### File Organization
```
scripts/entities/enemies/
├── EnemyData.gd        # Enemy constants (preload pattern)
└── EnemyController.gd  # Enemy behavior script

scenes/entities/enemies/
└── enemy.tscn          # Scene file
```

### Enemy Types
| Type | HP | Damage | Speed | Collision | Detection | Sprite | Spawns At |
|------|-----|--------|-------|-----------|-----------|--------|-----------|
| SWAT | 20 | 5 | 40 | 5.0 | 48 | Soldier | SWAT threat |
| MILITARY | 40 | 10 | 35 | 5.0 | 48 | Soldier | MILITARY threat |
| HEAVY | 80 | 20 | 25 | 10.0 | 48 | Tank | HEAVY threat |
| SPECIAL_FORCES | 50 | 15 | 45 | 5.0 | 48 | Soldier | HEAVY threat |
| PSYCHIC | 15 | 8 | 50 | 4.0 | 80 | Psych Boy | MILITARY threat |

### Stats Configuration (GameConstants.ENEMY_STATS)
Enemy combat stats use unified dictionary pattern for scalability:
```gdscript
# GameConstants.gd - balance values
const ENEMY_STATS := {
	Enums.EnemyType.SWAT: {hp = 20, damage = 5, speed = 40.0, group = "swat"},
	Enums.EnemyType.MILITARY: {hp = 40, damage = 10, speed = 35.0, group = "military"},
	Enums.EnemyType.HEAVY: {hp = 80, damage = 20, speed = 25.0, group = "heavy"},
	Enums.EnemyType.SPECIAL_FORCES: {hp = 50, damage = 15, speed = 45.0, group = "special_forces"},
	Enums.EnemyType.PSYCHIC: {hp = 15, damage = 8, speed = 50.0, group = "psychic"},
}

# EnemyController.gd setup uses dictionary lookup
func setup(type: Enums.EnemyType) -> void:
	enemy_type = type
	var stats: Dictionary = GameConstants.ENEMY_STATS[type]
	_damage = stats.damage
	_speed = stats.speed
	add_to_group(stats.group)
	# ... setup functions
```

### Per-Type Configuration (EnemyData.gd)
Entity-specific (non-balance) values like sprites and collision:
```gdscript
# Per-type sprite paths
const SPRITE_PATHS := {
	Enums.EnemyType.SWAT: "res://assets/sprites/military/military_soldier_tactical.png",
	Enums.EnemyType.HEAVY: "res://assets/sprites/military/military_tank_heavy_armored.png",
	Enums.EnemyType.PSYCHIC: "res://assets/sprites/military/psych_boy.png",
	# ...
}

# Per-type collision radii
const COLLISION_RADII := {
	Enums.EnemyType.HEAVY: 10.0,   # Tank is bigger
	Enums.EnemyType.PSYCHIC: 4.0,  # Slightly smaller
	# ...
}

# Per-type detection radii
const DETECTION_RADII := {
	Enums.EnemyType.SWAT: 48.0,
	Enums.EnemyType.PSYCHIC: 80.0,  # Extended psychic sensing range
	# ...
}
```

Sprites and detection ranges are loaded dynamically in `setup(type)` based on the enemy type.

### Behavior States
| State | Description |
|-------|-------------|
| PATROL | Wander near spawn point |
| CHASE | Pursue detected threats |
| ATTACK | Attack threats in range |
| INVESTIGATE | Move to alarm location (triggered by alarm towers) |

### Combat Targeting
- Detects and attacks entities in GROUP_THREATS (Dark Lord, minions)
- Also attacks player buildings in GROUP_BUILDINGS (portals, corruption nodes, spawning pits)
- Buildings have HP and can be destroyed

### Alarm Response
When an alarm tower is triggered, nearby enemies receive `investigate_position(target_pos)`:
- Only interrupts PATROL or INVESTIGATE states (not combat)
- Moves at full speed to alarm location
- If threat detected while investigating → switches to CHASE
- Returns to PATROL after reaching investigation point

### Spawning
- Triggered by threat level changes (corruption %)
- Spawns at map edges in Human World
- Random spawning (independent of threat) with configurable weights
- Max count limits per type

---

## Alarm Tower System

Human defense structures that civilians flee toward when threatened.

### File Organization
```
scripts/entities/buildings/
├── AlarmTowerData.gd       # Alarm tower constants (preload pattern)
└── AlarmTowerController.gd # Alarm tower behavior

scenes/entities/buildings/
└── alarm_tower.tscn        # Scene file
```

### Mechanic Flow
1. Civilian detects threat (Dark Lord, minions)
2. Civilian searches for nearest alarm tower within `ALARM_TOWER_SEARCH_RADIUS` (200px)
3. If found → civilian enters `FLEE_TO_ALARM` state, runs toward tower
4. If not found → civilian enters `FLEE` state, runs away from threat
5. Fleeing civilian reaches tower's trigger area → alarm activates
6. Alarm effect:
   - Threat level increases by `ALARM_THREAT_INCREASE` (1 level)
   - Nearby enemies within `ALARM_ENEMY_ATTRACT_RADIUS` (128px) investigate
   - Tower goes on cooldown (`ALARM_COOLDOWN` = 30s)
   - Civilian calms down

### Data Script Constants (AlarmTowerData.gd)
```gdscript
SPRITE_PATH             # Path to alarm tower sprite
COLLISION_RADIUS        # 8.0 - physical collision size
SPRITE_SIZE_RATIO       # 1.5 - visual size relative to collision
TRIGGER_RADIUS          # 20.0 - civilians can trigger within this range
ALARM_COOLDOWN          # 30.0s - time before tower can be triggered again
ALARM_FLASH_DURATION    # 0.5s - visual feedback animation duration

# Visual colors
ACTIVE_COLOR            # Normal state (white)
ALARM_COLOR             # When triggered (red flash)
COOLDOWN_COLOR          # During cooldown (gray)
```

### GameConstants
```gdscript
GROUP_ALARM_TOWERS          # "alarm_towers" - group name
ALARM_TOWER_COUNT           # 3 - towers spawned per map
ALARM_THREAT_INCREASE       # 1 - threat levels gained when triggered
ALARM_ENEMY_ATTRACT_RADIUS  # 128.0px - enemies within this respond
```

### Civilian Flee Behavior (CivilianData.gd)
```gdscript
ALARM_TOWER_SEARCH_RADIUS   # 200.0px - max distance to find alarm tower
ALARM_TOWER_ARRIVAL_DISTANCE # 16.0px - close enough to trigger
```

### Civilian States
| State | Description |
|-------|-------------|
| WANDER | Normal wandering behavior |
| FLEE | Running away from threat (no tower found) |
| FLEE_TO_ALARM | Running toward nearest alarm tower |

### Signal
```gdscript
EventBus.alarm_triggered(position: Vector2)  # Emitted when alarm activates
```

### Scene Structure (alarm_tower.tscn)
```
AlarmTower [StaticBody2D] (AlarmTowerController.gd)
├── Sprite2D - Visual representation
├── CollisionShape2D - Physics collision
├── TriggerArea [Area2D] - Detects civilians
│   └── CollisionShape2D - Trigger radius
└── CooldownTimer - Prevents spam triggering
```

---

## Policeman Entity

Human world law enforcement that randomly chooses to fight or flee when detecting threats.

### File Organization
```
scripts/entities/humans/
├── PolicemanData.gd       # Policeman constants (preload pattern)
└── PolicemanController.gd # Policeman behavior script

scenes/entities/humans/
└── policeman.tscn         # Scene file
```

### Fight/Flight Decision
When a policeman first detects a threat (Dark Lord, minions):
- 50% chance to FIGHT: Chase and attack the threat
- 50% chance to FLEE: Run toward alarm tower (or just flee if none found)

Decision is made once per encounter and persists until threat leaves detection range.

### Behavior States
| State | Description |
|-------|-------------|
| WANDER | Normal wandering behavior |
| FLEE | Running away from threat (no tower or chose to flee) |
| FLEE_TO_ALARM | Running toward nearest alarm tower |
| CHASE | Pursuing detected threat (chose to fight) |
| ATTACK | Attacking target in range |

### Data Script Constants (PolicemanData.gd)
```gdscript
SPRITE_PATH              # Path to policeman sprite
COLLISION_RADIUS         # 5.0 - physical collision size
SPRITE_SIZE_RATIO        # 1.0 - visual size relative to collision

# Movement
WANDER_SPEED             # 30.0 - normal movement
WANDER_INTERVAL_MIN/MAX  # Wait time between moves

# Flee behavior (when choosing to run)
FLEE_SPEED               # 45.0 - faster than wander
FLEE_DETECTION_RADIUS    # 56.0 (~3.5 tiles) - slightly better awareness than civilians
FLEE_SAFE_DISTANCE       # 80.0 (5 tiles) - stop fleeing when this far

# Fight behavior (when choosing to fight)
CHASE_SPEED              # 40.0 - pursuit speed
ATTACK_RANGE             # 14.0 - melee attack range
ATTACK_COOLDOWN          # 0.8s - between attacks

# Behavior chance
FIGHT_CHANCE             # 50 (0-100) - % chance to fight vs flee

# Alarm tower seeking
ALARM_TOWER_SEARCH_RADIUS    # 200.0px - same as civilians
ALARM_TOWER_ARRIVAL_DISTANCE # 16.0px - close enough to trigger
```

### GameConstants
```gdscript
GROUP_POLICEMEN               # "policemen" - group name
GROUP_POLICE_STATIONS         # "police_stations" - police station buildings
POLICE_STATION_COUNT          # 2 - police stations spawned per map
MAX_POLICEMEN_PER_STATION     # 5 - max policemen each station maintains
POLICE_STATION_SPAWN_INTERVAL # 5.0 - seconds between policeman spawn attempts
POLICEMAN_HP                  # 25 - higher than civilians
POLICEMAN_DAMAGE              # 5 - can hurt Dark Lord/minions
ESSENCE_PER_POLICEMAN         # 15 - reward for killing
```

### Police Stations
- Spawn randomly on the map (like alarm towers)
- Each station spawns and maintains up to MAX_POLICEMEN_PER_STATION policemen
- Policemen spawn near their station every POLICE_STATION_SPAWN_INTERVAL seconds (if under max count)
- Dead policemen are automatically replaced over time

### Combat
- Policemen can damage Dark Lord and minions
- Uses HealthComponent for HP tracking
- Adds to GROUP_KILLABLE (can be killed by player forces)
- Awards essence when killed

### Alarm Tower Interaction
Policemen can trigger alarm towers when fleeing (same as civilians):
- Implements `is_fleeing() -> bool` for alarm tower detection
- Implements `on_alarm_triggered()` callback to calm down after triggering

### Scene Structure (policeman.tscn)
```
Policeman [CharacterBody2D] (PolicemanController.gd)
├── Sprite2D - Visual representation
├── CollisionShape2D - Physics collision
├── WanderTimer - Controls movement timing
├── DetectionArea [Area2D] - Detects threats for fight/flee decision
│   └── CollisionShape2D - Detection radius
├── AttackRange [Area2D] - Detects targets to attack
│   └── CollisionShape2D - Attack radius
└── AttackTimer - Cooldown between attacks
```

---

## Military Portals

Human military gateways that spawn when threat level reaches 70%. Enemies walk through to invade the Corrupted World.

### GameConstants
```gdscript
GROUP_MILITARY_PORTALS           # "military_portals" - group name
MILITARY_PORTAL_THREAT_THRESHOLD # 0.7 - threat level to start spawning
MILITARY_PORTAL_SPAWN_INTERVAL   # 30.0 - seconds between portal spawns
MILITARY_PORTAL_MAX_COUNT        # 3 - max portals on map
```

### Behavior
- Spawn at map edges when threat >= 70% (every 30 seconds)
- Enemies (from regular spawning) walk through to enter Corrupted World
- One-way travel: Human World → Corrupted World
- Player cannot close or destroy military portals
- Up to 3 portals can exist simultaneously

### Scene Structure (military_portal.tscn)
```
MilitaryPortal [StaticBody2D] (MilitaryPortalController.gd)
├── Sprite2D - Visual representation
├── CollisionShape2D - Physics collision
└── TravelArea [Area2D] - Detects enemies entering portal
    └── CollisionShape2D - Travel trigger radius
```

---

## Game Over Screen

Win/lose UI overlay that pauses the game and allows restart.

### File Organization
```
scripts/ui/
└── GameOverScreen.gd

scenes/ui/
└── game_over_screen.tscn
```

### Triggers
- **Win**: Corruption reaches WIN_THRESHOLD (80%)
- **Lose - Dark Lord**: Dark Lord HP reaches 0
- **Lose - Corruption**: All corruption cleared in Dark World

### Connected Signals
```gdscript
EventBus.game_won  → _on_game_won()
EventBus.game_lost → _on_game_lost()
```

---

## Evolve Modal

Placeholder modal for the minion evolution system.

### File Organization
```
scripts/ui/
└── EvolveModal.gd

scenes/ui/
└── evolve_modal.tscn
```

### Features
- Opens when Evolve button clicked (`evolve_modal_requested` signal)
- Pauses game while open
- ESC or Close button to dismiss
- Uses UITheme for consistent styling

### Scene Structure
```
EvolveModal [CanvasLayer, layer=10, process_mode=ALWAYS]
├── ColorRect - Semi-transparent overlay
└── Panel [PanelContainer]
	└── VBox [VBoxContainer]
		├── TitleLabel
		├── ContentLabel
		└── CloseBtn
```

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

### Continuous Fog Reveal During Movement
For smooth fog reveal as entities move (not just when stopping), track the last tile position:
```gdscript
# Use a constant for the invalid position marker
var _last_tile_pos: Vector2i = Data.INVALID_TILE_POS  # or Vector2i(-999, -999) if no Data

func _check_fog_update() -> void:
	var current_tile := Vector2i(global_position / GameConstants.TILE_SIZE)
	if current_tile != _last_tile_pos:
		_last_tile_pos = current_tile
		EventBus.fog_update_requested.emit(WorldManager.active_world)
```
Call `_check_fog_update()` in `_ready()` and during movement (e.g., in `_move_toward_target()`).

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

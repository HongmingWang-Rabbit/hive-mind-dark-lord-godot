# World System

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

---

## Manager Architecture

World.gd is an orchestrator that delegates to specialized managers:

```
scripts/world/
├── World.gd              # Orchestrator (~390 lines)
├── MapGenerator.gd       # Procedural map generation
├── CorruptionManager.gd  # Corruption spreading and tracking
├── FogManager.gd         # Fog of war visibility
├── EntitySpawner.gd      # Entity spawning (Dark Lord, civilians, animals, minions)
├── EnemySpawner.gd       # Threat-based enemy spawning
└── InputManager.gd       # Input handling, cursor preview, interaction modes
```

### Manager Pattern
All managers extend `RefCounted` (lightweight, not Nodes). World.gd keeps lifecycle methods (`_ready`, `_process`, `_unhandled_input`) and delegates to managers.

```gdscript
# In World.gd
const MapGenerator := preload("res://scripts/world/MapGenerator.gd")

var _map_generator: RefCounted

func _ready() -> void:
    _map_generator = MapGenerator.new()
    _map_generator.setup(self, map_width, map_height)

func _process(delta: float) -> void:
    _enemy_spawner.process(delta)  # Delegate timer updates
```

### Manager Responsibilities

| Manager | Responsibility |
|---------|----------------|
| MapGenerator | Procedural terrain (floors, buildings, props), occupied tiles tracking |
| CorruptionManager | Corruption spreading, per-world tracking, corruption % |
| FogManager | Fog of war visibility, tile reveal |
| EntitySpawner | Spawn Dark Lord, civilians, animals, minions |
| EnemySpawner | Threat-based enemy spawning, spawn timers |
| InputManager | Input handling, cursor preview, interaction modes |

---

## World.gd Responsibilities

World.gd is the orchestrator that:
1. Holds all `@onready` node references (tilemap layers, entity containers)
2. Creates and wires up managers in `_ready()`
3. Delegates `_process()` to managers that need frame updates
4. Delegates `_unhandled_input()` to InputManager
5. Provides public API for other systems (corruption, fog, entity transfer)
6. Handles building placement (uses corruption manager)
7. Manages world switching visibility

### Tile Layers (per world)
| Layer | Human World | Corrupted World |
|-------|-------------|-----------------|
| FloorMap | `human_floor_map` | `corrupted_floor_map` |
| StructureMap | `human_structure_map` | `corrupted_structure_map` |
| CorruptionMap | `human_corruption_map` | `corrupted_corruption_map` |
| Entities | `human_entities` | `corrupted_entities` |
| FogMap | `human_fog_map` | `corrupted_fog_map` |

### World Collision Separation
Each world uses separate collision layers so entities don't physically interact across worlds:
- **Layer 4**: Corrupted World entities
- **Layer 5**: Human World entities
- **Layer 2**: Threat detection (Dark Lord, minions - for flee behavior)

Entities implement `set_world_collision(world)` to update their collision layer/mask.

### Public API
```gdscript
get_entities_container(world)                    # Get Entities node for a world
transfer_entity_to_world(entity, target_world)   # Move entity between worlds
is_tile_corrupted(pos, world)                    # Check corruption
corrupt_tile(pos, world)                         # Corrupt single tile
corrupt_area_around(center, world, radius)       # Corrupt area
update_fog(world)                                # Update fog visibility
execute_build(tile_pos, building_type)           # Place building
```

### Export Variables
```gdscript
@export var use_procedural_generation := true
@export var override_map_size := false
@export var custom_map_width := GameConstants.MAP_WIDTH
@export var custom_map_height := GameConstants.MAP_HEIGHT
```

---

## MapGenerator.gd

Handles procedural map generation for both worlds.

### Key Functions
```gdscript
setup(world, map_width, map_height)  # Initialize with references
generate_map()                        # Full procedural generation
count_existing_tiles()                # Count tiles for non-procedural maps
is_floor_tile(pos)                    # Check if position is valid floor
```

### State
- `occupied_tiles: Dictionary` - Tiles with structures
- `total_tiles: int` - Total floor tile count
- `initial_corruption_tile: Vector2i` - Starting corruption position

---

## CorruptionManager.gd

Manages corruption spreading and tracking in both worlds.

### Key Functions
```gdscript
setup(world, fog_manager)                     # Initialize with references
corrupt_tile(pos, world)                       # Corrupt single tile
spread_corruption()                            # Spread to random adjacent
is_tile_corrupted(pos, world)                  # Check if corrupted
can_corrupt_tile(pos, world)                   # Check if can corrupt
corrupt_area_around(center, world, radius)     # Corrupt area
clear_corruption(pos)                          # Clear corruption (Human World)
```

### State
- `human_corrupted_tiles: Dictionary` - Corruption in Human World
- `corrupted_corrupted_tiles: Dictionary` - Corruption in Corrupted World

### How It Works
- Game starts with one Corruption Node in Corrupted World at center
- Corruption Nodes auto-spread corruption every `CORRUPTION_SPREAD_INTERVAL` seconds
- Spread is limited to `CORRUPTION_NODE_RANGE` tiles (Manhattan distance)
- Buildings can only be placed on corrupted tiles
- Portals create `PORTAL_INITIAL_CORRUPTION_RANGE` tiles of corruption in Human World

---

## FogManager.gd

Manages fog of war visibility in both worlds.

### Key Functions
```gdscript
setup(world, map_width, map_height)  # Initialize with references
setup_fog()                           # Fill fog for both worlds
reveal_tile(pos, world)               # Reveal single tile
reveal_initial_corruption(pos)        # Reveal starting area
update_fog(world)                     # Update based on entity sight
```

### State
- `_human_explored_tiles: Dictionary` - Revealed tiles in Human World
- `_corrupted_explored_tiles: Dictionary` - Revealed tiles in Corrupted World

Fog clears permanently when explored (no re-fogging for jam scope). In Corrupted World, corruption spread auto-reveals tiles.

### Entity Visibility Interface
Entities that reveal fog implement `get_visible_tiles() -> Array[Vector2i]`:
```gdscript
const FogUtils := preload("res://scripts/utils/fog_utils.gd")

func get_visible_tiles() -> Array[Vector2i]:
    var center := Vector2i(global_position / GameConstants.TILE_SIZE)
    return FogUtils.get_tiles_in_sight_range(center, Data.SIGHT_RANGE)
```

---

## EntitySpawner.gd

Handles spawning of Dark Lord, civilians, animals, and minions.

### Key Functions
```gdscript
setup(world, map_generator, map_width, map_height)
spawn_dark_lord(initial_tile)          # Spawn Dark Lord at position
spawn_initial_corruption_node(tile)     # Spawn starting corruption node
spawn_human_world_entities()            # Spawn civilians and animals
spawn_minion(type) -> bool              # Spawn minion near Dark Lord
get_dark_lord_world() -> WorldType      # Get Dark Lord's current world
```

### State
- `dark_lord: CharacterBody2D` - Reference to Dark Lord entity

---

## EnemySpawner.gd

Handles threat-based enemy spawning.

### Key Functions
```gdscript
setup(world, map_generator, map_width, map_height)
process(delta)     # Update spawn timers (called by World._process)
reset()            # Reset all timers
```

### Spawn Logic
- Police spawn at POLICE threat and above
- Military spawn at MILITARY threat and above
- Heavy spawn at HEAVY threat
- Random enemies spawn independently if enabled

---

## InputManager.gd

Handles input, interaction modes, and cursor preview.

### Key Functions
```gdscript
setup(world, camera, entity_spawner, corruption_manager)
handle_input(event) -> bool    # Process input event
update_cursor_preview()        # Update cursor position (called by World._process)
```

### Interaction Modes
- `NONE` - Default, left-click moves Dark Lord
- `BUILD` - Building placement mode, cursor shows building preview
- `ORDER` - Order mode, cursor shows target indicator

### State
- `cursor_preview: Sprite2D` - Building preview sprite (World adds to tree)
- `order_cursor: Sprite2D` - Order target sprite (World adds to tree)
- `_interaction_mode: InteractionMode` - Current mode
- `_building_textures: Dictionary` - Cached building textures

---

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

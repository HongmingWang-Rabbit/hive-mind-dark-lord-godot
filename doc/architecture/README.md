# Technical Architecture

This folder contains modular documentation for the game's technical architecture.

## Documentation Index

| File | Description |
|------|-------------|
| [constants.md](constants.md) | GameConstants reference, Enums |
| [signals.md](signals.md) | EventBus signals |
| [systems.md](systems.md) | Autoloads (SpatialGrid, WorldManager, etc.) |
| [world.md](world.md) | World.gd, Scene Tree, Corruption, Fog of War |
| [entities.md](entities.md) | Dark Lord, Minions, Enemies, Human Entities |
| [buildings.md](buildings.md) | Portal, Corruption Node, Spawning Pit |
| [ui.md](ui.md) | HUD, UITheme, Game Over Screen |
| [guides.md](guides.md) | How to add new features |

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
Tile atlas coordinates for the current tileset. Uses preload pattern for reliable constant access at parse time. Change this file to swap tilesets.

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
- Green bar when HP > 60%
- Yellow bar when HP 30-60%
- Red bar when HP < 30%
All visual constants in GameConstants (HEALTH_BAR_*)

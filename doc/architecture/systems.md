# System Autoloads

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

---

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

---

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

---

## ThreatSystem.gd

Autoload that manages threat level from multiple modular sources.

### Design
- **Float-based**: Threat is 0.0-1.0 instead of discrete enum levels
- **Multi-source**: Multiple sources can contribute (corruption, sightings, alarms)
- **Max wins**: Final threat = max(all sources)
- **Only increases**: Threat never decreases during gameplay
- **Scalable**: New sources can be added without modifying ThreatSystem

### Public API
```gdscript
set_source(source_id: String, value: float)  # Add/update a threat source
remove_source(source_id: String)             # Remove source (mainly for reset)
get_threat_value() -> float                  # Get current threat (0.0-1.0)
get_threat_level() -> Enums.ThreatLevel      # Get enum tier for spawning
get_source_value(source_id: String) -> float # Get specific source value
reset()                                      # Clear all sources
```

### Built-in Sources
| Source | Trigger | Value |
|--------|---------|-------|
| `corruption` | Corruption 20-80% | 0.0-1.0 (linear) |
| `military_sighting` | Military sees Dark Lord | 0.5 floor |
| `alarm_tower` | Civilian triggers alarm | 0.5 floor |

### Enum Thresholds
```gdscript
# GameConstants.THREAT_LEVEL_THRESHOLDS = [0.25, 0.5, 0.75]
0.0-0.25  → NONE
0.25-0.5  → POLICE
0.5-0.75  → MILITARY
0.75-1.0  → HEAVY
```

### Adding New Threat Sources
```gdscript
# From anywhere in the codebase:
ThreatSystem.set_source("boss_spotted", 0.75)

# Or with constants (recommended):
ThreatSystem.set_source(
    GameConstants.THREAT_SOURCE_BOSS_SPOTTED,
    GameConstants.THREAT_BOSS_SPOTTED_FLOOR
)
```

### Signals
Emits via EventBus when threat changes:
- `threat_value_changed(new_value: float, old_value: float)` - Float value changed
- `threat_level_changed(new_level: Enums.ThreatLevel)` - Enum tier changed

---

## System Reset Flow

```gdscript
GameManager.reset_game()  # Resets all systems
    → Essence.reset()     # Reset to STARTING_ESSENCE
    → HivePool.reset()    # Clear all minion pools
    → WorldManager.reset() # Reset to CORRUPTED world, clear portals
    → SpatialGrid.reset() # Clear spatial grid
    → ThreatSystem.reset() # Clear all threat sources
```

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

## System Reset Flow

```gdscript
GameManager.reset_game()  # Resets all systems
    → Essence.reset()     # Reset to STARTING_ESSENCE
    → HivePool.reset()    # Clear all minion pools
    → WorldManager.reset() # Reset to CORRUPTED world, clear portals
    → SpatialGrid.reset() # Clear spatial grid
```

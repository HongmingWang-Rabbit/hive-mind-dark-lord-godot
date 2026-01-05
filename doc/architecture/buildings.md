# Building Entities

Player-placeable structures that provide various benefits.

## File Organization
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

## Building Types
| Type | Cost | Effect |
|------|------|--------|
| Portal | 20 | Travel between worlds (auto-linked, creates corruption in Human World) |
| Corruption Node | 50 | Auto-spreads corruption + essence income (+2/s) |
| Spawning Pit | 100 | Auto-spawns minions every `SPAWN_INTERVAL` seconds |

**Note:** All buildings require corrupted land to place.

## Placement Flow
1. Click building button → enters build mode
2. Cursor preview shows building sprite following mouse
3. Left-click on corrupted tile → building placed (fails if not corrupted)
4. ESC or right-click cancels build mode

## Common Building Pattern
All buildings follow the same pattern:
```gdscript
const Data := preload("res://scripts/entities/buildings/YourBuildingData.gd")

func _ready() -> void:
    add_to_group(GameConstants.GROUP_BUILDINGS)
    add_to_group(GameConstants.GROUP_YOUR_BUILDING)

func setup(tile_pos: Vector2i, world: Enums.WorldType) -> void:
    # Position, register, emit signals
```

---

## Portal Entity

Player-placeable buildings that allow travel between worlds when linked.

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

## Corruption Node Entity

Auto-spreads corruption within its range and provides passive essence income.

### Data Script Constants
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

### Behavior
- Spread controlled by `GameConstants.CORRUPTION_SPREAD_INTERVAL`
- Limited to `GameConstants.CORRUPTION_NODE_RANGE` tiles (Manhattan distance)
- Provides passive essence income

---

## Spawning Pit Entity

Auto-spawns minions using HivePool.

### Behavior
- Spawns minion type defined by `Data.SPAWN_TYPE` (default: Crawler)
- Spawn interval from `Data.SPAWN_INTERVAL` (10s)
- Uses HivePool to check capacity and deduct essence cost
- Minions spawn with random offset (`Data.SPAWN_OFFSET_RATIO` of tile size)
- Automatically sets world collision for spawned minions

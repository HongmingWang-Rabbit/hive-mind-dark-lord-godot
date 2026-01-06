# Entities

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
WANDER_SPEED        # float - movement speed when wandering
MOVE_SPEED          # float - movement speed when player commands (faster)
WANDER_INTERVAL_MIN # float - min wait between moves
WANDER_INTERVAL_MAX # float - max wait between moves
SIGHT_RANGE         # int - tiles visible around Dark Lord (fog of war)

# Combat balance values are in GameConstants:
# DARK_LORD_HP, DARK_LORD_DAMAGE, DARK_LORD_ATTACK_RANGE, DARK_LORD_ATTACK_COOLDOWN
```

### Current Behavior
- **Click-to-move**: Player left-clicks to move Dark Lord to position (uses `MOVE_SPEED`)
- Wanders randomly in 8 directions when idle (uses `WANDER_SPEED`)
- Moves one tile at a time when wandering
- Waits random interval between wandering moves
- Reveals fog in sight range when moving (via `get_visible_tiles()`)
- **Auto-attacks** killable entities (civilians, animals) in range
- Listens to `EventBus.dark_lord_move_ordered` signal for player commands

### Combat System
- **AttackRange Area2D** detects entities in `GROUP_KILLABLE` group
- Auto-attacks target with `GameConstants.DARK_LORD_DAMAGE`
- Attack cooldown prevents spam (`Data.ATTACK_COOLDOWN`)
- Calls `take_damage()` on target entities
- When target HP depletes: entity dies, Dark Lord gains essence

### Scene Structure (dark_lord.tscn)
```
DarkLord [CharacterBody2D] (DarkLordController.gd)
├── Sprite2D - Visual representation (scale derived from COLLISION_RADIUS)
├── CollisionShape2D - Physics collision (radius from Data.COLLISION_RADIUS)
├── WanderTimer - Controls movement timing
├── AttackTimer - Cooldown between attacks (one_shot)
└── AttackRange [Area2D] - Detects killable entities
    └── CollisionShape2D - Attack detection radius
```

---

## Human World Entities

Civilians and animals spawn in Human World, wander randomly, and provide essence when killed by the Dark Lord.

### File Organization
```
scripts/entities/humans/
├── CivilianData.gd       # Civilian constants (preload pattern)
├── CivilianController.gd # Civilian behavior
├── AnimalData.gd         # Animal constants (preload pattern)
└── AnimalController.gd   # Animal behavior

scenes/entities/humans/
├── civilian.tscn         # Civilian scene
└── animal.tscn           # Animal scene
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
- Auto-attack entities in GROUP_KILLABLE
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
| Type | HP | Damage | Speed | Spawns At |
|------|-----|--------|-------|-----------|
| SWAT | 20 | 5 | 40 | SWAT threat |
| MILITARY | 40 | 10 | 35 | MILITARY threat |
| HEAVY | 80 | 20 | 25 | HEAVY threat |
| SPECIAL_FORCES | 50 | 15 | 45 | HEAVY threat (Dark World invasion) |

### Behavior States
| State | Description |
|-------|-------------|
| PATROL | Wander near spawn point |
| CHASE | Pursue detected threats |
| ATTACK | Attack threats in range |

### Spawning
- Triggered by threat level changes (corruption %)
- Spawns at map edges in Human World
- Max count limits per type

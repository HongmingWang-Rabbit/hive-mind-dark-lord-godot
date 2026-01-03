extends RefCounted
## Minion configuration - entity-specific values (non-balance)
## Use preload pattern: const Data := preload("res://scripts/entities/minions/MinionData.gd")
##
## Combat/cost values come from GameConstants.MINION_STATS

const COLLISION_RADIUS := 4.0
const SPRITE_SIZE_RATIO := 1.0

# AI behavior
const FOLLOW_DISTANCE := 32.0  # Stay this far from Dark Lord when following
const FOLLOW_DISTANCE_THRESHOLD := 1.5  # Multiplier for when to start following again
const ATTACK_RANGE := 12.0  # Range to attack enemies
const ATTACK_RANGE_FACTOR := 0.8  # Move closer than full range before attacking
const ATTACK_COOLDOWN := 0.5  # Seconds between attacks
const WANDER_RADIUS := 24.0  # Wander radius when idle near Dark Lord
const WANDER_SPEED_FACTOR := 0.5  # Wander at this fraction of full speed
const WANDER_ARRIVAL_DISTANCE := 4.0  # Consider arrived when this close
const WANDER_DIRECTION_CHANGE_CHANCE := 60  # 1 in N frames to pick new wander target

# Order behavior
const ORDER_ARRIVAL_DISTANCE := 8.0  # Consider arrived at order target when this close

# Squad separation (keep minions from clumping)
const SEPARATION_DISTANCE := 16.0  # Desired min distance between minions
const SEPARATION_STRENGTH := 0.6  # How strongly to push apart (0-1)
const SEPARATION_MOVE_THRESHOLD := 0.1  # Min separation force to trigger movement

# Default fallbacks (used if GameConstants.MINION_STATS missing entry)
const DEFAULT_HP := 10
const DEFAULT_SPEED := 60.0
const DEFAULT_DAMAGE := 2

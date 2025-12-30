extends RefCounted
## Minion configuration - entity-specific values (non-balance)
## Use preload pattern: const Data := preload("res://scripts/entities/minions/MinionData.gd")
##
## Combat/cost values come from GameConstants.MINION_STATS

const COLLISION_RADIUS := 4.0
const SPRITE_SIZE_RATIO := 1.0

# AI behavior
const FOLLOW_DISTANCE := 32.0  # Stay this far from Dark Lord when following
const ATTACK_RANGE := 12.0  # Range to attack enemies
const WANDER_RADIUS := 24.0  # Wander radius when idle near Dark Lord
const WANDER_INTERVAL := 0.5  # Time between wander position updates

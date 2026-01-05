extends RefCounted
## Dark Lord configuration - entity-specific values (non-balance)
## Use preload pattern: const Data := preload("res://scripts/entities/dark_lord/DarkLordData.gd")
##
## Combat balance values (HP, damage, attack range/cooldown) are in GameConstants

const COLLISION_RADIUS := 10.0
const SPRITE_SIZE_RATIO := 1.2  # Sprite visual size relative to collision diameter (1.0 = match collision)
const WANDER_SPEED := 30.0
const MOVE_SPEED := 80.0  # Speed when player commands movement (faster than wander)
const CHASE_SPEED := 70.0  # Speed when chasing enemies
const WANDER_INTERVAL_MIN := 1.0
const WANDER_INTERVAL_MAX := 3.0

# Combat detection
const DETECTION_RADIUS := 64.0  # Pixels - range to detect and chase enemies (4 tiles)

# Fog of war
const SIGHT_RANGE := 6  # Tiles visible around Dark Lord

# Initial/invalid tile position marker
const INVALID_TILE_POS := Vector2i(-999, -999)

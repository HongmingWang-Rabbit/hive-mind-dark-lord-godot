extends RefCounted
## Animal configuration - entity-specific values (non-balance)
## Use preload pattern: const Data := preload("res://scripts/entities/humans/AnimalData.gd")
##
## Balance values (HP, essence rewards) are in GameConstants for easy tuning

const COLLISION_RADIUS := 4.0
const SPRITE_SIZE_RATIO := 1.0

# Movement
const WANDER_SPEED := 15.0  # Slower than civilians
const WANDER_INTERVAL_MIN := 2.0
const WANDER_INTERVAL_MAX := 5.0

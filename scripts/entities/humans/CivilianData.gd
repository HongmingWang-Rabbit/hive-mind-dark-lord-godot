extends RefCounted
## Civilian configuration - entity-specific values (non-balance)
## Use preload pattern: const Data := preload("res://scripts/entities/humans/CivilianData.gd")
##
## Balance values (HP, essence rewards) are in GameConstants for easy tuning

const COLLISION_RADIUS := 5.0
const SPRITE_SIZE_RATIO := 1.0

# Movement
const WANDER_SPEED := 25.0
const WANDER_INTERVAL_MIN := 1.0
const WANDER_INTERVAL_MAX := 3.0

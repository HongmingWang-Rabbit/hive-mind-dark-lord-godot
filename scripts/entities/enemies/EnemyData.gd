extends RefCounted
## Enemy configuration - entity-specific values (non-balance)
## Use preload pattern: const Data := preload("res://scripts/entities/enemies/EnemyData.gd")
##
## Combat stats (HP, damage, speed) come from GameConstants

const COLLISION_RADIUS := 5.0
const SPRITE_SIZE_RATIO := 1.0

# AI behavior
const PATROL_RADIUS := 64.0  # How far to patrol from spawn point
const ATTACK_RANGE := 14.0  # Range to attack threats
const DETECTION_RADIUS := 48.0  # Range to detect threats
const PATROL_INTERVAL := 2.0  # Time between patrol destination changes

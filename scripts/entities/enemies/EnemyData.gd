extends RefCounted
## Enemy configuration - entity-specific values (non-balance)
## Use preload pattern: const Data := preload("res://scripts/entities/enemies/EnemyData.gd")
##
## Combat stats (HP, damage, speed) come from GameConstants

# Default values (used if type not in dictionaries)
const COLLISION_RADIUS := 5.0
const SPRITE_SIZE_RATIO := 1.0

# Per-type sprite paths
const SPRITE_PATHS := {
	Enums.EnemyType.SWAT: "res://assets/sprites/military/military_soldier_tactical.png",
	Enums.EnemyType.MILITARY: "res://assets/sprites/military/military_soldier_tactical.png",
	Enums.EnemyType.HEAVY: "res://assets/sprites/military/military_tank_heavy_armored.png",
	Enums.EnemyType.SPECIAL_FORCES: "res://assets/sprites/military/military_soldier_tactical.png",
	Enums.EnemyType.PSYCHIC: "res://assets/sprites/military/psych_boy.png",
}

# Per-type collision radii (heavy units are larger)
const COLLISION_RADII := {
	Enums.EnemyType.SWAT: 5.0,
	Enums.EnemyType.MILITARY: 5.0,
	Enums.EnemyType.HEAVY: 10.0,  # Tank is bigger
	Enums.EnemyType.SPECIAL_FORCES: 5.0,
	Enums.EnemyType.PSYCHIC: 4.0,  # Slightly smaller
}

# Per-type sprite size ratios
const SPRITE_SIZE_RATIOS := {
	Enums.EnemyType.SWAT: 1.0,
	Enums.EnemyType.MILITARY: 1.0,
	Enums.EnemyType.HEAVY: 1.5,  # Tank sprite displayed larger
	Enums.EnemyType.SPECIAL_FORCES: 1.0,
	Enums.EnemyType.PSYCHIC: 0.9,  # Slightly smaller sprite
}

# Per-type detection radii
const DETECTION_RADII := {
	Enums.EnemyType.SWAT: 48.0,
	Enums.EnemyType.MILITARY: 48.0,
	Enums.EnemyType.HEAVY: 48.0,
	Enums.EnemyType.SPECIAL_FORCES: 48.0,
	Enums.EnemyType.PSYCHIC: 80.0,  # Extended psychic sensing range
}

# AI behavior
const PATROL_RADIUS := 64.0  # How far to patrol from spawn point
const PATROL_SPEED_FACTOR := 0.5  # Patrol at this fraction of full speed
const PATROL_ARRIVAL_DISTANCE := 4.0  # Consider arrived when this close
const ATTACK_RANGE := 14.0  # Range to attack threats
const ATTACK_RANGE_FACTOR := 0.8  # Move closer than full range before attacking
const ATTACK_COOLDOWN := 0.5  # Seconds between attacks
const DETECTION_RADIUS := 48.0  # Range to detect threats
const PATROL_INTERVAL := 2.0  # Time between patrol destination changes

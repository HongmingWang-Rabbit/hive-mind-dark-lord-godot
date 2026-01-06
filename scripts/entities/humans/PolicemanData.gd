extends RefCounted
## Policeman configuration - entity-specific values (non-balance)
## Use preload pattern: const Data := preload("res://scripts/entities/humans/PolicemanData.gd")
##
## Policemen are human world entities that randomly choose to fight or flee when threatened.
## Balance values (HP, damage, essence rewards) are in GameConstants

const SPRITE_PATH := "res://assets/sprites/humans/police.png"
const COLLISION_RADIUS := 5.0
const SPRITE_SIZE_RATIO := 1.0

# Movement
const WANDER_SPEED := 30.0
const WANDER_INTERVAL_MIN := 1.5
const WANDER_INTERVAL_MAX := 4.0

# Flee behavior (when choosing to run)
const FLEE_SPEED := 45.0
const FLEE_DETECTION_RADIUS := 56.0  # 3.5 tiles - slightly better awareness than civilians
const FLEE_SAFE_DISTANCE := 80.0  # 5 tiles

# Fight behavior (when choosing to fight)
const CHASE_SPEED := 40.0
const ATTACK_RANGE := 14.0  # Range to attack threats
const ATTACK_COOLDOWN := 0.8  # Seconds between attacks

# Behavior chance (0-100)
const FIGHT_CHANCE := 50  # 50% chance to fight, 50% to flee

# Alarm tower seeking (same as civilian)
const ALARM_TOWER_SEARCH_RADIUS := 200.0
const ALARM_TOWER_ARRIVAL_DISTANCE := 16.0

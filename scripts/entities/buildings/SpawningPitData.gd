extends RefCounted
## Spawning Pit configuration - allows spawning minions at this location
## Use preload pattern: const Data := preload("res://scripts/entities/buildings/SpawningPitData.gd")

# Display info
const NAME := "Spawning Pit"
const DESCRIPTION := "Auto-spawns minions every 10s"

const SPRITE_PATH := "res://assets/sprites/buildings/spawning_pit.png"
const COLLISION_RADIUS := 8.0
const SPRITE_SIZE_RATIO := 2.0  # Sprite diameter = collision diameter * this ratio

# Visual
const ACTIVE_COLOR := Color(1.0, 1.0, 1.0, 1.0)  # No tint, use sprite colors

# Fog of war
const SIGHT_RANGE := 2  # Tiles visible around pit

# Spawning behavior
const SPAWN_INTERVAL := 10.0  # Seconds between auto-spawns
const SPAWN_TYPE: int = 0  # Enums.MinionType.CRAWLER (use int to avoid circular dependency)
const SPAWN_OFFSET_RATIO := 0.5  # Spawn offset as ratio of tile size

# Default fallback values (used if GameConstants.BUILDING_STATS is missing data)
const DEFAULT_COST := 100

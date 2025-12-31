extends RefCounted
## Spawning Pit configuration - allows spawning minions at this location
## Use preload pattern: const Data := preload("res://scripts/entities/buildings/SpawningPitData.gd")

const COLLISION_RADIUS := 6.0
const SPRITE_SIZE_RATIO := 1.0

# Visual
const ACTIVE_COLOR := Color(0.8, 0.3, 0.3, 1.0)  # Red glow

# Fog of war
const SIGHT_RANGE := 2  # Tiles visible around pit

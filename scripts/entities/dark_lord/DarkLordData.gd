extends RefCounted
## Dark Lord configuration - all Dark Lord specific values
## Use preload pattern: const Data := preload("res://scripts/entities/dark_lord/DarkLordData.gd")

const COLLISION_RADIUS := 10.0
const SPRITE_SIZE_RATIO := 1.2  # Sprite visual size relative to collision diameter (1.0 = match collision)
const WANDER_SPEED := 30.0
const WANDER_INTERVAL_MIN := 1.0
const WANDER_INTERVAL_MAX := 3.0

# Fog of war
const SIGHT_RANGE := 6  # Tiles visible around Dark Lord

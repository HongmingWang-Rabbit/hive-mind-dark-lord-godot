extends RefCounted
## Civilian House configuration - entity-specific values (non-balance)
## Use preload pattern: const Data := preload("res://scripts/entities/buildings/CivilianHouseData.gd")
##
## Civilian houses are human buildings that exist in the Human World.
## They spawn and maintain civilians in the area around them.

const NAME := "Civilian House"
const DESCRIPTION := "Human dwelling - spawns civilians"

const SPRITE_PATH := "res://assets/sprites/tilemap/civilian_houses.png"
const COLLISION_RADIUS := 12.0
const SPRITE_SIZE_RATIO := 2.0

# Civilian spawning (visual/positioning only - balance values in GameConstants)
const SPAWN_RADIUS := 24.0   # Pixels - distance from house to spawn

# Visual feedback
const ACTIVE_COLOR := Color(1.0, 1.0, 1.0, 1.0)  # Normal state

extends RefCounted
## Police Station configuration - entity-specific values (non-balance)
## Use preload pattern: const Data := preload("res://scripts/entities/buildings/PoliceStationData.gd")
##
## Police stations are human buildings that exist in the Human World.
## They spawn and maintain policemen in the area around them.

const NAME := "Police Station"
const DESCRIPTION := "Human defense structure - spawns policemen"

const SPRITE_PATH := "res://assets/sprites/buildings/police_station.png"
const COLLISION_RADIUS := 10.0
const SPRITE_SIZE_RATIO := 1.8

# Policeman spawning (visual/positioning only - balance values in GameConstants)
const SPAWN_RADIUS := 32.0   # Pixels - distance from station to spawn

# Visual feedback
const ACTIVE_COLOR := Color(1.0, 1.0, 1.0, 1.0)  # Normal state

extends RefCounted
## Spawning Pit configuration - allows spawning minions at this location
## Use preload pattern: const Data := preload("res://scripts/entities/buildings/SpawningPitData.gd")

const SPRITE_PATH := "res://assets/sprites/buildings/corruption_node.png"  # Placeholder until unique sprite
const COLLISION_RADIUS := 8.0
const SPRITE_SIZE_RATIO := 2.0  # Sprite diameter = collision diameter * this ratio

# Visual
const ACTIVE_COLOR := Color(0.8, 0.3, 0.3, 1.0)  # Red tint to distinguish from node

# Fog of war
const SIGHT_RANGE := 2  # Tiles visible around pit

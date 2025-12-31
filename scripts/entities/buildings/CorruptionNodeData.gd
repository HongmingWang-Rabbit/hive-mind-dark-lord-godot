extends RefCounted
## Corruption Node configuration - generates passive essence income
## Use preload pattern: const Data := preload("res://scripts/entities/buildings/CorruptionNodeData.gd")

const SPRITE_PATH := "res://assets/sprites/buildings/corruption_node.png"
const COLLISION_RADIUS := 8.0
const SPRITE_SIZE_RATIO := 2.0  # Sprite diameter = collision diameter * this ratio

# Visual
const ACTIVE_COLOR := Color(1.0, 1.0, 1.0, 1.0)  # No tint, use sprite colors

# Fog of war
const SIGHT_RANGE := 2  # Tiles visible around node

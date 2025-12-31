extends RefCounted
## Corruption Node configuration - generates passive essence income
## Use preload pattern: const Data := preload("res://scripts/entities/buildings/CorruptionNodeData.gd")

const COLLISION_RADIUS := 5.0
const SPRITE_SIZE_RATIO := 1.0

# Visual
const ACTIVE_COLOR := Color(0.6, 0.2, 0.8, 1.0)  # Purple glow

# Fog of war
const SIGHT_RANGE := 2  # Tiles visible around node

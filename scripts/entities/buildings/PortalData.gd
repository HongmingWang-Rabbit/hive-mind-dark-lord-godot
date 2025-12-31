extends RefCounted
## Portal configuration - all portal specific values
## Use preload pattern: const Data := preload("res://scripts/entities/buildings/PortalData.gd")

# Display info
const NAME := "Portal"
const DESCRIPTION := "Travel between Dark and Human worlds"

const SPRITE_PATH := "res://assets/sprites/buildings/dark_portal.png"
const COLLISION_RADIUS := 8.0
const TRAVEL_TRIGGER_RADIUS := 12.0  # Larger than collision for easier entry
const SPRITE_SIZE_RATIO := 2.0  # Sprite diameter = collision diameter * this ratio

# Portal visual effects
const ACTIVE_COLOR := Color(1.0, 1.0, 1.0, 1.0)  # No tint when linked
const INACTIVE_COLOR := Color(0.5, 0.5, 0.5, 1.0)  # Gray when not linked

# Essence cost to place portal
const PLACEMENT_COST := 20

# Fog of war
const SIGHT_RANGE := 4  # Tiles visible around portal

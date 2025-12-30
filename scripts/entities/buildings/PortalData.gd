extends RefCounted
## Portal configuration - all portal specific values
## Use preload pattern: const Data := preload("res://scripts/entities/buildings/PortalData.gd")

const COLLISION_RADIUS := 6.0
const TRAVEL_TRIGGER_RADIUS := 10.0  # Larger than collision for easier entry
const SPRITE_SIZE_RATIO := 1.0

# Portal visual effects
const ACTIVE_COLOR := Color(0.5, 0.2, 1.0, 1.0)  # Purple glow when linked
const INACTIVE_COLOR := Color(0.3, 0.3, 0.3, 1.0)  # Gray when not linked

# Essence cost to place portal
const PLACEMENT_COST := 20

# Fog of war
const SIGHT_RANGE := 4  # Tiles visible around portal

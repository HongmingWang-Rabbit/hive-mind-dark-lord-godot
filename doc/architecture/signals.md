# EventBus Signals

All inter-system communication goes through EventBus signals.

```gdscript
# Corruption
signal tile_corrupted(tile_pos: Vector2i, world: Enums.WorldType)
signal corruption_changed(new_percent: float, world: Enums.WorldType)
signal corruption_cleansed(tile_pos: Vector2i, world: Enums.WorldType)

# Combat - Human World
signal entity_killed(position: Vector2, entity_type: Enums.HumanType)
signal human_possessed(position: Vector2)
signal enemy_spotted(position: Vector2, threat_type: Enums.ThreatLevel)

# Combat - Dark World Invasion
signal dark_world_invaded(portal_pos: Vector2i)
signal special_forces_spawned(position: Vector2, force_type: Enums.SpecialForcesType)
signal dark_lord_attacked(attacker_pos: Vector2)

# Buildings
signal building_placed(building_type: Enums.BuildingType, position: Vector2, world: Enums.WorldType)
signal building_destroyed(building_type: Enums.BuildingType, position: Vector2)

# Portals
signal portal_placed(tile_pos: Vector2i, world: Enums.WorldType, owner: Enums.PortalOwner)
signal portal_activated(tile_pos: Vector2i)
signal portal_closed(tile_pos: Vector2i, world: Enums.WorldType)
signal military_portal_opened(tile_pos: Vector2i)  # AI-controlled, player cannot prevent

# Commands
signal attack_ordered(target_pos: Vector2, minion_percent: float, stance: Enums.Stance)
signal retreat_ordered()
signal dark_lord_move_ordered(target_pos: Vector2)  # Player clicked to move Dark Lord

# Game State
signal threat_level_changed(new_level: Enums.ThreatLevel)
signal game_won()
signal game_lost(reason: String)  # "dark_lord_died" or "corruption_wiped"

# World Dimension
signal world_switched(new_world: Enums.WorldType)

# Fog of War
signal fog_update_requested(world: Enums.WorldType)

# Interaction Mode
signal interaction_mode_changed(mode: Enums.InteractionMode, data: Variant)
signal build_mode_entered(building_type: Enums.BuildingType)
signal order_mode_entered(assignment: Enums.MinionAssignment)
signal interaction_cancelled()

# UI
signal evolve_modal_requested()

# Resources
signal essence_harvested(amount: int, source: Enums.HumanType)
signal evolution_points_gained(amount: int, source: String)
```

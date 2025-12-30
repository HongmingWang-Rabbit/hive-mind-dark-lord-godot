extends Node
## Central event bus for decoupled communication between systems

# Corruption events
signal tile_corrupted(tile_pos: Vector2i)
signal corruption_changed(new_percent: float)

# Combat events
signal human_killed(position: Vector2)
signal human_possessed(position: Vector2)
signal enemy_spotted(position: Vector2, threat_type: Enums.ThreatLevel)

# Building events
signal building_placed(building_type: Enums.BuildingType, position: Vector2)
signal building_destroyed(building_type: Enums.BuildingType, position: Vector2)

# Command events
signal attack_ordered(target_pos: Vector2, minion_percent: float, stance: Enums.Stance)
signal retreat_ordered()

# Game state events
signal threat_level_changed(new_level: Enums.ThreatLevel)
signal game_won()
signal game_lost()

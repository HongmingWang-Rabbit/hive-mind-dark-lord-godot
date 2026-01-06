extends Node
## Global enums for Hive Mind Dark Lord

# Game flow
enum GameState {MENU, PLAYING, PAUSED, WON, LOST}

# Units
enum MinionType {CRAWLER, BRUTE, STALKER}
enum MinionAssignment {IDLE, ATTACKING, DEFENDING}
enum Stance {AGGRESSIVE, HOLD, RETREAT}

# World
enum BuildingType {CORRUPTION_NODE, SPAWNING_PIT, PORTAL}
enum ThreatLevel {NONE, SWAT, MILITARY, HEAVY}
enum TileType {FLOOR, WALL, PROP, EMPTY}
enum WorldType {CORRUPTED, HUMAN}

# Human World entities
enum HumanType {CIVILIAN, ANIMAL, POLICEMAN}

# Enemy types (military forces)
enum EnemyType {SWAT, MILITARY, HEAVY, SPECIAL_FORCES, PSYCHIC}

# Interaction modes
enum InteractionMode {NONE, BUILD, ORDER}

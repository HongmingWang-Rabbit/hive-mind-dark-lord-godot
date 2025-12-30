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
enum ThreatLevel {NONE, POLICE, MILITARY, HEAVY}
enum TileType {FLOOR, WALL, PROP, EMPTY}
enum WorldType {CORRUPTED, HUMAN}

# Human World entities
enum HumanType {CIVILIAN, ANIMAL}

# Enemy types (military forces)
enum EnemyType {POLICE, MILITARY, HEAVY, SPECIAL_FORCES}

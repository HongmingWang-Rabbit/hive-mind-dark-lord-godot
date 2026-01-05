# Adding New Features

## New Entity Type
1. Create folder `scripts/entities/your_entity/`
2. Create `YourEntityData.gd` with entity-specific constants (extends RefCounted)
3. Create `YourEntityController.gd` with behavior script
4. Create folder `scenes/entities/your_entity/`
5. Create `your_entity.tscn` scene with script attached
6. Use preload pattern: `const Data := preload("res://scripts/entities/your_entity/YourEntityData.gd")`
7. Set all configurable values (scale, collision, speeds) from Data in `_ready()`

## New Human World Entity (Civilian, Animal, etc.)
1. Add to `Enums.HumanType`
2. Create entity following "New Entity Type" pattern
3. Add essence value to `GameConstants.ESSENCE_PER_*`
4. Add spawn logic to Human World entity spawner
5. If special: add evolution points to `GameConstants.EVOLUTION_PER_SPECIAL`

**Note:** Animals use generic `HumanType.ANIMAL` but the system is extensible.
Future special creatures (e.g., rare monsters, easter eggs) can have their own
type and custom rewards. Just add new enum value and configure rewards.

## New Special Forces Type (Invade Dark World)
1. Add to `Enums.SpecialForcesType`
2. Create entity following "New Entity Type" pattern
3. Add behavior: SCOUT (report), CLEANSER (remove corruption), STRIKE_TEAM (attack)
4. Add spawn trigger at appropriate threat level

## New Minion Type
1. Add to `Enums.MinionType`
2. Add stats to `GameConstants.MINION_STATS`
3. Add sprite to `TileData.CHAR_*`
4. HivePool automatically handles new type

## New Building Type
1. Add to `Enums.BuildingType`
2. Add stats to `GameConstants.BUILDING_STATS`
3. Add tiles to `TileData.PROP_*`

## Military Portal System
Military portals are AI-controlled and open at HIGH+ threat:
1. Listen for `threat_level_changed` signal
2. At HIGH threat, spawn military portals **dynamically near player corruption** (not fixed)
3. Emit `military_portal_opened` signal
4. Special forces enter through military portals
5. Player CANNOT close or prevent military portals

## New Tileset
1. Replace `TileData` coordinates
2. Update `resources/dungeon_tileset.tres` atlas
3. No other code changes needed

## New Balance Values
1. Add constant to `GameConstants`
2. Reference via `GameConstants.YOUR_CONSTANT`
3. Never hardcode numbers in logic files

## New Component (Composition Pattern)
1. Create `scripts/components/YourComponent.gd`
2. Extend Node2D or appropriate base
3. Add signals for events (e.g., `signal state_changed`)
4. Add `setup()` function for initialization
5. Document in `doc/architecture/README.md`

Example:
```gdscript
extends Node2D
## Description of component

signal some_event()

var _some_state: int = 0

func setup(initial_value: int) -> void:
    _some_state = initial_value

func do_something() -> void:
    _some_state += 1
    some_event.emit()
```

Usage:
```gdscript
const YourComponent := preload("res://scripts/components/YourComponent.gd")

var _component: Node2D

func _ready() -> void:
    _component = YourComponent.new()
    add_child(_component)
    _component.setup(10)
    _component.some_event.connect(_on_event)
```

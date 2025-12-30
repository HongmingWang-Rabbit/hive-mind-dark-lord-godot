# Tile Reference - Kenney Tiny Dungeon

Tileset: `resources/kenney_tiny-dungeon/Tilemap/tilemap_packed.png`
Tile size: 16x16 pixels
Grid: 12 columns x 11 rows

**Code location:** `scripts/data/tile_data.gd`

## How to Use

All tile coordinates are in `TileData` class:

```gdscript
# Access directly (class_name)
var floor := TileData.FLOOR_MAIN
var wall := TileData.WALL
var skeleton := TileData.CHAR_SKELETON

# Random helpers
var random_floor := TileData.get_random_floor()
var random_prop := TileData.get_random_prop()
```

## TileData Constants

### Floors
| Constant | Coord | Description |
|----------|-------|-------------|
| `FLOOR_MAIN` | (0,4) | Tan floor |
| `FLOOR_ALT` | (1,4) | Tan floor alt |
| `FLOOR_VARIATION` | (2,4) | Tan variation |
| `FLOORS` | Array | All floor tiles |

### Walls
| Constant | Coord | Description |
|----------|-------|-------------|
| `WALL` | (1,3) | Stone brick center |
| `WALL_LEFT` | (0,3) | Stone brick left |
| `WALL_RIGHT` | (2,3) | Stone brick right |
| `WALL_TOP` | (1,3) | Wall top center |
| `WALL_TOP_LEFT` | (0,3) | Wall top left |
| `WALL_TOP_RIGHT` | (2,3) | Wall top right |

### Props
| Constant | Coord | Description |
|----------|-------|-------------|
| `PROP_CRATE` | (0,6) | Orange crate |
| `PROP_BARREL` | (1,6) | Dark barrel |
| `PROP_DOOR` | (3,6) | Wooden door |
| `PROP_CHEST` | (6,5) | Orange chest |
| `PROP_TOMBSTONE` | (4,5) | Gray tombstone |
| `PROP_BARS` | (4,6) | Iron bars |
| `PROPS` | Array | Scatterable props |

### Characters - Minions
| Constant | Coord | Description |
|----------|-------|-------------|
| `CHAR_SKELETON` | (3,7) | White skeleton |
| `CHAR_DEMON` | (2,9) | Red demon |
| `CHAR_GHOST` | (1,10) | White ghost |
| `CHAR_SLIME` | (0,9) | Green slime |
| `CHAR_BAT` | (0,10) | Orange bat |

### Characters - Humans
| Constant | Coord | Description |
|----------|-------|-------------|
| `CHAR_VILLAGER` | (1,7) | Brown human |
| `CHAR_VILLAGER_ALT` | (2,7) | Brown human alt |
| `CHAR_GUARD` | (4,8) | Blue knight |
| `CHAR_KNIGHT` | (0,8) | Purple knight |
| `CHAR_WIZARD` | (0,7) | Purple wizard |

### Special
| Constant | Coord | Description |
|----------|-------|-------------|
| `CHAR_DARK_LORD` | (2,9) | Red demon |

## Changing Tileset

1. Update coordinates in `scripts/data/tile_data.gd`
2. Update `resources/dungeon_tileset.tres` atlas
3. No other code changes needed

## Atlas Index Formula

For individual tile files: `tile_number = row * 12 + col`

Example: Skeleton (3,7) = tile_0087.png (7*12 + 3 = 87)

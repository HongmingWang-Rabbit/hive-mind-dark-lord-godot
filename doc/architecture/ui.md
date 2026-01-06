# UI System

## HUDController.gd

Manages UI elements and player interactions. Applies visual theme from UITheme.gd.

### Mouse Filter Configuration
The HUD root Control and non-interactive labels use `mouse_filter = MOUSE_FILTER_IGNORE` (2) so mouse clicks pass through to the world below. Only interactive elements (buttons, panels) capture mouse events.

```gdscript
# In hud.tscn - root HUD node
mouse_filter = 2  # MOUSE_FILTER_IGNORE - clicks pass through

# Interactive elements (buttons, panels) use default MOUSE_FILTER_STOP
```

### Features
- **Essence display**: Updates when `Essence.essence_changed` fires
- **Corruption display**: Updates when `EventBus.corruption_changed` fires
- **Threat display**: Updates when `EventBus.threat_level_changed` fires
- **World switch button**: Toggles visibility between Corrupted/Human world (view only, does not move entities)
- **Bottom toolbar**: Buildings, Orders, and Evolve sections with cost display and disabled states
- **Mode indicator**: Shows "Click to place/target" when in build/order mode (mouse_filter = IGNORE)
- **Themed styling**: All colors and styles applied programmatically from UITheme.gd

### Interaction Mode System
Priority-based input handling (World.gd `_unhandled_input`):
1. **UI buttons** (handled by Godot Control system - highest priority)
2. **ESC** cancels current interaction mode
3. **Mouse clicks** (with UI overlap check via `_is_mouse_over_ui()`)
4. **Keyboard shortcuts** (minion spawning, world switch)

Flow:
1. User clicks building/order button → enters build/order mode
2. Mode indicator appears: "Click to place" or "Click to target"
3. Cursor preview: building sprite (build mode) or colored circle (order mode)
   - Build cursor: scaled by `Data.SPRITE_SIZE_RATIO`, snaps to tile
   - Order cursor: `ORDER_CURSOR_COLOR` (attack), `ORDER_CURSOR_DEFEND_COLOR`, `ORDER_CURSOR_SCOUT_COLOR`
4. User left-clicks on map → action executed at clicked position
5. Left-click with no mode → moves Dark Lord to position
6. ESC or right-click cancels current mode

### Bottom Toolbar Sections
| Section | Buttons | Emits |
|---------|---------|-------|
| Buildings | Icon buttons (sprites from Data.SPRITE_PATH) | `build_mode_entered(BuildingType)` |
| Orders | Atk, Sct, Def, Ret | `order_mode_entered(MinionAssignment)`, `retreat_ordered()` |
| Evolve | Evo | `evolve_modal_requested()` |

Building buttons display sprites from Data files with tooltips showing "Name (cost)\nDescription". Buttons auto-disable when player can't afford the cost. Costs are retrieved via `_get_building_cost()` helper which routes to either `GameConstants.BUILDING_STATS` or `PortalData.PLACEMENT_COST`.

### UI Text Constants
```gdscript
WORLD_BUTTON_CORRUPTED  # "Corrupt"
WORLD_BUTTON_HUMAN      # "Human"
ESSENCE_FORMAT          # "E:%d" (compact for 480x270 viewport)
CORRUPTION_FORMAT       # "C:%d%%"
THREAT_FORMAT           # "T:%s"
THREAT_LEVEL_NAMES      # ["None", "SWAT", "Military", "Heavy"]
BUILDING_TOOLTIP_FORMAT # "%s (%d)\n%s" - "Name (cost)\nDescription"
MODE_BUILD              # "Click to place"
MODE_ORDER              # "Click to target"
```

### Connected Signals
```gdscript
EventBus.corruption_changed
EventBus.threat_level_changed
EventBus.world_switched
EventBus.interaction_mode_changed
EventBus.interaction_cancelled
Essence.essence_changed
```

---

## UITheme.gd

UI theme data script containing all visual constants for the HUD. Uses preload pattern.

### Usage
```gdscript
const UI := preload("res://scripts/ui/UITheme.gd")
label.add_theme_color_override("font_color", UI.ESSENCE_COLOR)
```

### Constants
```gdscript
#region Panel Colors
PANEL_BG_COLOR, PANEL_BORDER_COLOR
PANEL_BORDER_WIDTH, PANEL_CORNER_RADIUS
PANEL_MARGIN, PANEL_MARGIN_SMALL

#region Button Colors
BUTTON_BG_COLOR, BUTTON_BG_HOVER_COLOR
BUTTON_BORDER_COLOR, BUTTON_BORDER_HOVER_COLOR
BUTTON_FONT_COLOR, BUTTON_FONT_HOVER_COLOR
BUTTON_DISABLED_COLOR               # Grayed out when disabled
BUTTON_CORNER_RADIUS, BUTTON_BORDER_WIDTH
BUTTON_MARGIN_H, BUTTON_MARGIN_V

#region Label Colors - Stats
ESSENCE_COLOR, ESSENCE_SHADOW_COLOR
CORRUPTION_COLOR, CORRUPTION_SHADOW_COLOR
THREAT_COLOR, THREAT_SHADOW_COLOR

#region Label Colors - Minions
HEADER_COLOR, HEADER_SHADOW_COLOR
CRAWLER_COLOR, BRUTE_COLOR, STALKER_COLOR

#region Layout
SHADOW_OFFSET
TOP_BAR_SEPARATION, SIDE_PANEL_SEPARATION, SEPARATOR_WIDTH

#region Font
FONT_SIZE, FONT_SIZE_HEADER  # 8px for pixel art viewport
FONT_SIZE_TITLE              # 10px for modal titles

#region Modal
MODAL_CONTENT_COLOR          # Color for modal text content
MODAL_OVERLAY_COLOR          # Semi-transparent overlay color

#region Bottom Toolbar
TOOLBAR_HEIGHT              # 24px
TOOLBAR_SECTION_SEPARATION  # 4px between sections
TOOLBAR_LABEL_COLOR         # Light purple section headers
BUILDING_BUTTON_ICON_SIZE   # Vector2i(16, 16) - icon size for building buttons
```

---

## Game Over Screen

Win/lose UI overlay that pauses the game and allows restart.

### File Organization
```
scripts/ui/
└── GameOverScreen.gd

scenes/ui/
└── game_over_screen.tscn
```

### Triggers
- **Win**: Corruption reaches WIN_THRESHOLD (80%)
- **Lose - Dark Lord**: Dark Lord HP reaches 0
- **Lose - Corruption**: All corruption cleared in Dark World

### Connected Signals
```gdscript
EventBus.game_won  → _on_game_won()
EventBus.game_lost → _on_game_lost()
```

---

## Evolve Modal

Placeholder modal for the minion evolution system.

### File Organization
```
scripts/ui/
└── EvolveModal.gd

scenes/ui/
└── evolve_modal.tscn
```

### Features
- Opens when Evolve button clicked (`evolve_modal_requested` signal)
- Pauses game while open
- ESC or Close button to dismiss
- Uses UITheme for consistent styling

### Scene Structure
```
EvolveModal [CanvasLayer, layer=10, process_mode=ALWAYS]
├── ColorRect - Semi-transparent overlay
└── Panel [PanelContainer]
    └── VBox [VBoxContainer]
        ├── TitleLabel
        ├── ContentLabel
        └── CloseBtn
```

extends RefCounted
## UI Theme configuration - all UI visual constants
## Use preload pattern: const UI := preload("res://scripts/ui/UITheme.gd")

#region Panel Colors
const PANEL_BG_COLOR := Color(0.1, 0.05, 0.15, 0.85)
const PANEL_BORDER_COLOR := Color(0.4, 0.2, 0.6, 0.8)
const PANEL_BORDER_WIDTH := 1
const PANEL_CORNER_RADIUS := 2
const PANEL_MARGIN := 4.0
const PANEL_MARGIN_SMALL := 3.0
#endregion

#region Button Colors
const BUTTON_BG_COLOR := Color(0.2, 0.1, 0.3, 0.9)
const BUTTON_BG_HOVER_COLOR := Color(0.3, 0.15, 0.45, 0.95)
const BUTTON_BORDER_COLOR := Color(0.5, 0.3, 0.7, 1.0)
const BUTTON_BORDER_HOVER_COLOR := Color(0.6, 0.4, 0.8, 1.0)
const BUTTON_FONT_COLOR := Color(0.9, 0.9, 1.0, 1.0)
const BUTTON_FONT_HOVER_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const BUTTON_DISABLED_COLOR := Color(0.4, 0.4, 0.4, 0.6)
const BUTTON_CORNER_RADIUS := 2
const BUTTON_BORDER_WIDTH := 1
const BUTTON_MARGIN_H := 3.0
const BUTTON_MARGIN_V := 1.0
#endregion

#region Label Colors - Stats
const ESSENCE_COLOR := Color(1.0, 0.85, 0.2, 1.0)
const ESSENCE_SHADOW_COLOR := Color(0.3, 0.2, 0.0, 0.5)
const CORRUPTION_COLOR := Color(0.8, 0.4, 1.0, 1.0)
const CORRUPTION_SHADOW_COLOR := Color(0.2, 0.0, 0.3, 0.5)
const THREAT_COLOR := Color(1.0, 0.4, 0.3, 1.0)
const THREAT_SHADOW_COLOR := Color(0.3, 0.0, 0.0, 0.5)
#endregion

#region Label Colors - Minions
const HEADER_COLOR := Color(0.7, 0.5, 0.9, 1.0)
const HEADER_SHADOW_COLOR := Color(0.1, 0.0, 0.2, 0.5)
const CRAWLER_COLOR := Color(0.6, 0.8, 0.6, 1.0)
const BRUTE_COLOR := Color(0.9, 0.6, 0.5, 1.0)
const STALKER_COLOR := Color(0.6, 0.6, 0.9, 1.0)
#endregion

#region Shadow Settings
const SHADOW_OFFSET := Vector2i(1, 1)
#endregion

#region Layout
const TOP_BAR_SEPARATION := 8
const SIDE_PANEL_SEPARATION := 1
const SEPARATOR_WIDTH := 2
#endregion

#region Font
const FONT_SIZE := 8
const FONT_SIZE_HEADER := 8
const FONT_SIZE_TITLE := 10
#endregion

#region Modal
const MODAL_CONTENT_COLOR := Color(0.9, 0.9, 0.9, 1.0)
const MODAL_OVERLAY_COLOR := Color(0.0, 0.0, 0.0, 0.5)
#endregion

#region Bottom Toolbar
const TOOLBAR_HEIGHT := 24
const TOOLBAR_SECTION_SEPARATION := 4
const TOOLBAR_LABEL_COLOR := Color(0.8, 0.7, 0.9, 1.0)
const BUILDING_BUTTON_ICON_SIZE := Vector2i(16, 16)  # Icon size for building buttons
#endregion

#region Mode Indicator
const MODE_INDICATOR_COLOR := Color(1.0, 1.0, 0.5, 1.0)  # Yellow for visibility
#endregion

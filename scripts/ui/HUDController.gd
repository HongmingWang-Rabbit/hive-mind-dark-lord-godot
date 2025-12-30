extends Control
## HUD controller - manages UI elements and player interactions
## Applies visual theme from UITheme.gd

const UI := preload("res://scripts/ui/UITheme.gd")
const PortalData := preload("res://scripts/entities/buildings/PortalData.gd")

@onready var top_bar: PanelContainer = $TopBar
@onready var hbox: HBoxContainer = $TopBar/HBox
@onready var essence_label: Label = $TopBar/HBox/EssenceLabel
@onready var corruption_label: Label = $TopBar/HBox/CorruptionLabel
@onready var threat_label: Label = $TopBar/HBox/ThreatLabel
@onready var world_button: Button = $TopBar/HBox/WorldButton
@onready var side_panel: PanelContainer = $SidePanel
@onready var minion_header: Label = $SidePanel/VBox/MinionHeader
@onready var crawler_count: Label = $SidePanel/VBox/CrawlerCount
@onready var brute_count: Label = $SidePanel/VBox/BruteCount
@onready var stalker_count: Label = $SidePanel/VBox/StalkerCount

# Bottom toolbar
@onready var bottom_toolbar: PanelContainer = $BottomToolbar
@onready var build_label: Label = $BottomToolbar/HBox/BuildingsSection/BuildLabel
@onready var node_btn: Button = $BottomToolbar/HBox/BuildingsSection/NodeBtn
@onready var pit_btn: Button = $BottomToolbar/HBox/BuildingsSection/PitBtn
@onready var portal_btn: Button = $BottomToolbar/HBox/BuildingsSection/PortalBtn
@onready var order_label: Label = $BottomToolbar/HBox/OrdersSection/OrderLabel
@onready var attack_btn: Button = $BottomToolbar/HBox/OrdersSection/AttackBtn
@onready var scout_btn: Button = $BottomToolbar/HBox/OrdersSection/ScoutBtn
@onready var defend_btn: Button = $BottomToolbar/HBox/OrdersSection/DefendBtn
@onready var retreat_btn: Button = $BottomToolbar/HBox/OrdersSection/RetreatBtn
@onready var evolve_label: Label = $BottomToolbar/HBox/EvolveSection/EvolveLabel
@onready var evolve_btn: Button = $BottomToolbar/HBox/EvolveSection/EvolveBtn

# UI text constants
const WORLD_BUTTON_CORRUPTED := "Corrupt"
const WORLD_BUTTON_HUMAN := "Human"
const ESSENCE_FORMAT := "E:%d"
const CORRUPTION_FORMAT := "C:%d%%"
const THREAT_FORMAT := "T:%s"
const THREAT_LEVEL_NAMES: Array[String] = ["None", "Police", "Military", "Heavy"]

# Toolbar button text
const NODE_BTN_FORMAT := "N:%d"
const PIT_BTN_FORMAT := "P:%d"
const PORTAL_BTN_FORMAT := "O:%d"


func _ready() -> void:
	_apply_theme()
	_connect_signals()
	_init_ui_state()


func _apply_theme() -> void:
	# Top bar panel
	top_bar.add_theme_stylebox_override("panel", _create_panel_style(true))
	hbox.add_theme_constant_override("separation", UI.TOP_BAR_SEPARATION)

	# Side panel
	side_panel.add_theme_stylebox_override("panel", _create_side_panel_style())
	$SidePanel/VBox.add_theme_constant_override("separation", UI.SIDE_PANEL_SEPARATION)

	# Stat labels
	_apply_label_theme(essence_label, UI.ESSENCE_COLOR, UI.ESSENCE_SHADOW_COLOR)
	_apply_label_theme(corruption_label, UI.CORRUPTION_COLOR, UI.CORRUPTION_SHADOW_COLOR)
	_apply_label_theme(threat_label, UI.THREAT_COLOR, UI.THREAT_SHADOW_COLOR)

	# Minion labels
	_apply_label_theme(minion_header, UI.HEADER_COLOR, UI.HEADER_SHADOW_COLOR)
	_apply_minion_label_theme(crawler_count, UI.CRAWLER_COLOR)
	_apply_minion_label_theme(brute_count, UI.BRUTE_COLOR)
	_apply_minion_label_theme(stalker_count, UI.STALKER_COLOR)

	# World button
	_apply_button_theme(world_button)

	# Separators
	for child in hbox.get_children():
		if child is VSeparator:
			child.add_theme_constant_override("separation", UI.SEPARATOR_WIDTH)

	# Bottom toolbar
	_apply_toolbar_theme()


func _create_panel_style(is_top: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = UI.PANEL_BG_COLOR
	style.border_color = UI.PANEL_BORDER_COLOR
	style.content_margin_left = UI.PANEL_MARGIN
	style.content_margin_right = UI.PANEL_MARGIN
	style.content_margin_top = UI.PANEL_MARGIN / 2.0
	style.content_margin_bottom = UI.PANEL_MARGIN / 2.0

	if is_top:
		style.border_width_bottom = UI.PANEL_BORDER_WIDTH
		style.corner_radius_bottom_left = UI.PANEL_CORNER_RADIUS
		style.corner_radius_bottom_right = UI.PANEL_CORNER_RADIUS
	else:
		style.border_width_left = UI.PANEL_BORDER_WIDTH
		style.corner_radius_top_left = UI.PANEL_CORNER_RADIUS
		style.corner_radius_bottom_left = UI.PANEL_CORNER_RADIUS

	return style


func _create_side_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = UI.PANEL_BG_COLOR
	style.border_color = UI.PANEL_BORDER_COLOR
	style.border_width_left = UI.PANEL_BORDER_WIDTH
	style.corner_radius_top_left = UI.PANEL_CORNER_RADIUS
	style.corner_radius_bottom_left = UI.PANEL_CORNER_RADIUS
	style.content_margin_left = UI.PANEL_MARGIN_SMALL
	style.content_margin_right = UI.PANEL_MARGIN_SMALL
	style.content_margin_top = UI.PANEL_MARGIN_SMALL
	style.content_margin_bottom = UI.PANEL_MARGIN_SMALL
	return style


func _create_button_style(is_hover: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = UI.BUTTON_BG_HOVER_COLOR if is_hover else UI.BUTTON_BG_COLOR
	style.border_color = UI.BUTTON_BORDER_HOVER_COLOR if is_hover else UI.BUTTON_BORDER_COLOR
	style.set_border_width_all(UI.BUTTON_BORDER_WIDTH)
	style.set_corner_radius_all(UI.BUTTON_CORNER_RADIUS)
	style.content_margin_left = UI.BUTTON_MARGIN_H
	style.content_margin_right = UI.BUTTON_MARGIN_H
	style.content_margin_top = UI.BUTTON_MARGIN_V
	style.content_margin_bottom = UI.BUTTON_MARGIN_V
	return style


func _apply_label_theme(label: Label, color: Color, shadow_color: Color) -> void:
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", shadow_color)
	label.add_theme_constant_override("shadow_offset_x", UI.SHADOW_OFFSET.x)
	label.add_theme_constant_override("shadow_offset_y", UI.SHADOW_OFFSET.y)
	label.add_theme_font_size_override("font_size", UI.FONT_SIZE)


func _apply_minion_label_theme(label: Label, color: Color) -> void:
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", UI.FONT_SIZE)


func _apply_button_theme(button: Button) -> void:
	button.add_theme_color_override("font_color", UI.BUTTON_FONT_COLOR)
	button.add_theme_color_override("font_hover_color", UI.BUTTON_FONT_HOVER_COLOR)
	button.add_theme_color_override("font_disabled_color", UI.BUTTON_DISABLED_COLOR)
	button.add_theme_font_size_override("font_size", UI.FONT_SIZE)
	button.add_theme_stylebox_override("normal", _create_button_style(false))
	button.add_theme_stylebox_override("hover", _create_button_style(true))
	button.add_theme_stylebox_override("pressed", _create_button_style(true))
	button.add_theme_stylebox_override("disabled", _create_button_style(false))


func _apply_toolbar_theme() -> void:
	# Bottom toolbar panel
	bottom_toolbar.add_theme_stylebox_override("panel", _create_bottom_panel_style())
	$BottomToolbar/HBox.add_theme_constant_override("separation", UI.TOOLBAR_SECTION_SEPARATION)

	# Section labels
	_apply_label_theme(build_label, UI.TOOLBAR_LABEL_COLOR, UI.HEADER_SHADOW_COLOR)
	_apply_label_theme(order_label, UI.TOOLBAR_LABEL_COLOR, UI.HEADER_SHADOW_COLOR)
	_apply_label_theme(evolve_label, UI.TOOLBAR_LABEL_COLOR, UI.HEADER_SHADOW_COLOR)

	# Building buttons
	for btn in [node_btn, pit_btn, portal_btn]:
		_apply_button_theme(btn)

	# Order buttons
	for btn in [attack_btn, scout_btn, defend_btn, retreat_btn]:
		_apply_button_theme(btn)

	# Evolve button
	_apply_button_theme(evolve_btn)

	# Separators
	for child in $BottomToolbar/HBox.get_children():
		if child is VSeparator:
			child.add_theme_constant_override("separation", UI.SEPARATOR_WIDTH)

	# Update button text with costs
	_update_building_button_text()


func _create_bottom_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = UI.PANEL_BG_COLOR
	style.border_color = UI.PANEL_BORDER_COLOR
	style.border_width_top = UI.PANEL_BORDER_WIDTH
	style.corner_radius_top_left = UI.PANEL_CORNER_RADIUS
	style.corner_radius_top_right = UI.PANEL_CORNER_RADIUS
	style.content_margin_left = UI.PANEL_MARGIN
	style.content_margin_right = UI.PANEL_MARGIN
	style.content_margin_top = UI.PANEL_MARGIN / 2.0
	style.content_margin_bottom = UI.PANEL_MARGIN / 2.0
	return style


func _get_building_cost(building_type: Enums.BuildingType) -> int:
	## Returns cost for a building type from appropriate data source
	if building_type == Enums.BuildingType.PORTAL:
		return PortalData.PLACEMENT_COST
	return GameConstants.BUILDING_STATS[building_type].cost


func _update_building_button_text() -> void:
	node_btn.text = NODE_BTN_FORMAT % _get_building_cost(Enums.BuildingType.CORRUPTION_NODE)
	pit_btn.text = PIT_BTN_FORMAT % _get_building_cost(Enums.BuildingType.SPAWNING_PIT)
	portal_btn.text = PORTAL_BTN_FORMAT % _get_building_cost(Enums.BuildingType.PORTAL)


func _update_building_buttons() -> void:
	node_btn.disabled = not Essence.can_afford(_get_building_cost(Enums.BuildingType.CORRUPTION_NODE))
	pit_btn.disabled = not Essence.can_afford(_get_building_cost(Enums.BuildingType.SPAWNING_PIT))
	portal_btn.disabled = not Essence.can_afford(_get_building_cost(Enums.BuildingType.PORTAL))


func _connect_signals() -> void:
	EventBus.corruption_changed.connect(_on_corruption_changed)
	EventBus.threat_level_changed.connect(_on_threat_level_changed)
	EventBus.world_switched.connect(_on_world_switched)
	Essence.essence_changed.connect(_on_essence_changed)
	world_button.pressed.connect(_on_world_button_pressed)

	# Toolbar signals
	_connect_toolbar_signals()


func _connect_toolbar_signals() -> void:
	node_btn.pressed.connect(_on_node_btn_pressed)
	pit_btn.pressed.connect(_on_pit_btn_pressed)
	portal_btn.pressed.connect(_on_portal_btn_pressed)
	attack_btn.pressed.connect(_on_attack_btn_pressed)
	scout_btn.pressed.connect(_on_scout_btn_pressed)
	defend_btn.pressed.connect(_on_defend_btn_pressed)
	retreat_btn.pressed.connect(_on_retreat_btn_pressed)
	evolve_btn.pressed.connect(_on_evolve_btn_pressed)


func _init_ui_state() -> void:
	_update_essence_display(Essence.current)
	_update_world_button(WorldManager.active_world)
	_update_building_buttons()


func _on_essence_changed(new_amount: int) -> void:
	_update_essence_display(new_amount)
	_update_building_buttons()


func _update_essence_display(amount: int) -> void:
	essence_label.text = ESSENCE_FORMAT % amount


func _on_corruption_changed(new_percent: float) -> void:
	corruption_label.text = CORRUPTION_FORMAT % int(new_percent * 100)


func _on_threat_level_changed(new_level: Enums.ThreatLevel) -> void:
	threat_label.text = THREAT_FORMAT % THREAT_LEVEL_NAMES[new_level]


func _on_world_switched(new_world: Enums.WorldType) -> void:
	_update_world_button(new_world)


func _update_world_button(world: Enums.WorldType) -> void:
	match world:
		Enums.WorldType.CORRUPTED:
			world_button.text = WORLD_BUTTON_CORRUPTED
		Enums.WorldType.HUMAN:
			world_button.text = WORLD_BUTTON_HUMAN


func _on_world_button_pressed() -> void:
	var target_world: Enums.WorldType
	if WorldManager.active_world == Enums.WorldType.CORRUPTED:
		target_world = Enums.WorldType.HUMAN
	else:
		target_world = Enums.WorldType.CORRUPTED
	WorldManager.switch_world(target_world)


#region Toolbar Button Handlers

func _on_node_btn_pressed() -> void:
	EventBus.building_requested.emit(Enums.BuildingType.CORRUPTION_NODE)


func _on_pit_btn_pressed() -> void:
	EventBus.building_requested.emit(Enums.BuildingType.SPAWNING_PIT)


func _on_portal_btn_pressed() -> void:
	EventBus.building_requested.emit(Enums.BuildingType.PORTAL)


func _on_attack_btn_pressed() -> void:
	EventBus.order_requested.emit(Enums.MinionAssignment.ATTACKING)


func _on_scout_btn_pressed() -> void:
	# Scout uses idle assignment - will be extended in future
	EventBus.order_requested.emit(Enums.MinionAssignment.IDLE)


func _on_defend_btn_pressed() -> void:
	EventBus.order_requested.emit(Enums.MinionAssignment.DEFENDING)


func _on_retreat_btn_pressed() -> void:
	EventBus.retreat_ordered.emit()


func _on_evolve_btn_pressed() -> void:
	# Placeholder for future evolve system
	pass

#endregion

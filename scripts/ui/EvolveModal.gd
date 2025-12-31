extends CanvasLayer
## Evolve modal - placeholder for minion evolution system
## Shows available evolutions and costs

const UI := preload("res://scripts/ui/UITheme.gd")

@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var content_label: Label = $Panel/VBox/ContentLabel
@onready var close_btn: Button = $Panel/VBox/CloseBtn


func _ready() -> void:
	_apply_theme()
	_connect_signals()
	visible = false


func _apply_theme() -> void:
	# Panel style
	var style := StyleBoxFlat.new()
	style.bg_color = UI.PANEL_BG_COLOR
	style.border_color = UI.PANEL_BORDER_COLOR
	style.set_border_width_all(UI.PANEL_BORDER_WIDTH)
	style.set_corner_radius_all(UI.PANEL_CORNER_RADIUS)
	style.content_margin_left = UI.PANEL_MARGIN
	style.content_margin_right = UI.PANEL_MARGIN
	style.content_margin_top = UI.PANEL_MARGIN
	style.content_margin_bottom = UI.PANEL_MARGIN
	panel.add_theme_stylebox_override("panel", style)

	# Title
	title_label.add_theme_color_override("font_color", UI.HEADER_COLOR)
	title_label.add_theme_font_size_override("font_size", UI.FONT_SIZE + 2)

	# Content
	content_label.add_theme_color_override("font_color", Color.WHITE)
	content_label.add_theme_font_size_override("font_size", UI.FONT_SIZE)

	# Close button
	_apply_button_theme(close_btn)


func _apply_button_theme(button: Button) -> void:
	button.add_theme_color_override("font_color", UI.BUTTON_FONT_COLOR)
	button.add_theme_color_override("font_hover_color", UI.BUTTON_FONT_HOVER_COLOR)
	button.add_theme_font_size_override("font_size", UI.FONT_SIZE)

	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = UI.BUTTON_BG_COLOR
	normal_style.border_color = UI.BUTTON_BORDER_COLOR
	normal_style.set_border_width_all(UI.BUTTON_BORDER_WIDTH)
	normal_style.set_corner_radius_all(UI.BUTTON_CORNER_RADIUS)
	normal_style.content_margin_left = UI.BUTTON_MARGIN_H
	normal_style.content_margin_right = UI.BUTTON_MARGIN_H
	normal_style.content_margin_top = UI.BUTTON_MARGIN_V
	normal_style.content_margin_bottom = UI.BUTTON_MARGIN_V
	button.add_theme_stylebox_override("normal", normal_style)

	var hover_style := normal_style.duplicate()
	hover_style.bg_color = UI.BUTTON_BG_HOVER_COLOR
	hover_style.border_color = UI.BUTTON_BORDER_HOVER_COLOR
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", hover_style)


func _connect_signals() -> void:
	EventBus.evolve_modal_requested.connect(_on_evolve_modal_requested)
	close_btn.pressed.connect(_on_close_btn_pressed)


func _on_evolve_modal_requested() -> void:
	visible = true
	get_tree().paused = true


func _on_close_btn_pressed() -> void:
	visible = false
	get_tree().paused = false


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_on_close_btn_pressed()
		get_viewport().set_input_as_handled()

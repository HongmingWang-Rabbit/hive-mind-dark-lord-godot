extends CanvasLayer
## Game Over Screen - displays win/lose message and restart option

@onready var panel: PanelContainer = $CenterContainer/PanelContainer
@onready var title_label: Label = $CenterContainer/PanelContainer/VBoxContainer/TitleLabel
@onready var message_label: Label = $CenterContainer/PanelContainer/VBoxContainer/MessageLabel
@onready var restart_button: Button = $CenterContainer/PanelContainer/VBoxContainer/RestartButton


func _ready() -> void:
	hide()
	EventBus.game_won.connect(_on_game_won)
	EventBus.game_lost.connect(_on_game_lost)
	restart_button.pressed.connect(_on_restart_pressed)


func _on_game_won() -> void:
	title_label.text = "VICTORY!"
	message_label.text = "The Human World has been corrupted.\nDarkness reigns supreme."
	_show_screen()


func _on_game_lost() -> void:
	title_label.text = "DEFEAT"
	if GameManager.game_state == Enums.GameState.LOST:
		if Essence.current <= 0:
			message_label.text = "Your essence has been depleted.\nThe darkness fades..."
		else:
			message_label.text = "The Dark Lord has fallen.\nThe corruption withers..."
	else:
		message_label.text = "The darkness has been defeated."
	_show_screen()


func _show_screen() -> void:
	show()
	get_tree().paused = true


func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

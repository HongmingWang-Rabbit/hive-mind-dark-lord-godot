extends Control
## HUD controller - manages UI elements and player interactions

@onready var essence_label: Label = $TopBar/EssenceLabel
@onready var corruption_label: Label = $TopBar/CorruptionLabel
@onready var threat_label: Label = $TopBar/ThreatLabel
@onready var world_button: Button = $TopBar/WorldButton

# UI text constants
const WORLD_BUTTON_CORRUPTED := "View: Corrupted"
const WORLD_BUTTON_HUMAN := "View: Human"
const ESSENCE_FORMAT := "Essence: %d"
const CORRUPTION_FORMAT := "Corruption: %d%%"
const THREAT_FORMAT := "Threat: %s"
const THREAT_LEVEL_NAMES: Array[String] = ["None", "Police", "Military", "Heavy"]


func _ready() -> void:
	# Connect to EventBus signals
	EventBus.corruption_changed.connect(_on_corruption_changed)
	EventBus.threat_level_changed.connect(_on_threat_level_changed)
	EventBus.world_switched.connect(_on_world_switched)
	Essence.essence_changed.connect(_on_essence_changed)

	# Connect button
	world_button.pressed.connect(_on_world_button_pressed)

	# Initialize UI state
	_update_essence_display(Essence.current)
	_update_world_button(WorldManager.active_world)


func _on_essence_changed(new_amount: int) -> void:
	_update_essence_display(new_amount)


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

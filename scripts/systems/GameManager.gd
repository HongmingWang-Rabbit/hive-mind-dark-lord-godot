extends Node
## Core game manager - tracks state and win/lose conditions

var game_state: Enums.GameState = Enums.GameState.MENU
var corruption_percent: float = 0.0
var threat_level: Enums.ThreatLevel = Enums.ThreatLevel.NONE


func _ready() -> void:
	EventBus.tile_corrupted.connect(_on_tile_corrupted)


func _process(delta: float) -> void:
	if game_state == Enums.GameState.PLAYING:
		Essence.tick(delta)


func start_game() -> void:
	reset_game()
	game_state = Enums.GameState.PLAYING


func reset_game() -> void:
	game_state = Enums.GameState.MENU
	corruption_percent = 0.0
	threat_level = Enums.ThreatLevel.NONE
	Essence.reset()
	HivePool.reset()
	WorldManager.reset()


func pause_game() -> void:
	if game_state == Enums.GameState.PLAYING:
		game_state = Enums.GameState.PAUSED
		get_tree().paused = true


func resume_game() -> void:
	if game_state == Enums.GameState.PAUSED:
		game_state = Enums.GameState.PLAYING
		get_tree().paused = false


func check_win_lose() -> void:
	if corruption_percent >= GameConstants.WIN_THRESHOLD:
		game_state = Enums.GameState.WON
		EventBus.game_won.emit()


func update_corruption(new_percent: float) -> void:
	corruption_percent = new_percent
	EventBus.corruption_changed.emit(corruption_percent)
	_update_threat_level()
	check_win_lose()


func _update_threat_level() -> void:
	var new_level := Enums.ThreatLevel.NONE
	var thresholds := GameConstants.THREAT_THRESHOLDS

	# Check thresholds from highest to lowest
	for i in range(thresholds.size() - 1, -1, -1):
		if corruption_percent >= thresholds[i]:
			new_level = (i + 1) as Enums.ThreatLevel
			break

	if new_level != threat_level:
		threat_level = new_level
		EventBus.threat_level_changed.emit(threat_level)


func _on_tile_corrupted(_tile_pos: Vector2i) -> void:
	Essence.add_income(GameConstants.ESSENCE_PER_TILE)

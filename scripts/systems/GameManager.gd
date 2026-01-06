extends Node
## Core game manager - tracks state and win/lose conditions

var game_state: Enums.GameState = Enums.GameState.MENU
var corruption_percent: float = 0.0


func _ready() -> void:
	EventBus.tile_corrupted.connect(_on_tile_corrupted)
	EventBus.alarm_triggered.connect(_on_alarm_triggered)


func _process(delta: float) -> void:
	if game_state == Enums.GameState.PLAYING:
		Essence.tick(delta)


func start_game() -> void:
	reset_game()
	game_state = Enums.GameState.PLAYING


func reset_game() -> void:
	game_state = Enums.GameState.MENU
	corruption_percent = 0.0
	Essence.reset()
	HivePool.reset()
	WorldManager.reset()
	SpatialGrid.reset()
	ThreatSystem.reset()


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
	_update_threat_from_corruption()
	check_win_lose()


func _update_threat_from_corruption() -> void:
	## Update corruption-based threat source (linear scaling from min to max)
	var min_corr := GameConstants.THREAT_CORRUPTION_MIN
	var max_corr := GameConstants.THREAT_CORRUPTION_MAX

	# Linear scale: 0.0 at min_corr, 1.0 at max_corr
	var threat_value := 0.0
	if corruption_percent >= min_corr:
		threat_value = clampf(
			(corruption_percent - min_corr) / (max_corr - min_corr),
			0.0,
			1.0
		)

	ThreatSystem.set_source(
		GameConstants.THREAT_SOURCE_CORRUPTION,
		threat_value
	)


func _on_tile_corrupted(_tile_pos: Vector2i) -> void:
	Essence.add_income(GameConstants.ESSENCE_PER_TILE)


func _on_alarm_triggered(alarm_position: Vector2) -> void:
	## Alarm tower was triggered - set threat floor and attract enemies
	ThreatSystem.set_source(
		GameConstants.THREAT_SOURCE_ALARM_TOWER,
		GameConstants.THREAT_ALARM_TOWER_FLOOR
	)
	_attract_enemies_to_position(alarm_position)


func _attract_enemies_to_position(target_pos: Vector2) -> void:
	## Make nearby enemies move toward the alarm position
	var enemies := get_tree().get_nodes_in_group(GameConstants.GROUP_ENEMIES)

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue

		var distance: float = enemy.global_position.distance_to(target_pos)
		if distance <= GameConstants.ALARM_ENEMY_ATTRACT_RADIUS:
			# Tell enemy to investigate the alarm
			if enemy.has_method("investigate_position"):
				enemy.investigate_position(target_pos)

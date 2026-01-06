extends Node
## Manages threat level from multiple sources
## Threat = max(all sources), only increases, never decreases

# Sources dictionary: {source_id: float value}
var _sources: Dictionary = {}

# Cached threat value (max of all sources)
var _threat_value: float = 0.0

# Cached threat level (derived from value)
var _threat_level: Enums.ThreatLevel = Enums.ThreatLevel.NONE


func _ready() -> void:
	_connect_signals()


func _connect_signals() -> void:
	EventBus.dark_lord_spotted_by_military.connect(_on_dark_lord_spotted_by_military)


func set_source(source_id: String, value: float) -> void:
	## Set or update a threat source. Value is clamped to 0.0-1.0.
	## Threat only increases - if new value < current source value, ignored.
	var clamped_value := clampf(value, 0.0, 1.0)
	var current_value := _sources.get(source_id, 0.0) as float

	# Only increase, never decrease
	if clamped_value <= current_value:
		return

	_sources[source_id] = clamped_value
	_recalculate_threat()


func remove_source(source_id: String) -> void:
	## Remove a threat source (rarely used since threat only increases)
	## This is mainly for cleanup on game reset
	if _sources.has(source_id):
		_sources.erase(source_id)


func get_threat_value() -> float:
	return _threat_value


func get_threat_level() -> Enums.ThreatLevel:
	return _threat_level


func get_source_value(source_id: String) -> float:
	return _sources.get(source_id, 0.0)


func _recalculate_threat() -> void:
	## Recalculate threat as max of all sources
	var old_value := _threat_value
	var old_level := _threat_level

	# Find max of all sources
	var max_value := 0.0
	for source_value: float in _sources.values():
		if source_value > max_value:
			max_value = source_value

	# Only increase (defensive check)
	if max_value <= _threat_value:
		return

	_threat_value = max_value
	_threat_level = _value_to_level(_threat_value)

	# Emit signals
	if _threat_value != old_value:
		EventBus.threat_value_changed.emit(_threat_value, old_value)

	if _threat_level != old_level:
		EventBus.threat_level_changed.emit(_threat_level)


func _value_to_level(value: float) -> Enums.ThreatLevel:
	## Convert 0.0-1.0 float to ThreatLevel enum
	var thresholds := GameConstants.THREAT_LEVEL_THRESHOLDS

	# Check thresholds from highest to lowest
	for i in range(thresholds.size() - 1, -1, -1):
		if value >= thresholds[i]:
			return (i + 1) as Enums.ThreatLevel

	return Enums.ThreatLevel.NONE


func _on_dark_lord_spotted_by_military(_enemy_position: Vector2) -> void:
	## Military enemy detected Dark Lord - set threat floor
	set_source(
		GameConstants.THREAT_SOURCE_MILITARY_SIGHTING,
		GameConstants.THREAT_MILITARY_SIGHTING_FLOOR
	)


func reset() -> void:
	## Reset all threat state (called on game reset)
	_sources.clear()
	_threat_value = 0.0
	_threat_level = Enums.ThreatLevel.NONE

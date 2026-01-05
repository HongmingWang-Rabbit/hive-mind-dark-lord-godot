extends Node2D
## Reusable health component for any entity
## Add as child of entity, call setup() to initialize, take_damage() when hit
## Emits died signal when HP reaches 0

const HealthBar := preload("res://scripts/ui/HealthBar.gd")

signal died
signal health_changed(current_hp: int, max_hp: int)

var _max_hp: int = 1
var _current_hp: int = 1
var _health_bar: Node2D


func _ready() -> void:
	_setup_health_bar()


func _setup_health_bar() -> void:
	_health_bar = HealthBar.new()
	add_child(_health_bar)


func setup(max_hp: int, current_hp: int = -1) -> void:
	## Initialize health. current_hp defaults to max if not specified.
	_max_hp = max_hp
	_current_hp = current_hp if current_hp >= 0 else max_hp
	if _health_bar:
		_health_bar.setup(_max_hp, _current_hp)


func take_damage(amount: int) -> void:
	## Apply damage and update health bar. Emits died when HP <= 0.
	_current_hp -= amount
	if _health_bar:
		_health_bar.update_health(_current_hp)
	health_changed.emit(_current_hp, _max_hp)
	if _current_hp <= 0:
		died.emit()


func heal(amount: int) -> void:
	## Heal entity up to max HP
	_current_hp = mini(_current_hp + amount, _max_hp)
	if _health_bar:
		_health_bar.update_health(_current_hp)
	health_changed.emit(_current_hp, _max_hp)


func get_hp() -> int:
	return _current_hp


func get_max_hp() -> int:
	return _max_hp


func is_alive() -> bool:
	return _current_hp > 0

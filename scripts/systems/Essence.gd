extends Node
## Resource system - manages essence income and drain

signal essence_changed(new_amount: int)
signal essence_depleted()

var current: int
var income_rate: float = 0.0
var drain_rate: float = 0.0


func _ready() -> void:
	reset()


func reset() -> void:
	current = GameConstants.STARTING_ESSENCE
	income_rate = 0.0
	drain_rate = GameConstants.DARK_LORD_UPKEEP


func tick(delta: float) -> void:
	var net_rate := income_rate - drain_rate
	var change := int(net_rate * delta)

	if change != 0:
		modify(change)


func modify(amount: int) -> void:
	var old := current
	current = max(0, current + amount)

	if current != old:
		essence_changed.emit(current)

	if current == 0 and old > 0:
		essence_depleted.emit()


func can_afford(cost: int) -> bool:
	return current >= cost


func spend(cost: int) -> bool:
	if not can_afford(cost):
		return false
	modify(-cost)
	return true


func add_income(amount: float) -> void:
	income_rate += amount


func remove_income(amount: float) -> void:
	income_rate = max(0.0, income_rate - amount)


func add_drain(amount: float) -> void:
	drain_rate += amount


func remove_drain(amount: float) -> void:
	drain_rate = max(0.0, drain_rate - amount)

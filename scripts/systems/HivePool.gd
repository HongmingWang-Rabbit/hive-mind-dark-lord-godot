extends Node
## Minion pool system - tracks all minions by type and assignment

# Pool structure: {MinionType: {MinionAssignment: count}}
var pool: Dictionary = {}
var auto_defend_percent: float = 0.0


func _ready() -> void:
	_init_pool()


func _init_pool() -> void:
	pool.clear()
	for type in Enums.MinionType.values():
		pool[type] = {}
		for assignment in Enums.MinionAssignment.values():
			pool[type][assignment] = 0


func reset() -> void:
	_init_pool()
	auto_defend_percent = 0.0


func spawn_minion(type: Enums.MinionType) -> bool:
	var stats: Dictionary = GameConstants.MINION_STATS.get(type, {})
	var cost: int = stats.get("cost", 0)

	if not Essence.spend(cost):
		return false

	pool[type][Enums.MinionAssignment.IDLE] += 1
	Essence.add_drain(stats.get("upkeep", 0))
	return true


func kill_minion(type: Enums.MinionType, assignment: Enums.MinionAssignment) -> void:
	if pool[type][assignment] > 0:
		pool[type][assignment] -= 1
		var stats: Dictionary = GameConstants.MINION_STATS.get(type, {})
		Essence.remove_drain(stats.get("upkeep", 0))


func send_attack(target: Vector2, percent: float, stance: Enums.Stance) -> void:
	for type in pool.keys():
		var idle_count: int = pool[type][Enums.MinionAssignment.IDLE]
		var to_send := int(idle_count * percent)
		pool[type][Enums.MinionAssignment.IDLE] -= to_send
		pool[type][Enums.MinionAssignment.ATTACKING] += to_send

	EventBus.attack_ordered.emit(target, percent, stance)


func recall_attackers() -> void:
	for type in pool.keys():
		var attacking: int = pool[type][Enums.MinionAssignment.ATTACKING]
		pool[type][Enums.MinionAssignment.IDLE] += attacking
		pool[type][Enums.MinionAssignment.ATTACKING] = 0


func get_count(type: Enums.MinionType, assignment: Enums.MinionAssignment) -> int:
	return pool[type][assignment]


func get_idle_count(type: Enums.MinionType) -> int:
	return pool[type][Enums.MinionAssignment.IDLE]


func get_total_count(type: Enums.MinionType) -> int:
	var total := 0
	for assignment in Enums.MinionAssignment.values():
		total += pool[type][assignment]
	return total


func get_all_idle() -> int:
	var total := 0
	for type in pool.keys():
		total += pool[type][Enums.MinionAssignment.IDLE]
	return total


func get_all_count() -> int:
	var total := 0
	for type in pool.keys():
		for assignment in Enums.MinionAssignment.values():
			total += pool[type][assignment]
	return total

class_name Health
extends RefCounted

signal changed(current_health: int, max_health: int)

var max_health: int
var current_health: int

func _init(starting_max_health: int = 1) -> void:
	max_health = max(1, starting_max_health)
	current_health = max_health


func take(amount: int) -> void:
	set_current(current_health - amount)


func set_current(value: int) -> void:
	current_health = clamp(value, 0, max_health)
	changed.emit(current_health, max_health)


func is_empty() -> bool:
	return current_health <= 0

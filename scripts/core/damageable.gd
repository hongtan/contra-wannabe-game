class_name Damageable
extends RefCounted

signal health_changed(current_health: int, max_health: int)
signal died

var health: Health
var is_dead := false

func _init(max_health: int = 1) -> void:
	health = Health.new(max_health)
	health.changed.connect(_on_health_changed)


func take_damage(amount: int) -> void:
	if is_dead or amount <= 0:
		return

	health.take(amount)
	if health.is_empty() and not is_dead:
		is_dead = true
		died.emit()


func kill() -> void:
	if is_dead:
		return

	take_damage(health.current_health)


func get_current_health() -> int:
	return health.current_health


func get_max_health() -> int:
	return health.max_health


func _on_health_changed(current_health: int, max_health: int) -> void:
	health_changed.emit(current_health, max_health)

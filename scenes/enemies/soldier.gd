extends EnemyBase

@export var start_direction := -1

func _ready() -> void:
	add_to_group("soldier")
	direction = start_direction
	super._ready()

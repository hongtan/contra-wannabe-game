extends CanvasLayer

@onready var health_label: Label = $MarginContainer/HealthLabel
@onready var status_label: Label = $MarginContainer/StatusLabel

func set_player(player: Node) -> void:
	player.health_changed.connect(_on_player_health_changed)
	_on_player_health_changed(player.get_current_health(), player.get_max_health())


func _on_player_health_changed(current_health: int, max_health: int) -> void:
	health_label.text = "HP: %d / %d" % [current_health, max_health]


func set_status(message: String) -> void:
	status_label.text = message

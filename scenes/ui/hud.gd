extends CanvasLayer

@onready var health_label: Label = $MarginContainer/HealthLabel
@onready var status_label: Label = $MarginContainer/StatusLabel
@onready var intro_overlay: Control = $IntroOverlay
@onready var center_message: Label = $CenterMessage

func set_player(player: Node) -> void:
	player.health_changed.connect(_on_player_health_changed)
	_on_player_health_changed(player.get_current_health(), player.get_max_health())


func _on_player_health_changed(current_health: int, max_health: int) -> void:
	health_label.text = "HP: %d / %d" % [current_health, max_health]


func set_status(message: String) -> void:
	status_label.text = message


func show_intro() -> void:
	intro_overlay.visible = true
	center_message.visible = false


func hide_intro() -> void:
	intro_overlay.visible = false


func show_center_message(message: String) -> void:
	center_message.text = message
	center_message.visible = true


func hide_center_message() -> void:
	center_message.visible = false

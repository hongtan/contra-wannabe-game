extends Area2D

const Globals = preload("res://scripts/core/globals.gd")

@export var pickup_scene: PackedScene = preload("res://scenes/powerups/weapon_pickup.tscn")
@export var weapon_id := "m"
@export var speed := 120.0
@export var wave_amplitude := 26.0
@export var wave_frequency := 2.4
@export var stage_width_limit := 3800.0

var start_position := Vector2.ZERO
var travel_time := 0.0
var destroyed := false

@onready var body: Polygon2D = $Body
@onready var wing_left: Polygon2D = $WingLeft
@onready var wing_right: Polygon2D = $WingRight
@onready var capsule: Polygon2D = $Capsule
@onready var label: Label = $Label

func _ready() -> void:
	add_to_group(Globals.POWERUP_CARRIER_GROUP)
	start_position = global_position
	_update_visuals()


func _physics_process(delta: float) -> void:
	if destroyed:
		return

	travel_time += delta
	global_position.x += speed * delta
	global_position.y = start_position.y + sin(travel_time * wave_frequency * TAU) * wave_amplitude

	if global_position.x > stage_width_limit:
		queue_free()


func take_damage(_amount: int) -> void:
	if destroyed:
		return

	destroyed = true
	_drop_pickup()
	queue_free()


func _drop_pickup() -> void:
	var pickup := pickup_scene.instantiate()
	pickup.weapon_id = weapon_id
	get_parent().add_child(pickup)
	pickup.global_position = global_position


func _update_visuals() -> void:
	body.color = Color(0.5, 0.52, 0.6, 1.0)
	wing_left.color = Color(0.78, 0.82, 0.9, 1.0)
	wing_right.color = Color(0.78, 0.82, 0.9, 1.0)
	capsule.color = _get_weapon_color()
	label.text = weapon_id.to_upper()


func _get_weapon_color() -> Color:
	if weapon_id == "s":
		return Color(0.12, 0.58, 0.28, 1.0)
	return Color(0.72, 0.12, 0.12, 1.0)

extends Area2D

const Globals = preload("res://scripts/core/globals.gd")

@export var weapon_id := "m"
@export var fall_gravity := 900.0
@export var max_fall_speed := 260.0
@export var ground_offset := 8.0

var fall_speed := 0.0
var grounded := false

@onready var body: Polygon2D = $Body
@onready var label: Label = $Label

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_update_visuals()


func _physics_process(delta: float) -> void:
	if grounded:
		return

	fall_speed = minf(fall_speed + fall_gravity * delta, max_fall_speed)
	var next_position := global_position + Vector2.DOWN * fall_speed * delta
	var query := PhysicsRayQueryParameters2D.create(global_position, next_position + Vector2.DOWN * ground_offset, 1)
	var result := get_world_2d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		global_position = next_position
		return
	if result.collider is Node and result.collider.is_in_group(Globals.PLAYER_GROUP):
		global_position = next_position
		return

	global_position.y = result.position.y - ground_offset
	fall_speed = 0.0
	grounded = true


func _on_body_entered(body_node: Node) -> void:
	if not body_node.is_in_group(Globals.PLAYER_GROUP):
		return
	if body_node.has_method("equip_weapon"):
		body_node.equip_weapon(weapon_id)
	queue_free()


func _update_visuals() -> void:
	body.color = _get_weapon_color()
	label.text = weapon_id.to_upper()


func _get_weapon_color() -> Color:
	if weapon_id == "s":
		return Color(0.12, 0.58, 0.28, 1.0)
	return Color(0.72, 0.12, 0.12, 1.0)

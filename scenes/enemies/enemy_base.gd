class_name EnemyBase
extends CharacterBody2D

const Damageable = preload("res://scripts/core/damageable.gd")
const Globals = preload("res://scripts/core/globals.gd")

@export var move_speed := 60.0
@export var patrol_distance := 96.0
@export var gravity := 1200.0
@export var max_health := 2
@export var contact_damage := 1

@onready var sprite: Sprite2D = $Sprite2D

var direction := -1
var start_x := 0.0
var damageable: Damageable

func _ready() -> void:
	add_to_group(Globals.ENEMY_GROUP)
	start_x = global_position.x
	damageable = Damageable.new(max_health)
	damageable.died.connect(_on_died)
	_update_facing()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	velocity.x = direction * move_speed
	move_and_slide()

	if patrol_distance > 0.0 and abs(global_position.x - start_x) >= patrol_distance:
		direction *= -1
	if is_on_wall():
		direction *= -1
	_update_facing()
	_apply_contact_damage()
	_cleanup_if_far_away()


func take_damage(amount: int) -> void:
	damageable.take_damage(amount)


func _update_facing() -> void:
	sprite.flip_h = direction > 0


func _apply_contact_damage() -> void:
	for index in range(get_slide_collision_count()):
		var collision := get_slide_collision(index)
		var collider := collision.get_collider()
		if collider is Node and collider.is_in_group(Globals.PLAYER_GROUP) and collider.has_method("take_damage"):
			collider.take_damage(contact_damage)


func _on_died() -> void:
	queue_free()


func _cleanup_if_far_away() -> void:
	if global_position.y > 560.0:
		queue_free()
		return

	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return

	var half_width := get_viewport_rect().size.x * 0.5
	var left_limit := camera.global_position.x - half_width - 192.0
	var right_limit := camera.global_position.x + half_width + 192.0
	if global_position.x < left_limit or global_position.x > right_limit:
		queue_free()

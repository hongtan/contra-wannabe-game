class_name EnemyBase
extends CharacterBody2D

const Damageable = preload("res://scripts/core/damageable.gd")
const Globals = preload("res://scripts/core/globals.gd")

@export var move_speed := 60.0
@export var patrol_distance := 96.0
@export var gravity := 1200.0
@export var max_health := 2
@export var contact_damage := 1
@export var bullet_scene: PackedScene = preload("res://scenes/projectiles/bullet.tscn")
@export var fire_interval := 1.35
@export var bullet_speed := 210.0
@export var fire_range := 260.0

@onready var visual_root = $VisualRoot

var direction := -1
var start_x := 0.0
var damageable: Damageable
var shot_cooldown := 0.0

func _ready() -> void:
	add_to_group(Globals.ENEMY_GROUP)
	start_x = global_position.x
	damageable = Damageable.new(max_health)
	damageable.died.connect(_on_died)
	shot_cooldown = randf_range(0.15, fire_interval)
	_update_facing()
	visual_root.set_walking(false, 0.0)
	visual_root.set_aim_direction(Vector2(float(direction), 0.15), 0.0, 0.0)


func _physics_process(delta: float) -> void:
	shot_cooldown = maxf(0.0, shot_cooldown - delta)

	if not is_on_floor():
		velocity.y += gravity * delta

	velocity.x = direction * move_speed
	move_and_slide()

	if patrol_distance > 0.0 and abs(global_position.x - start_x) >= patrol_distance:
		direction *= -1
	if is_on_wall():
		direction *= -1
	_update_facing()
	visual_root.set_walking(absf(velocity.x) > 0.05, delta)
	_update_combat(delta)
	_apply_contact_damage()
	_cleanup_if_far_away()


func take_damage(amount: int) -> void:
	damageable.take_damage(amount)


func _update_facing() -> void:
	visual_root.set_facing(direction)


func _apply_contact_damage() -> void:
	for index in range(get_slide_collision_count()):
		var collision := get_slide_collision(index)
		var collider := collision.get_collider()
		if collider is Node and collider.is_in_group(Globals.PLAYER_GROUP) and collider.has_method("take_damage"):
			collider.take_damage(contact_damage)


func _update_combat(delta: float) -> void:
	var player := _get_player()
	var aim_vector := Vector2(float(direction), 0.15)
	if player != null:
		var to_player := player.global_position - global_position
		if absf(to_player.x) <= fire_range:
			if absf(to_player.x) > 4.0:
				direction = 1 if to_player.x > 0.0 else -1
				_update_facing()
			aim_vector = to_player.normalized()
			if shot_cooldown <= 0.0:
				_fire(aim_vector)
				shot_cooldown = fire_interval

	visual_root.set_aim_direction(aim_vector, delta, 8.0)


func _fire(shot_direction: Vector2) -> void:
	var bullet := bullet_scene.instantiate()
	bullet.faction = Globals.ENEMY_GROUP
	bullet.owner_ref = self
	bullet.direction = direction
	bullet.direction_vector = shot_direction.normalized()
	bullet.speed = bullet_speed
	bullet.modulate = Color(1.0, 0.78, 0.35, 1.0)
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = visual_root.get_muzzle_global_position()


func _get_player() -> Node2D:
	var players := get_tree().get_nodes_in_group(Globals.PLAYER_GROUP)
	if players.is_empty():
		return null
	return players[0] as Node2D


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

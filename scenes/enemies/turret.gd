extends Node2D

const Damageable = preload("res://scripts/core/damageable.gd")
const Globals = preload("res://scripts/core/globals.gd")

@export var bullet_scene: PackedScene = preload("res://scenes/projectiles/bullet.tscn")
@export var fire_interval := 1.1
@export var bullet_speed := 240.0
@export_range(0.0, 90.0, 1.0) var max_aim_angle_deg := 30.0
@export var max_health := 3
@export var muzzle_length := 22.0
@export var facing_direction := -1

var damageable: Damageable
var shot_cooldown := 0.0

@onready var hurtbox: Area2D = $Hurtbox
@onready var hurtbox_shape: CollisionShape2D = $Hurtbox/CollisionShape2D
@onready var base: Polygon2D = $Base
@onready var barrel_pivot: Node2D = $BarrelPivot
@onready var barrel: Polygon2D = $BarrelPivot/Barrel


func _ready() -> void:
	add_to_group(Globals.ENEMY_GROUP)
	damageable = Damageable.new(max_health)
	damageable.died.connect(_on_died)
	_apply_visuals()
	shot_cooldown = randf_range(0.1, fire_interval)


func _physics_process(delta: float) -> void:
	if not _is_in_camera_view():
		return

	var player := _get_player()
	if player == null:
		return

	var shot_direction := _get_shot_direction(player.global_position)
	if shot_direction == Vector2.ZERO:
		barrel_pivot.rotation = PI if facing_direction < 0 else 0.0
		return

	barrel_pivot.rotation = shot_direction.angle()
	shot_cooldown -= delta
	if shot_cooldown <= 0.0:
		_fire(shot_direction)
		shot_cooldown = fire_interval


func take_damage(amount: int) -> void:
	damageable.take_damage(amount)
	base.modulate = Color(1.0, 0.65, 0.65, 1.0)
	barrel.modulate = Color(1.0, 0.65, 0.65, 1.0)
	var tween := create_tween()
	tween.tween_property(base, "modulate", Color.WHITE, 0.15)
	tween.parallel().tween_property(barrel, "modulate", Color.WHITE, 0.15)


func _apply_visuals() -> void:
	var hurtbox_rect := RectangleShape2D.new()
	hurtbox_rect.size = Vector2(26.0, 28.0)
	hurtbox_shape.shape = hurtbox_rect
	hurtbox.position = Vector2(0.0, -14.0)
	hurtbox_shape.position = Vector2.ZERO

	base.polygon = PackedVector2Array([
		Vector2(-14.0, -28.0),
		Vector2(14.0, -28.0),
		Vector2(18.0, -6.0),
		Vector2(-18.0, -6.0),
	])
	barrel.polygon = PackedVector2Array([
		Vector2(-2.0, -4.0),
		Vector2(muzzle_length, -4.0),
		Vector2(muzzle_length, 4.0),
		Vector2(-2.0, 4.0),
	])
	barrel_pivot.position = Vector2(0.0, -20.0)
	barrel_pivot.rotation = PI if facing_direction < 0 else 0.0


func _get_player() -> Node2D:
	var players := get_tree().get_nodes_in_group(Globals.PLAYER_GROUP)
	if players.is_empty():
		return null
	return players[0] as Node2D


func _get_shot_direction(target_position: Vector2) -> Vector2:
	var aim_vector := target_position - barrel_pivot.global_position
	if aim_vector == Vector2.ZERO:
		return Vector2.ZERO

	var aim_dir := aim_vector.normalized()
	var forward_dir := Vector2.LEFT if facing_direction < 0 else Vector2.RIGHT
	var angle_delta := rad_to_deg(abs(forward_dir.angle_to(aim_dir)))
	if angle_delta > max_aim_angle_deg:
		return Vector2.ZERO
	return aim_dir


func _fire(shot_direction: Vector2) -> void:
	var bullet := bullet_scene.instantiate()
	bullet.faction = Globals.ENEMY_GROUP
	bullet.owner_ref = self
	bullet.direction_vector = shot_direction
	bullet.speed = bullet_speed
	bullet.modulate = Color(1.0, 0.45, 0.45, 1.0)
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = barrel_pivot.global_position + shot_direction * muzzle_length


func _on_died() -> void:
	queue_free()


func _is_in_camera_view() -> bool:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return false

	var half_size: Vector2 = get_viewport_rect().size * 0.5
	var margin := Vector2(48.0, 48.0)
	var top_left := camera.global_position - half_size - margin
	var bottom_right := camera.global_position + half_size + margin
	return global_position.x >= top_left.x and global_position.x <= bottom_right.x and global_position.y >= top_left.y and global_position.y <= bottom_right.y

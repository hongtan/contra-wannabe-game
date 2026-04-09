extends CharacterBody2D

const Damageable = preload("res://scripts/core/damageable.gd")
const Globals = preload("res://scripts/core/globals.gd")

signal health_changed(current_health: int, max_health: int)
signal died

@export var move_speed := 180.0
@export var jump_velocity := -360.0
@export var gravity := 1200.0
@export var swim_move_speed := 120.0
@export var swim_gravity := 220.0
@export var swim_buoyancy := 180.0
@export var swim_stroke_velocity := -230.0
@export var water_exit_jump_velocity := -340.0
@export var swim_sink_acceleration := 320.0
@export var swim_max_fall_speed := 120.0
@export var max_health := 5
@export var invulnerability_time := 0.75
@export var fall_death_y := 560.0
@export var bullet_scene: PackedScene = preload("res://scenes/projectiles/bullet.tscn")
@export var aim_reset_speed := 10.0
@export var normal_fire_interval := 0.2
@export var machine_fire_interval := 0.1
@export var spread_fire_interval := 0.24

@onready var visual_root = $VisualRoot

const WEAPON_NORMAL := "normal"
const WEAPON_MACHINE := "m"
const WEAPON_SPREAD := "s"

var facing_direction := 1
var invulnerable := false
var damageable: Damageable
var min_world_x := -INF
var aim_direction := Vector2.RIGHT
var in_water := false
var current_weapon := WEAPON_NORMAL
var shot_cooldown := 0.0

func _ready() -> void:
	add_to_group(Globals.PLAYER_GROUP)
	damageable = Damageable.new(max_health)
	damageable.health_changed.connect(_on_health_changed)
	damageable.died.connect(_on_died)
	aim_direction = Vector2(float(facing_direction), 0.0)
	health_changed.emit(get_current_health(), get_max_health())


func _physics_process(delta: float) -> void:
	if damageable.is_dead:
		return

	shot_cooldown = maxf(0.0, shot_cooldown - delta)

	var axis := Input.get_axis("move_left", "move_right")
	velocity.x = axis * (swim_move_speed if in_water else move_speed)

	if axis != 0.0:
		facing_direction = 1 if axis > 0.0 else -1
		if aim_direction.x == 0.0:
			aim_direction.x = float(facing_direction)

	_update_aim(delta)
	visual_root.set_walking(absf(axis) > 0.05, delta)

	if in_water:
		_update_swimming(delta)
	else:
		if not is_on_floor():
			velocity.y += gravity * delta

		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = jump_velocity

	if Input.is_action_pressed("shoot"):
		_try_shoot()

	move_and_slide()

	if global_position.x < min_world_x:
		global_position.x = min_world_x
		if velocity.x < 0.0:
			velocity.x = 0.0

	if not in_water and global_position.y >= fall_death_y:
		kill()


func _try_shoot() -> void:
	if shot_cooldown > 0.0:
		return
	_shoot()
	shot_cooldown = _get_weapon_fire_interval()


func _shoot() -> void:
	if current_weapon == WEAPON_SPREAD:
		_fire_spread_weapon()
		return

	_spawn_bullet(aim_direction, _get_weapon_damage(), _get_weapon_bullet_color())


func take_damage(amount: int) -> void:
	if invulnerable or damageable.is_dead:
		return

	damageable.take_damage(amount)
	if not damageable.is_dead:
		_start_invulnerability()


func get_current_health() -> int:
	return damageable.get_current_health()


func get_max_health() -> int:
	return damageable.get_max_health()


func set_min_world_x(value: float) -> void:
	min_world_x = value


func set_in_water(value: bool) -> void:
	if in_water == value:
		return

	in_water = value
	if in_water:
		velocity.y = minf(velocity.y, 90.0)


func kill() -> void:
	if damageable.is_dead:
		return

	damageable.kill()


func equip_weapon(weapon_id: String) -> void:
	if weapon_id == WEAPON_MACHINE or weapon_id == WEAPON_SPREAD:
		current_weapon = weapon_id
		return
	current_weapon = WEAPON_NORMAL


func _start_invulnerability() -> void:
	invulnerable = true
	modulate = Color(1.0, 1.0, 1.0, 0.5)
	await get_tree().create_timer(invulnerability_time).timeout
	invulnerable = false
	modulate = Color.WHITE


func _on_health_changed(current_health: int, health_max: int) -> void:
	health_changed.emit(current_health, health_max)


func _on_died() -> void:
	visible = false
	set_physics_process(false)
	died.emit()


func _update_aim(delta: float) -> void:
	var aim_vertical := Input.get_axis("aim_up", "aim_down")
	var move_axis := Input.get_axis("move_left", "move_right")
	var shot_vector := Vector2(float(facing_direction), 0.0)
	if aim_vertical < -0.5:
		if absf(move_axis) > 0.2:
			shot_vector = Vector2(sign(move_axis), -1.0)
		else:
			shot_vector = Vector2.UP
	elif aim_vertical > 0.5:
		shot_vector = Vector2(float(facing_direction), 1.0)

	if shot_vector == Vector2.ZERO:
		shot_vector = Vector2(float(facing_direction), 0.0)

	aim_direction = shot_vector.normalized()
	visual_root.set_facing(facing_direction)
	visual_root.set_aim_direction(aim_direction, delta, aim_reset_speed)


func _get_weapon_damage() -> int:
	return 2 if current_weapon == WEAPON_MACHINE else 1


func _get_weapon_bullet_color() -> Color:
	if current_weapon == WEAPON_MACHINE:
		return Color(1.0, 0.35, 0.35, 1.0)
	if current_weapon == WEAPON_SPREAD:
		return Color(0.4, 0.95, 0.6, 1.0)
	return Color.WHITE


func _get_weapon_fire_interval() -> float:
	if current_weapon == WEAPON_MACHINE:
		return machine_fire_interval
	if current_weapon == WEAPON_SPREAD:
		return spread_fire_interval
	return normal_fire_interval


func _fire_spread_weapon() -> void:
	var spread_angles := [-0.55, -0.28, 0.0, 0.28, 0.55]
	for angle_offset in spread_angles:
		_spawn_bullet(aim_direction.rotated(angle_offset), 1, _get_weapon_bullet_color())


func _spawn_bullet(direction_vector: Vector2, damage_value: int, bullet_color: Color) -> void:
	var bullet := bullet_scene.instantiate()
	bullet.direction = facing_direction
	bullet.direction_vector = direction_vector.normalized()
	bullet.owner_ref = self
	bullet.damage = damage_value
	bullet.modulate = bullet_color
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = visual_root.get_muzzle_global_position()


func _update_swimming(delta: float) -> void:
	velocity.y += swim_gravity * delta

	if Input.is_action_pressed("aim_down"):
		velocity.y += swim_sink_acceleration * delta
	else:
		velocity.y -= swim_buoyancy * delta

	if Input.is_action_just_pressed("jump"):
		velocity.y = water_exit_jump_velocity if is_on_floor() else swim_stroke_velocity

	velocity.y = clampf(velocity.y, minf(water_exit_jump_velocity, swim_stroke_velocity), swim_max_fall_speed)

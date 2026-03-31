extends Node2D

const Globals = preload("res://scripts/core/globals.gd")

@export var player_scene: PackedScene = preload("res://scenes/player/player.tscn")
@export var level_scene: PackedScene = preload("res://scenes/levels/level_01.tscn")
@export var hud_scene: PackedScene = preload("res://scenes/ui/hud.tscn")
@export var soldier_scene: PackedScene = preload("res://scenes/enemies/soldier.tscn")
@export var boss_scene: PackedScene = preload("res://scenes/enemies/boss_fortress.tscn")
@export var camera_ground_offset := 112.0
@export var enemy_spawn_interval_range := Vector2(1.2, 2.1)
@export var max_spawned_soldiers := 4

var level_instance: Node2D
var player_instance: CharacterBody2D
var hud_instance: CanvasLayer
var boss_instance
var spawn_timer := 0.0
var camera_anchor_y := 192.0
var camera_progress_x := 0.0
var camera_min_x := 0.0
var stage_right_x := 3200.0
var stage_end_x := 3200.0
var boss_trigger_x := INF
var boss_lock_end_x := 3200.0
var boss_fight_active := false
var mission_complete := false

@onready var camera_2d: Camera2D = $Camera2D

func _ready() -> void:
	randomize()
	_spawn_level()
	_spawn_player()
	_spawn_hud()
	_initialize_camera()
	_reset_spawn_timer()


func _physics_process(_delta: float) -> void:
	if player_instance == null:
		return
	if not is_instance_valid(player_instance):
		return

	_update_boss_encounter()
	_update_camera()
	if not boss_fight_active and not mission_complete:
		_update_enemy_spawning(_delta)


func _spawn_level() -> void:
	level_instance = level_scene.instantiate()
	add_child(level_instance)


func _spawn_player() -> void:
	player_instance = player_scene.instantiate()
	add_child(player_instance)

	var spawn_point := level_instance.get_node_or_null("PlayerSpawn")
	if spawn_point:
		player_instance.global_position = spawn_point.global_position

	player_instance.died.connect(_on_player_died)


func _spawn_hud() -> void:
	hud_instance = hud_scene.instantiate()
	add_child(hud_instance)
	hud_instance.set_player(player_instance)


func _on_player_died() -> void:
	await get_tree().create_timer(Globals.RESTART_DELAY).timeout
	get_tree().reload_current_scene()


func _initialize_camera() -> void:
	var half_width: float = get_viewport_rect().size.x * 0.5
	camera_min_x = half_width
	camera_progress_x = camera_min_x

	var spawn_point := level_instance.get_node_or_null("PlayerSpawn")
	if spawn_point:
		camera_anchor_y = spawn_point.global_position.y - camera_ground_offset

	var stage_end := level_instance.get_node_or_null("StageEnd")
	if stage_end:
		stage_end_x = stage_end.global_position.x
		stage_right_x = stage_end_x

	var boss_trigger := level_instance.get_node_or_null("BossTrigger")
	if boss_trigger:
		boss_trigger_x = boss_trigger.global_position.x

	var boss_lock_end := level_instance.get_node_or_null("BossArenaEnd")
	if boss_lock_end:
		boss_lock_end_x = boss_lock_end.global_position.x
	else:
		boss_lock_end_x = stage_end_x

	camera_2d.global_position = Vector2(camera_progress_x, camera_anchor_y)
	camera_2d.make_current()


func _update_camera() -> void:
	var half_width: float = get_viewport_rect().size.x * 0.5
	var max_camera_x: float = maxf(camera_min_x, stage_right_x - half_width)
	camera_progress_x = clamp(max(camera_progress_x, player_instance.global_position.x), camera_min_x, max_camera_x)
	camera_2d.global_position = Vector2(camera_progress_x, camera_anchor_y)

	var left_lock_x: float = maxf(24.0, camera_2d.global_position.x - half_width + 24.0)
	if player_instance.has_method("set_min_world_x"):
		player_instance.set_min_world_x(left_lock_x)


func _update_enemy_spawning(delta: float) -> void:
	if get_tree().get_nodes_in_group("soldier").size() >= max_spawned_soldiers:
		return

	spawn_timer -= delta
	if spawn_timer > 0.0:
		return

	if _spawn_random_soldier():
		_reset_spawn_timer()
	else:
		spawn_timer = 0.35


func _spawn_random_soldier() -> bool:
	var half_width: float = get_viewport_rect().size.x * 0.5
	var spawn_sides: Array[int] = [-1, 1]
	if randf() < 0.5:
		spawn_sides.reverse()

	for spawn_side in spawn_sides:
		var spawn_x: float = camera_2d.global_position.x + (half_width + 72.0) * float(spawn_side)
		var ground_position: Variant = _find_ground_position(spawn_x)
		if ground_position == null:
			continue

		var soldier := soldier_scene.instantiate()
		soldier.global_position = ground_position as Vector2
		soldier.start_direction = -1 if spawn_side > 0 else 1
		soldier.patrol_distance = 0.0
		level_instance.add_child(soldier)
		return true

	return false


func _find_ground_position(world_x: float) -> Variant:
	var direct_space := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		Vector2(world_x, 80.0),
		Vector2(world_x, 520.0),
		1
	)
	var result := direct_space.intersect_ray(query)
	if result.is_empty():
		return null
	return Vector2(world_x, result.position.y)


func _reset_spawn_timer() -> void:
	spawn_timer = randf_range(enemy_spawn_interval_range.x, enemy_spawn_interval_range.y)


func _update_boss_encounter() -> void:
	if mission_complete or boss_fight_active or boss_trigger_x == INF:
		return
	if player_instance.global_position.x < boss_trigger_x:
		return

	_start_boss_fight()


func _start_boss_fight() -> void:
	boss_fight_active = true
	stage_right_x = boss_lock_end_x
	spawn_timer = enemy_spawn_interval_range.y

	for soldier in get_tree().get_nodes_in_group("soldier"):
		soldier.queue_free()

	var boss_spawn := level_instance.get_node_or_null("BossSpawn")
	if boss_spawn == null:
		return

	boss_instance = boss_scene.instantiate()
	level_instance.add_child(boss_instance)
	boss_instance.global_position = boss_spawn.global_position
	boss_instance.connect("defeated", Callable(self, "_on_boss_defeated"))

	if hud_instance.has_method("set_status"):
		hud_instance.set_status("Boss fight: destroy the turrets, then hit the core.")


func _on_boss_defeated() -> void:
	boss_fight_active = false
	mission_complete = true
	stage_right_x = stage_end_x

	var boss_gate := level_instance.get_node_or_null("BossGate")
	if boss_gate:
		boss_gate.queue_free()
	var boss_gate_visual := level_instance.get_node_or_null("BossGateVisual")
	if boss_gate_visual:
		boss_gate_visual.queue_free()

	if hud_instance.has_method("set_status"):
		hud_instance.set_status("Mission complete.")

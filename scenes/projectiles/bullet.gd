extends Area2D

const Globals = preload("res://scripts/core/globals.gd")

@export var speed := 500.0
@export var damage := 1
@export var lifetime := 1.5

var direction := 1
var direction_vector := Vector2.ZERO
var faction := Globals.PLAYER_GROUP
var owner_ref: Node = null
var life_left := 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	life_left = lifetime
	_sync_visual_rotation()


func _physics_process(delta: float) -> void:
	var velocity := direction_vector
	if velocity == Vector2.ZERO:
		velocity = Vector2.RIGHT * direction
	else:
		velocity = velocity.normalized()

	rotation = velocity.angle()
	position += velocity * speed * delta
	life_left -= delta
	if life_left <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	_hit_node(body)


func _on_area_entered(area: Area2D) -> void:
	_hit_node(area)


func _hit_node(node: Node) -> void:
	var target := _resolve_target(node)
	if target == null or target == owner_ref:
		return

	if faction == Globals.PLAYER_GROUP:
		if target.has_method("take_damage") and (
			target.is_in_group(Globals.ENEMY_GROUP)
			or target.is_in_group(Globals.POWERUP_CARRIER_GROUP)
		):
			target.take_damage(damage)
			queue_free()
			return
	elif faction == Globals.ENEMY_GROUP:
		if target.is_in_group(Globals.PLAYER_GROUP) and target.has_method("take_damage"):
			target.take_damage(damage)
			queue_free()
			return

	if node is PhysicsBody2D:
		queue_free()


func _resolve_target(node: Node) -> Node:
	var current: Node = node
	while current != null:
		if current == owner_ref:
			return current
		if current.has_method("take_damage") or current.is_in_group(Globals.PLAYER_GROUP) or current.is_in_group(Globals.ENEMY_GROUP):
			return current
		current = current.get_parent()
	return null


func _sync_visual_rotation() -> void:
	var velocity := direction_vector
	if velocity == Vector2.ZERO:
		velocity = Vector2.RIGHT * direction
	rotation = velocity.normalized().angle()

class_name HumanoidVisual
extends Node2D

@export var include_gun := false
@export var head_color: Color = Color8(110, 193, 255)
@export var torso_color: Color = Color8(47, 111, 168)
@export var limb_color: Color = Color8(242, 194, 139)
@export var leg_color: Color = Color8(41, 68, 94)
@export var gun_color: Color = Color8(40, 40, 46)

var _facing := 1
var _walk_time := 0.0

var head: Polygon2D
var torso: Polygon2D
var back_arm: Polygon2D
var front_arm_pivot: Node2D
var front_arm: Polygon2D
var back_hand: Polygon2D
var front_hand: Polygon2D
var back_leg_pivot: Node2D
var front_leg_pivot: Node2D
var gun: Polygon2D
var muzzle_marker: Marker2D

func _ready() -> void:
	_build_visuals()


func set_facing(direction: int) -> void:
	_facing = 1 if direction >= 0 else -1
	scale.x = float(_facing)


func set_aim_direction(direction: Vector2, delta: float, aim_speed: float) -> void:
	if front_arm_pivot == null:
		return

	var local_direction := Vector2(float(_facing) * direction.x, direction.y)
	if local_direction == Vector2.ZERO:
		local_direction = Vector2.RIGHT
	else:
		local_direction = local_direction.normalized()

	var target_rotation := local_direction.angle()
	if delta > 0.0 and aim_speed > 0.0:
		front_arm_pivot.rotation = lerp_angle(front_arm_pivot.rotation, target_rotation, delta * aim_speed)
	else:
		front_arm_pivot.rotation = target_rotation


func set_walking(moving: bool, delta: float) -> void:
	if back_leg_pivot == null or front_leg_pivot == null:
		return

	if delta <= 0.0:
		back_leg_pivot.rotation = deg_to_rad(-6.0)
		front_leg_pivot.rotation = deg_to_rad(6.0)
		back_arm.rotation = deg_to_rad(-6.0)
		torso.position.y = -4.0
		head.position.y = -12.0
		return

	if moving:
		_walk_time += delta * 10.0
		var leg_swing := sin(_walk_time) * deg_to_rad(16.0)
		var arm_swing := sin(_walk_time) * deg_to_rad(8.0)
		back_leg_pivot.rotation = leg_swing
		front_leg_pivot.rotation = -leg_swing
		back_arm.rotation = -arm_swing
		torso.position.y = -4.0 + abs(cos(_walk_time)) * 0.6
		head.position.y = -12.0 + abs(cos(_walk_time)) * 0.4
	else:
		back_leg_pivot.rotation = lerp_angle(back_leg_pivot.rotation, deg_to_rad(-6.0), delta * 10.0)
		front_leg_pivot.rotation = lerp_angle(front_leg_pivot.rotation, deg_to_rad(6.0), delta * 10.0)
		back_arm.rotation = lerp_angle(back_arm.rotation, deg_to_rad(-6.0), delta * 10.0)
		torso.position.y = lerpf(torso.position.y, -4.0, delta * 10.0)
		head.position.y = lerpf(head.position.y, -12.0, delta * 10.0)


func get_muzzle_global_position() -> Vector2:
	if muzzle_marker != null:
		return muzzle_marker.global_position
	return global_position + Vector2(float(_facing) * 12.0, -3.0)


func _build_visuals() -> void:
	for child in get_children():
		child.queue_free()

	back_leg_pivot = Node2D.new()
	back_leg_pivot.name = "BackLegPivot"
	back_leg_pivot.position = Vector2(-4.0, 4.0)
	add_child(back_leg_pivot)
	_make_rect("BackLeg", Vector2.ZERO, Vector2(3.0, 8.0), leg_color, back_leg_pivot)

	front_leg_pivot = Node2D.new()
	front_leg_pivot.name = "FrontLegPivot"
	front_leg_pivot.position = Vector2(1.0, 4.0)
	add_child(front_leg_pivot)
	_make_rect("FrontLeg", Vector2.ZERO, Vector2(3.0, 8.0), leg_color, front_leg_pivot)

	back_arm = _make_rect("BackArm", Vector2(-6.0, -3.0), Vector2(2.0, 6.0), limb_color, self)
	back_hand = _make_rect("BackHand", Vector2(-6.5, 1.5), Vector2(3.0, 2.0), limb_color, self)
	torso = _make_rect("Torso", Vector2(-4.0, -4.0), Vector2(8.0, 8.0), torso_color, self)
	head = _make_rect("Head", Vector2(-3.0, -12.0), Vector2(6.0, 8.0), head_color, self)

	front_arm_pivot = Node2D.new()
	front_arm_pivot.name = "FrontArmPivot"
	front_arm_pivot.position = Vector2(4.0, -3.0)
	add_child(front_arm_pivot)

	front_arm = _make_rect("FrontArm", Vector2(0.0, -1.0), Vector2(6.0, 2.0), limb_color, front_arm_pivot)
	front_hand = _make_rect("FrontHand", Vector2(5.0, -1.5), Vector2(3.0, 3.0), limb_color, front_arm_pivot)

	if include_gun:
		gun = _make_rect("Gun", Vector2(6.0, -1.0), Vector2(8.0, 2.0), gun_color, front_arm_pivot)
		_make_rect("GunGrip", Vector2(8.0, 1.0), Vector2(2.0, 3.0), gun_color, front_arm_pivot)

	muzzle_marker = Marker2D.new()
	muzzle_marker.name = "Muzzle"
	muzzle_marker.position = Vector2(14.0 if include_gun else 8.0, 0.0)
	front_arm_pivot.add_child(muzzle_marker)

	set_facing(_facing)
	set_walking(false, 0.0)
	set_aim_direction(Vector2.RIGHT, 0.0, 0.0)


func _make_rect(name: String, position_value: Vector2, size: Vector2, color_value: Color, parent: Node) -> Polygon2D:
	var rect := Polygon2D.new()
	rect.name = name
	rect.position = position_value
	rect.color = color_value
	rect.polygon = PackedVector2Array([
		Vector2.ZERO,
		Vector2(size.x, 0.0),
		Vector2(size.x, size.y),
		Vector2(0.0, size.y)
	])
	parent.add_child(rect)
	return rect

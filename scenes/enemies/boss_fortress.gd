extends Node2D

const Damageable = preload("res://scripts/core/damageable.gd")
const Globals = preload("res://scripts/core/globals.gd")

signal defeated

@export var max_health := 12
@export var hover_amplitude := 10.0
@export var hover_speed := 1.25

var damageable: Damageable
var base_core_position := Vector2.ZERO
var hover_time := 0.0
var is_vulnerable := false

@onready var frame: Polygon2D = $Frame
@onready var armor: Polygon2D = $Armor
@onready var core_pivot: Node2D = $CorePivot
@onready var core_visual: Polygon2D = $CorePivot/CoreVisual
@onready var core_glow: Polygon2D = $CorePivot/CoreGlow
@onready var core_hurtbox: Area2D = $CorePivot/CoreHurtbox
@onready var core_shape: CollisionShape2D = $CorePivot/CoreHurtbox/CollisionShape2D
@onready var turrets: Array[Node] = [
	$TurretTop,
	$TurretCenter,
	$TurretBottom,
]


func _ready() -> void:
	add_to_group(Globals.ENEMY_GROUP)
	damageable = Damageable.new(max_health)
	damageable.died.connect(_on_died)
	base_core_position = core_pivot.position
	_apply_visuals()
	_refresh_vulnerability()


func _physics_process(delta: float) -> void:
	hover_time += delta
	core_pivot.position.y = base_core_position.y + sin(hover_time * hover_speed * TAU) * hover_amplitude
	core_glow.rotation -= delta * 0.7
	_refresh_vulnerability()


func take_damage(amount: int) -> void:
	if not is_vulnerable:
		_flash_blocked_hit()
		return

	damageable.take_damage(amount)
	_flash_damage()


func get_remaining_turret_count() -> int:
	var remaining := 0
	for turret in turrets:
		if is_instance_valid(turret):
			remaining += 1
	return remaining


func _refresh_vulnerability() -> void:
	var should_be_vulnerable := get_remaining_turret_count() == 0
	if should_be_vulnerable == is_vulnerable:
		return

	is_vulnerable = should_be_vulnerable
	if is_vulnerable:
		armor.visible = false
		core_hurtbox.monitorable = true
		core_visual.color = Color(1.0, 0.35, 0.3, 1.0)
		core_glow.color = Color(1.0, 0.58, 0.2, 0.55)
	else:
		armor.visible = true
		core_hurtbox.monitorable = false
		core_visual.color = Color(0.4, 0.85, 0.92, 1.0)
		core_glow.color = Color(0.4, 0.85, 1.0, 0.28)


func _apply_visuals() -> void:
	frame.polygon = PackedVector2Array([
		Vector2(-108.0, -126.0),
		Vector2(102.0, -126.0),
		Vector2(126.0, -82.0),
		Vector2(126.0, 82.0),
		Vector2(102.0, 126.0),
		Vector2(-108.0, 126.0),
		Vector2(-126.0, 82.0),
		Vector2(-126.0, -82.0),
	])
	armor.polygon = PackedVector2Array([
		Vector2(-36.0, -52.0),
		Vector2(40.0, -52.0),
		Vector2(58.0, 0.0),
		Vector2(40.0, 52.0),
		Vector2(-36.0, 52.0),
		Vector2(-56.0, 0.0),
	])
	core_visual.polygon = PackedVector2Array([
		Vector2(-24.0, -24.0),
		Vector2(24.0, -24.0),
		Vector2(24.0, 24.0),
		Vector2(-24.0, 24.0),
	])
	core_glow.polygon = PackedVector2Array([
		Vector2(0.0, -38.0),
		Vector2(38.0, 0.0),
		Vector2(0.0, 38.0),
		Vector2(-38.0, 0.0),
	])

	var core_rect := RectangleShape2D.new()
	core_rect.size = Vector2(48.0, 48.0)
	core_shape.shape = core_rect


func _flash_damage() -> void:
	frame.modulate = Color(1.0, 0.78, 0.78, 1.0)
	core_visual.modulate = Color(1.0, 0.92, 0.92, 1.0)
	var tween := create_tween()
	tween.tween_property(frame, "modulate", Color.WHITE, 0.18)
	tween.parallel().tween_property(core_visual, "modulate", Color.WHITE, 0.18)


func _flash_blocked_hit() -> void:
	armor.modulate = Color(1.0, 1.0, 0.65, 1.0)
	var tween := create_tween()
	tween.tween_property(armor, "modulate", Color.WHITE, 0.14)


func _on_died() -> void:
	defeated.emit()
	queue_free()

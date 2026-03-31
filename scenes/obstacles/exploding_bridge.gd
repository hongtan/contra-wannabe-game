extends Node2D

const Globals = preload("res://scripts/core/globals.gd")

@export var bridge_size := Vector2(176.0, 18.0)
@export var trigger_size := Vector2(176.0, 44.0)
@export var trigger_delay := 0.5
@export var reset_time := 0.0

var activated := false
var player_on_bridge := false

@onready var bridge_body: StaticBody2D = $BridgeBody
@onready var collision_shape: CollisionShape2D = $BridgeBody/CollisionShape2D
@onready var trigger_area: Area2D = $TriggerArea
@onready var trigger_shape: CollisionShape2D = $TriggerArea/CollisionShape2D
@onready var deck: Polygon2D = $Deck
@onready var flash: Polygon2D = $Flash


func _ready() -> void:
	_apply_geometry()
	trigger_area.body_entered.connect(_on_trigger_area_body_entered)
	trigger_area.body_exited.connect(_on_trigger_area_body_exited)
	flash.visible = false


func _apply_geometry() -> void:
	var bridge_rect := RectangleShape2D.new()
	bridge_rect.size = bridge_size
	collision_shape.shape = bridge_rect
	collision_shape.position = Vector2.ZERO

	var trigger_rect := RectangleShape2D.new()
	trigger_rect.size = trigger_size
	trigger_shape.shape = trigger_rect
	trigger_shape.position = Vector2.ZERO

	var polygon := PackedVector2Array([
		Vector2(-bridge_size.x * 0.5, -bridge_size.y * 0.5),
		Vector2(bridge_size.x * 0.5, -bridge_size.y * 0.5),
		Vector2(bridge_size.x * 0.5, bridge_size.y * 0.5),
		Vector2(-bridge_size.x * 0.5, bridge_size.y * 0.5),
	])
	deck.polygon = polygon
	flash.polygon = polygon


func _on_trigger_area_body_entered(body: Node) -> void:
	if activated:
		return
	if not body.is_in_group(Globals.PLAYER_GROUP):
		return

	player_on_bridge = true
	flash.visible = true
	await get_tree().create_timer(trigger_delay).timeout

	if activated or not player_on_bridge:
		flash.visible = false
		deck.modulate = Color.WHITE
		return

	activated = true
	trigger_area.monitoring = false

	var tween := create_tween()
	tween.tween_property(deck, "modulate", Color(1.0, 0.55, 0.25, 1.0), trigger_delay * 0.6)
	tween.parallel().tween_property(flash, "modulate", Color(1.0, 0.9, 0.3, 0.9), trigger_delay * 0.6)
	await tween.finished

	collision_shape.disabled = true
	deck.visible = false
	flash.visible = false
	player_on_bridge = false

	if reset_time > 0.0:
		await get_tree().create_timer(reset_time).timeout
		collision_shape.disabled = false
		deck.visible = true
		deck.modulate = Color.WHITE
		trigger_area.monitoring = true
		activated = false


func _on_trigger_area_body_exited(body: Node) -> void:
	if not body.is_in_group(Globals.PLAYER_GROUP):
		return

	player_on_bridge = false
	if not activated:
		flash.visible = false
		deck.modulate = Color.WHITE

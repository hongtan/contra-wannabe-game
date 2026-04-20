extends Node2D

const SKY_SCROLL := 0.18
const JUNGLE_SCROLL := 0.45

@onready var parallax_sky: Node2D = $ParallaxSky
@onready var parallax_jungle: Node2D = $ParallaxJungle

var sky_base_position := Vector2.ZERO
var jungle_base_position := Vector2.ZERO
var parallax_anchor_x := 0.0
var anchor_initialized := false


func _ready() -> void:
	sky_base_position = parallax_sky.position
	jungle_base_position = parallax_jungle.position
	_update_parallax()


func _process(_delta: float) -> void:
	_update_parallax()


func _update_parallax() -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return

	if not anchor_initialized:
		parallax_anchor_x = camera.global_position.x
		anchor_initialized = true

	var camera_offset_x := camera.global_position.x - parallax_anchor_x
	parallax_sky.position.x = sky_base_position.x + camera_offset_x * (1.0 - SKY_SCROLL)
	parallax_jungle.position.x = jungle_base_position.x + camera_offset_x * (1.0 - JUNGLE_SCROLL)

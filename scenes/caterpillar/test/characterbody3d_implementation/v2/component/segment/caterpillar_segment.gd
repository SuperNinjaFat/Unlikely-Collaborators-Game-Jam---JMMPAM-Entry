extends CharacterBody3D

@onready var grab_surface_detector: Area3D = $GrabSurfaceDetector

var _id: int = -1

signal picked(id: int)

func _ready() -> void:
	set_as_top_level(true)

func initialize(id: int) -> void:
	_id = id

@warning_ignore("unused_parameter")
func _input_event(camera: Camera3D, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if not event.is_action_pressed("left_click"): return
	picked.emit(_id)

func grab_surface_detected() -> bool:
	return grab_surface_detector.get_overlapping_areas().size() > 0

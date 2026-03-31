extends RigidBody3D

signal released

var _selected: bool = false

func _input(event: InputEvent) -> void:
	if not event.is_action_released("left_click"): return
	if not _selected: return
	_selected = false
	released.emit()

@warning_ignore("unused_parameter")
func _input_event(camera: Camera3D, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if not event.is_action_pressed("left_click"): return
	_selected = true

extends RigidBody3D

signal picked(self_reference: RigidBody3D)

func _ready() -> void:
	set_as_top_level(true)

@warning_ignore("unused_parameter")
func _input_event(camera: Camera3D, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if not event.is_action_pressed("left_click"): return
	picked.emit(self)

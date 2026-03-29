extends RigidBody3D

@onready var world_pin: PinJoint3D = $WorldPin

var _id: int = -1

signal selected(id: int)

func _ready() -> void:
	set_as_top_level(true)

func initialize(id: int) -> void:
	_id = id

@warning_ignore("unused_parameter")
func _input_event(camera: Camera3D, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if not event.is_action_pressed("left_click"): return
	selected.emit(_id)

func pin_to_world(pin: bool) -> void:
	if pin: world_pin.node_a = get_path()
	else: world_pin.node_a = NodePath("")

func is_pinned_to_world() -> bool:
	return world_pin.node_a != NodePath("")

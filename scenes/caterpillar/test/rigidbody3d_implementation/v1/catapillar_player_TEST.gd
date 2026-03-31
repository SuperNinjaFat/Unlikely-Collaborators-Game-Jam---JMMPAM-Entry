extends RigidBody3D

const RIGID_BODY_DRAGGER_UID: String = "uid://o1mwnw5gf1yr"

@onready var front_segment: RigidBody3D = $FrontSegment
@onready var back_segment: RigidBody3D = $BackSegment

	### TEMP ###
var viewport: Viewport

func _ready() -> void:
	
	# TODO - most likely move to camera manager
	viewport = get_viewport()
	viewport.physics_object_picking = true
	
	front_segment.picked.connect(_on_segment_picked)
	back_segment.picked.connect(_on_segment_picked)

# TODO: Use for freezing instead of ".freeze"
const FROZEN_MASS = 1000

func _input_event(camera: Camera3D, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if not event.is_action_pressed("left_click"): return
	_on_segment_picked(self)

func _on_segment_picked(segment: RigidBody3D) -> void:
	var dragger: RigidBodyDragger3D = load(RIGID_BODY_DRAGGER_UID).instantiate()
	get_parent().add_child(dragger)
	dragger.global_position = segment.global_position
	dragger.initialize(segment)

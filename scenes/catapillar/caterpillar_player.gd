extends Node3D

const SEGMENT_MAX_DISTANCE_RAMP: float = 2.0
const SEGMENT_DRAG_DEADZONE: float = 0.25
const SEGMENT_MIN_TRAVEL_SPEED: float = 0.25
const SEGMENT_MAX_TRAVEL_SPEED: float = 12.0
const RIGID_BODY_DRAGGER_UID: String = "uid://o1mwnw5gf1yr"

@onready var segment_container: Node3D = $SegmentContainer

var _selectable_segments: Array[RigidBody3D] = []
var _selected_segment: int = -1
var _all_segments: Array[Node3D] = []

	### TEMP ###
var _viewport: Viewport
var _camera: Camera3D

func _ready() -> void:
	
	# TODO - most likely move to camera manager
	_viewport = get_viewport()
	_viewport.physics_object_picking = true
	_camera = _viewport.get_camera_3d()
	
	_selectable_segments = [
		$SegmentContainer/FrontCaterpillarSegment,
		$SegmentContainer/EndCaterpillarSegment
	]
	$SegmentContainer/FrontCaterpillarSegment.initialize(0)
	$SegmentContainer/FrontCaterpillarSegment.selected.connect(_on_segment_selected)
	$SegmentContainer/MidCaterpillarSegment.initialize(1)
	$SegmentContainer/EndCaterpillarSegment.initialize(2)
	$SegmentContainer/EndCaterpillarSegment.selected.connect(_on_segment_selected)
	
	for segment: Node3D in segment_container.get_children():
		_all_segments.append(segment)

func _on_segment_selected(segment_id: int) -> void:
	_selected_segment = segment_id
	var dragger: RigidBodyDragger3D = load(RIGID_BODY_DRAGGER_UID).instantiate()
	get_parent().add_child(dragger)
	dragger.global_position = _selectable_segments[_selected_segment].global_position
	dragger.initialize(_selectable_segments[_selected_segment])

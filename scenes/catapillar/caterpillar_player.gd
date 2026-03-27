extends CharacterBody3D

const SEGMENT_MAX_DISTANCE_RAMP: float = 2.0
const SEGMENT_DRAG_DEADZONE: float = 0.25
const SEGMENT_MIN_TRAVEL_SPEED: float = 0.25
const SEGMENT_MAX_TRAVEL_SPEED: float = 12.0

@onready var segment_container: Node3D = $SegmentContainer
@onready var mouse_marker: MeshInstance3D = $MouseMarker

var _all_segments: Array[Node3D] = []
var _selectable_segments: Array[CharacterBody3D] = []
var _selected_segment: int = -1
var _segment_length: float = 0.0
var _max_body_length: float = 0.0 # constrains click/drag movement

	### TEMP ###
var _viewport: Viewport
var _camera: Camera3D

func _ready() -> void:
	
	_segment_length = global_position.distance_to(segment_container.get_child(0).global_position)
	_max_body_length = global_position.distance_to($SegmentContainer/EndPickableSegment.global_position)
	
	# TODO - most likely move to camera manager
	_viewport = get_viewport()
	_viewport.physics_object_picking = true
	_camera = _viewport.get_camera_3d()
	
	# TEMP - pending more permanent body scene structure
	_selectable_segments = [
		self,
		$SegmentContainer/MidPickableSegment,
		$SegmentContainer/EndPickableSegment
	]
	$SegmentContainer/MidPickableSegment.initialize(1)
	$SegmentContainer/EndPickableSegment.initialize(2)
	$SegmentContainer/EndPickableSegment.picked.connect(_on_segment_picked)
	
	_all_segments.append(self)
	for segment: Node3D in segment_container.get_children():
		_all_segments.append(segment)
		segment.set_as_top_level(true)

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void:
	if _selected_segment == -1: return
	
	# move selected segment toward mouse
	var projected_global_position: Vector3 = _get_projected_mouse_position()
	var opposite_end_segment_position: Vector3 = (
		_selectable_segments[0].global_position if _selected_segment != 0 else _selectable_segments[2].global_position
	)
	var max_travel_position: Vector3 = opposite_end_segment_position + \
		opposite_end_segment_position.direction_to(projected_global_position) * _max_body_length
	var min_travel_position: Vector3 = opposite_end_segment_position + \
		opposite_end_segment_position.direction_to(projected_global_position) * (_max_body_length / 3.0)
	
	var travel_target: Vector3 = projected_global_position
	if opposite_end_segment_position.distance_to(travel_target) > _max_body_length:
		travel_target = max_travel_position
	elif opposite_end_segment_position.distance_to(travel_target) < (_max_body_length / 3.0):
		travel_target = min_travel_position
	
	mouse_marker.global_position = travel_target
	
	var segment_velocity: Vector3 = Vector3.ZERO
	if _selectable_segments[_selected_segment].global_position.distance_to(travel_target) >= 0.25:
		var segment_distance_to_mouse: float = _selectable_segments[_selected_segment].global_position.distance_to(travel_target)
		var distance_ratio: float = clamp(
			segment_distance_to_mouse / SEGMENT_MAX_DISTANCE_RAMP, 
			0.0, 1.0
		)
		var travel_direction: Vector3 = _selectable_segments[_selected_segment].global_position.direction_to(travel_target)
		var speed: float = lerp(SEGMENT_MIN_TRAVEL_SPEED, SEGMENT_MAX_TRAVEL_SPEED, distance_ratio)
		segment_velocity = (
			travel_direction * speed
		)
	
	_selectable_segments[_selected_segment].set_velocity(segment_velocity)
	_selectable_segments[_selected_segment].move_and_slide()
	
	_update_segment_positions(delta)
	_update_segment_rotations(delta)
	
	if Input.is_action_just_released("left_click"): _selected_segment = -1

func _update_segment_positions(delta: float) -> void:
	
	# forward pass
	if _selected_segment == 0:
		
		for i: int in range(1, _all_segments.size() - 1):
			
			var previous: Node3D = _all_segments[i - 1]
			var current: Node3D = _all_segments[i]
			var next: Node3D = _all_segments[i + 1]
			
			# 1. get absolute target
			# 2. get constrained target relative to next segment and some max distance
			# 3. if distance from next to absolute target is greater than max distance, move target is direction to absolute target * max distance
			# 4. else move target is absolute target
			
			var absolute_target_direction: Vector3 = previous.global_position.direction_to(current.global_position)
			var absolute_target: Vector3 = previous.global_position + absolute_target_direction * _segment_length
			var constrained_target_direction: Vector3 = next.global_position.direction_to(absolute_target)
			var constrained_target: Vector3 = next.global_position + (constrained_target_direction * (_segment_length * 1.5))
			var move_target: Vector3 = absolute_target
			if next.global_position.distance_to(absolute_target) >= (_segment_length * 1.5):
				move_target = constrained_target
			
			current.global_position = lerp(
				current.global_position,
				move_target, 
				delta * 64.0
			)
		return
	
	# backward pass
	for i: int in range(_all_segments.size() - 2, 1, -1):
		
		var next: Node3D = _all_segments[i + 1]
		var current: Node3D = _all_segments[i]
		var previous: Node3D = _all_segments[i - 1]
		
		var absolute_target_direction: Vector3 = next.global_position.direction_to(current.global_position)
		var absolute_target: Vector3 = next.global_position + absolute_target_direction * _segment_length
		var constrained_target_direction: Vector3 = previous.global_position.direction_to(absolute_target)
		var constrained_target: Vector3 = previous.global_position + (constrained_target_direction * (_segment_length * 1.5))
		var move_target: Vector3 = absolute_target
		if previous.global_position.distance_to(absolute_target) >= (_segment_length * 1.5):
			move_target = constrained_target
		
		current.global_position = lerp(
			current.global_position,
			move_target, 
			delta * 64.0
		)

@warning_ignore("unused_parameter")
func _update_segment_rotations(delta: float) -> void:
	for i: int in range(_all_segments.size() - 1):
		var current: Node3D = _all_segments[i]
		var next: Node3D = _all_segments[i + 1]
		
		# TODO - interpolate rotations
		current.look_at(next.global_position, Vector3.UP)

@warning_ignore("unused_parameter")
func _input_event(camera: Camera3D, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if not event.is_action_pressed("left_click"): return
	_on_segment_picked(0)

func _on_segment_picked(segment_id: int) -> void:
	segment_id = clamp(segment_id, 0, _selectable_segments.size() - 1)
	_selected_segment = segment_id

func _get_projected_mouse_position() -> Vector3:
	var mouse_position: Vector2 = _viewport.get_mouse_position()
	# this "locks" projected coordinates to the caterpillar's z-coordinate
	var distance_to_camera: float = _camera.global_position.distance_to(global_position) 
	var world_coordinate_projection: Vector3 = (
		_camera.project_ray_normal(mouse_position) * distance_to_camera + _camera.project_ray_origin(mouse_position)
	) 
	# never change z coordinate
	world_coordinate_projection.z = global_position.z
	return world_coordinate_projection

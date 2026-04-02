extends CharacterBody3D

const SEGMENT_MAX_DISTANCE_RAMP: float = 2.0
const SEGMENT_DRAG_DEADZONE: float = 0.25

@onready var segments: Node3D = $Segments

var _segments: Array[CharacterBody3D] = []
var _selected_segment: int = -1
var _segment_length: float = 1.1

	### TEMP ###
var _viewport: Viewport
var _camera: Camera3D

func _ready() -> void:
	
	# TODO - most likely move to camera manager
	_viewport = get_viewport()
	_viewport.physics_object_picking = true
	_camera = _viewport.get_camera_3d()
	
	_segments.append(self)
	var segment_id: int = 0
	for segment: CharacterBody3D in segments.get_children():
		segment_id += 1
		segment.initialize(segment_id)
		segment.picked.connect(_on_segment_picked)
		_segments.append(segment)

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void:
	if _selected_segment == -1: return
	
	var projected_global_position: Vector3 = _get_projected_mouse_position()
	var segment_velocity: Vector3 = Vector3.ZERO
	if _segments[_selected_segment].global_position.distance_to(projected_global_position) >= 0.25:
		var segment_distance_to_mouse: float = _segments[_selected_segment].global_position.distance_to(projected_global_position)
		var distance_ratio: float = clamp(
			segment_distance_to_mouse / SEGMENT_MAX_DISTANCE_RAMP, 
			0.0, 1.0
		)
		var velocity_modifier: float = lerp(0.25, 16.0, distance_ratio)
		segment_velocity = (
			_segments[_selected_segment].global_position.direction_to(projected_global_position) * velocity_modifier
		)
	
	_segments[_selected_segment].set_velocity(segment_velocity)
	_segments[_selected_segment].move_and_slide()
	
	_update_segment_positions()
	_update_segment_rotations()
	
	if Input.is_action_just_released("left_click"): _selected_segment = -1

func _update_segment_positions() -> void:
	
	# forward pass
	for i: int in range(_selected_segment + 1, _segments.size()):
		var previous: CharacterBody3D = _segments[i - 1]
		var current: CharacterBody3D = _segments[i]
		
		var direction: Vector3 = (current.global_position - previous.global_position).normalized()
		current.global_position = previous.global_position + direction * _segment_length
	
	# backward pass
	for i: int in range(_selected_segment - 1, -1, -1):
		var next: CharacterBody3D = _segments[i + 1]
		var current: CharacterBody3D = _segments[i]
		
		var direction: Vector3 = (current.global_position - next.global_position).normalized()
		current.global_position = next.global_position + direction * _segment_length

func _update_segment_rotations() -> void:
	for i: int in range(_segments.size() - 1):
		var current: CharacterBody3D = _segments[i]
		var next: CharacterBody3D = _segments[i + 1]
		
		current.look_at(next.global_position, Vector3.UP)

@warning_ignore("unused_parameter")
func _input_event(camera: Camera3D, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if not event.is_action_pressed("left_click"): return
	_on_segment_picked(0)

func _on_segment_picked(segment_id: int) -> void:
	segment_id = clamp(segment_id, 0, _segments.size() - 1)
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

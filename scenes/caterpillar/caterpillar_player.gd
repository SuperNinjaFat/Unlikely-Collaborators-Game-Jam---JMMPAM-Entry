extends Node3D

const MIN_LAUNCH_STRENGTH: float = 200.0
const MAX_LAUNCH_STRENGTH: float = 1200.0

@onready var front_caterpillar_end_segment: CaterpillarBodyEndSegment = $PhysicsSegmentsContainer/FrontCaterpillarEndSegment
@onready var caterpillar_middle_segment: RigidBody3D = $PhysicsSegmentsContainer/CaterpillarMiddleSegment
@onready var end_caterpillar_end_segment: CaterpillarBodyEndSegment = $PhysicsSegmentsContainer/EndCaterpillarEndSegment
@onready var physics_segments_container: Node3D = $PhysicsSegmentsContainer
@onready var visual_segments_container: Node3D = $VisualSegmentsContainer

	### TEMP ###
var _viewport: Viewport
var _camera: Camera3D

# Dictionary of Node3D[Transform3D]
#var _visual_segments: Dictionary = {}
var _visual_segments_0: Array[Node3D] = []
var _visual_segments_1: Array[Node3D] = []
var _physics_segment_spacing: float = 0.0
var _visual_segment_spacing: float = 0.0

signal drag_released

func _ready() -> void:
	
	# TODO - most likely move to camera manager
	_viewport = get_viewport()
	_viewport.physics_object_picking = true
	_camera = _viewport.get_camera_3d()
	
	_physics_segment_spacing = (
		caterpillar_middle_segment.global_position - front_caterpillar_end_segment.global_position
	).length() 
	_visual_segment_spacing = _physics_segment_spacing / (float(visual_segments_container.get_child_count()) / 2.0)
	
	# Physics segment dependency injection
	front_caterpillar_end_segment.callbacks = {"get_mouse_position": _get_projected_mouse_position}
	front_caterpillar_end_segment.pinned_to_world.connect(_on_segment_pinned_to_world)
	caterpillar_middle_segment.released.connect(_on_middle_segment_released)
	end_caterpillar_end_segment.callbacks = {"get_mouse_position": _get_projected_mouse_position}
	end_caterpillar_end_segment.pinned_to_world.connect(_on_segment_pinned_to_world)
	
	# Initialize visual segments
	for i: int in range(visual_segments_container.get_child_count()):
		var segment: Node3D = visual_segments_container.get_child(i)
		@warning_ignore("integer_division")
		if i < visual_segments_container.get_child_count()/2: _visual_segments_0.append(segment)
		else: _visual_segments_1.append(segment)
		segment.set_as_top_level(true)

func _physics_process(delta: float) -> void:
	
	# Update segments between head and middle
	_update_visual_segments(
		front_caterpillar_end_segment, 
		caterpillar_middle_segment, 
		_visual_segments_0, 
		delta
	)
	
	# Update segments between middle and tail
	_update_visual_segments(
		caterpillar_middle_segment, 
		end_caterpillar_end_segment, 
		_visual_segments_1,
		delta
	)

func _update_visual_segments(start_physics_segment: RigidBody3D, end_physics_segment: RigidBody3D, visual_segments: Array[Node3D], _delta: float) -> void:
	
	var total_offset: Vector3 = end_physics_segment.global_position - start_physics_segment.global_position
	var direction: Vector3 = total_offset / _physics_segment_spacing
	
	for i: int in range(visual_segments.size()):
		
		var segment: Node3D = visual_segments[i]
		var distance_along: float = _visual_segment_spacing * float(i + 1)
		var target_position: Vector3 = start_physics_segment.global_position + direction * distance_along
		
		segment.global_position = target_position
		segment.look_at(start_physics_segment.global_position)

# TODO - cache state of all physical and visual nodes in caterpillar body
# store in a dictionary or something
# this will be used to restore from failure states
func _save_body_configuration() -> void:
	pass

# TODO - related to above
func _restore_body_configuration() -> void:
	pass

func engage_grip() -> void:
	front_caterpillar_end_segment.pin_to_world(true)
	end_caterpillar_end_segment.pin_to_world(true)

func _on_segment_pinned_to_world() -> void:
	if not front_caterpillar_end_segment.is_pinned_to_world() or \
	not end_caterpillar_end_segment.is_pinned_to_world(): return
	_save_body_configuration()
	drag_released.emit()

func _on_middle_segment_released() -> void:
	front_caterpillar_end_segment.disable_world_pin()
	end_caterpillar_end_segment.disable_world_pin()
	
	var launch_direction: Vector3 = _get_launch_direction()
	var launch_strength: float = _get_launch_strength()
	
	front_caterpillar_end_segment.apply_central_force(launch_direction * (launch_strength * 0.75))
	caterpillar_middle_segment.apply_central_force(launch_direction * launch_strength)
	end_caterpillar_end_segment.apply_central_force(launch_direction * (launch_strength * 0.75))

func _get_launch_direction() -> Vector3:
	var body_axis: Vector3 = front_caterpillar_end_segment.global_position - end_caterpillar_end_segment.global_position
	var perpendicular_vector: Vector3 = Vector3(-body_axis.y, body_axis.x, 0.0).normalized()
	var center: Vector3 = (front_caterpillar_end_segment.global_position + end_caterpillar_end_segment.global_position) * 0.5
	var avoid_direction: Vector3 = center - _get_projected_mouse_position()
	if perpendicular_vector.dot(avoid_direction.normalized()) < 0.0:
		perpendicular_vector = -perpendicular_vector
	return perpendicular_vector

func _get_launch_strength() -> float:
	var center: Vector3 = (front_caterpillar_end_segment.global_position + end_caterpillar_end_segment.global_position) * 0.5
	var drag_distance: float = (_get_projected_mouse_position() - center).length()
	var drag_distance_modifier: float = clamp(drag_distance / 2.0, 0.0, 1.0)
	return lerp(MIN_LAUNCH_STRENGTH, MAX_LAUNCH_STRENGTH, drag_distance_modifier)

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

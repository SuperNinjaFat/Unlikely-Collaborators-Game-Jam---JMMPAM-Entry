extends Node3D

const SEGMENT_MAX_DISTANCE_RAMP: float = 2.0
const SEGMENT_DRAG_DEADZONE: float = 0.1
const SEGMENT_MIN_TRAVEL_SPEED: float = 0.25
const SEGMENT_MAX_TRAVEL_SPEED: float = 16.0

@onready var physics_segments_container: Node3D = $PhysicsSegmentsContainer
@onready var visual_segments_container: Node3D = $VisualSegmentsContainer

#var _all_segments: Array[Node3D] = []

	### TEMP ###
#var _viewport: Viewport
#var _camera: Camera3D

func _ready() -> void:
	return
	
	## TODO - most likely move to camera manager
	#_viewport = get_viewport()
	#_viewport.physics_object_picking = true
	#_camera = _viewport.get_camera_3d()
	
	#for segment: Node3D in segment_container.get_children():
		#_all_segments.append(segment)

#func _input(event: InputEvent) -> void:
	#if event.is_action_released("left_click"):
		#_selected_segment = -1
	#if event.is_action_pressed("right_click") and _selected_segment != -1:
		#var selected_segment: RigidBody3D = _selectable_segments[_selected_segment]
		#selected_segment.pin_to_world(!selected_segment.is_pinned_to_world())

func _physics_process(_delta: float) -> void:
	return
	#if _selected_segment == -1: return
	#
	#var selected_segment: RigidBody3D = _selectable_segments[_selected_segment]
	#
	#var move_target: Vector3 = _get_projected_mouse_position()
	#var direction: Vector3 = move_target - selected_segment.global_transform.origin
	#var distance = direction.length()
	#
	#if distance > SEGMENT_DRAG_DEADZONE:
		#var speed_modifier: float = clamp(
			#distance / SEGMENT_MAX_DISTANCE_RAMP,
			#0.0, 1.0
		#)
		#var speed: float = lerp(SEGMENT_MIN_TRAVEL_SPEED, SEGMENT_MAX_TRAVEL_SPEED, speed_modifier)
		#selected_segment.linear_velocity = direction.normalized() * speed
	#else:
		#selected_segment.linear_velocity = Vector3.ZERO

#func _on_segment_selected(segment_id: int) -> void:
	#_selected_segment = segment_id
	#_selectable_segments[_selected_segment].pin_to_world(false)

#func _get_projected_mouse_position() -> Vector3:
	#var mouse_position: Vector2 = _viewport.get_mouse_position()
	## this "locks" projected coordinates to the caterpillar's z-coordinate
	#var distance_to_camera: float = _camera.global_position.distance_to(global_position) 
	#var world_coordinate_projection: Vector3 = (
		#_camera.project_ray_normal(mouse_position) * distance_to_camera + _camera.project_ray_origin(mouse_position)
	#) 
	## never change z coordinate
	#world_coordinate_projection.z = global_position.z
	#return world_coordinate_projection

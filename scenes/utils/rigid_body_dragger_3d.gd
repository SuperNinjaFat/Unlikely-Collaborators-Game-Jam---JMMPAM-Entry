extends CharacterBody3D
class_name RigidBodyDragger3D

const MAX_DISTANCE_RAMP: float = 2.0
const DRAG_DEADZONE: float = 0.25
const MIN_TRAVEL_SPEED: float = 0.25
const MAX_TRAVEL_SPEED: float = 12.0

@onready var pin_joint_3d: PinJoint3D = $PinJoint3D

var _viewport: Viewport
var _camera: Camera3D
var _rigid_body: RigidBody3D

func initialize(rigid_body: RigidBody3D) -> void:
	_viewport = get_viewport()
	_viewport.physics_object_picking = true
	_camera = _viewport.get_camera_3d()
	_rigid_body = rigid_body
	await get_tree().physics_frame
	pin_joint_3d.node_b = _rigid_body.get_path()

func _physics_process(_delta: float) -> void:
	
	velocity = Vector3.ZERO
	
	var travel_target: Vector3 = _get_projected_mouse_position()
	
	if global_position.distance_to(travel_target) >= DRAG_DEADZONE:
		var segment_distance_to_mouse: float = global_position.distance_to(travel_target)
		var distance_ratio: float = clamp(
			segment_distance_to_mouse / MAX_DISTANCE_RAMP, 
			0.0, 1.0
		)
		var travel_direction: Vector3 = global_position.direction_to(travel_target)
		var speed: float = lerp(MIN_TRAVEL_SPEED,MAX_TRAVEL_SPEED, distance_ratio)
		velocity = (
			travel_direction * speed
		)
	
	move_and_slide()
	
	if Input.is_action_just_released("left_click"): queue_free()

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

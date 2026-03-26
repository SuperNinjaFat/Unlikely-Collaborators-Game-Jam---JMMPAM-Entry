extends CharacterBody3D
class_name RigidBodyDragger3D

@onready var pin_joint_3d: PinJoint3D = $PinJoint3D

var _viewport: Viewport
var _camera: Camera3D
var _rigid_body: RigidBody3D

func initialize(rigid_body: RigidBody3D) -> void:
	_viewport = get_viewport()
	_viewport.physics_object_picking = true
	_camera = _viewport.get_camera_3d()
	_rigid_body = rigid_body
	pin_joint_3d.node_b = _rigid_body.get_path()

func _physics_process(_delta: float) -> void:
	var mouse_position: Vector2 = _viewport.get_mouse_position()
	# this "locks" projected coordinates to the caterpillar's z-coordinate
	var distance_to_camera: float = _camera.global_position.distance_to(global_position) 
	var world_coordinate_projection: Vector3 = (
		_camera.project_ray_normal(mouse_position) * distance_to_camera + _camera.project_ray_origin(mouse_position)
	) 
	global_position.x = world_coordinate_projection.x
	global_position.y = world_coordinate_projection.y
	
	if Input.is_action_just_released("left_click"): queue_free()

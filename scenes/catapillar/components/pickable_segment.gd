extends RigidBody3D
class_name PickableSegment

var _viewport: Viewport
var _camera: Camera3D

func initialize(viewport: Viewport, camera: Camera3D) -> void:
	_viewport = viewport
	_camera = camera
	set_as_top_level(true)

func _physics_process(_delta: float) -> void:
	if not freeze: return
	
	var mouse_position: Vector2 = _viewport.get_mouse_position()
	# this "locks" projected coordinates to the caterpillar's z-coordinate
	var distance_to_camera: float = _camera.global_position.distance_to(global_position) 
	var world_coordinate_projection: Vector3 = (
		_camera.project_ray_normal(mouse_position) * distance_to_camera + _camera.project_ray_origin(mouse_position)
	) 
	global_position.x = world_coordinate_projection.x
	global_position.y = world_coordinate_projection.y
	
	freeze = !Input.is_action_just_released("left_click")

@warning_ignore("unused_parameter")
func _input_event(camera: Camera3D, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if freeze: return
	if not event.is_action_pressed("left_click"): return
	freeze = true

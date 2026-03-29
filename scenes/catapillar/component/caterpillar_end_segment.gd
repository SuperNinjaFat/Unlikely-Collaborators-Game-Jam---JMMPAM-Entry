extends RigidBody3D

const SEGMENT_MAX_DISTANCE_RAMP: float = 2.0
const SEGMENT_DRAG_DEADZONE: float = 0.1
const SEGMENT_MIN_TRAVEL_SPEED: float = 0.25
const SEGMENT_MAX_TRAVEL_SPEED: float = 16.0

@onready var world_pin: PinJoint3D = $WorldPin
@onready var floor_check: RayCast3D = $FloorCheck
@onready var grab_surface_detection: Area3D = $GrabSurfaceDetection

var _selected: bool = false # redundant bool could be replaced with is_pinned_to_world() (maybe)

	### TEMP ###
var _viewport: Viewport
var _camera: Camera3D

func _ready() -> void:
	
	# TODO - most likely move to camera manager
	_viewport = get_viewport()
	_viewport.physics_object_picking = true
	_camera = _viewport.get_camera_3d()
	
	set_as_top_level(true)

func _input(event: InputEvent) -> void:
	if event.is_action_released("left_click"): 
		_selected = false
		#pin_to_world(true)

@warning_ignore("unused_parameter")
func _input_event(camera: Camera3D, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if not event.is_action_pressed("left_click"): return
	if not is_pinned_to_world(): return
	pin_to_world(false)
	_selected = true

func _physics_process(_delta: float) -> void:
	
	floor_check.target_position = to_local(
		global_position + Vector3(0.0, -.5001, 0.0)
	)
	
	# if selected, reach toward the mouse
	if _selected: 
		
		var move_target: Vector3 = _get_projected_mouse_position()
		var direction: Vector3 = move_target - global_transform.origin
		var distance = direction.length()
		
		if distance > SEGMENT_DRAG_DEADZONE:
			var speed_modifier: float = clamp(
				distance / SEGMENT_MAX_DISTANCE_RAMP,
				0.0, 1.0
			)
			var speed: float = lerp(SEGMENT_MIN_TRAVEL_SPEED, SEGMENT_MAX_TRAVEL_SPEED, speed_modifier)
			linear_velocity = direction.normalized() * speed
		else:
			linear_velocity = Vector3.ZERO
			
	# if not selected, pin to world once the segments lands on the ground or enters a grab surface
	elif floor_check.is_colliding() or grab_surface_detection.get_overlapping_areas().size() > 0: 
		pin_to_world(true)



func pin_to_world(pin: bool) -> void:
	if pin: world_pin.node_a = get_path()
	else: world_pin.node_a = NodePath("")

func is_pinned_to_world() -> bool:
	return world_pin.node_a != NodePath("")

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

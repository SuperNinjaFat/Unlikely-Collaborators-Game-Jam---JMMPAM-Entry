extends RigidBody3D

@onready var front_segment: PickableSegment = $FrontSegment
@onready var back_segment: PickableSegment = $BackSegment

	### TEMP ###
var viewport: Viewport
var camera: Camera3D

func _ready() -> void:
	
	# TODO - most likely move to camera manager
	viewport = get_viewport()
	viewport.physics_object_picking = true
	camera = viewport.get_camera_3d()
	
	front_segment.initialize(viewport, camera)
	back_segment.initialize(viewport, camera)

# TODO: Use for freezing instead of ".freeze"
const FROZEN_MASS = 1000

func _physics_process(_delta: float) -> void:
	if not freeze: return
	
	var mouse_position: Vector2 = viewport.get_mouse_position()
	# this "locks" projected coordinates to the caterpillar's z-coordinate
	var distance_to_camera: float = camera.global_position.distance_to(global_position) 
	var world_coordinate_projection: Vector3 = (
		camera.project_ray_normal(mouse_position) * distance_to_camera + camera.project_ray_origin(mouse_position)
	) 
	global_position.x = world_coordinate_projection.x
	global_position.y = world_coordinate_projection.y
	
	freeze = !Input.is_action_just_released("left_click")

func _input_event(camera: Camera3D, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if freeze: return
	if not event.is_action_pressed("left_click"): return
	freeze = true

extends RigidBody3D
class_name CaterpillarBodyEndSegment

const SEGMENT_MAX_DISTANCE_RAMP: float = 2.0
const SEGMENT_DRAG_DEADZONE: float = 0.1
const SEGMENT_MIN_TRAVEL_SPEED: float = 0.25
const SEGMENT_MAX_TRAVEL_SPEED: float = 16.0

@export var opposite_segment: CaterpillarBodyEndSegment

@onready var world_pin: PinJoint3D = $WorldPin
@onready var floor_check: RayCast3D = $FloorCheck
@onready var grab_surface_detection: Area3D = $GrabSurfaceDetection

var _selected: bool = false # redundant bool could be replaced with is_pinned_to_world() (maybe)

# TODO - standardize this into a special Resource subclass if there is a need
var callbacks: Dictionary = {}

signal pinned_to_world

func _ready() -> void:
	
	if not opposite_segment:
		printerr("CaterpillarBodyEndSegment @ _ready(): No opposite segment provided. This scene will not funciton as intended.")
		return
	
	grab_surface_detection.area_entered.connect(_on_grab_surface_area_entered)
	
	set_as_top_level(true)

func _input(event: InputEvent) -> void:
	if event.is_action_released("left_click") and _selected: 
		_selected = false
		if grab_surface_detection.get_overlapping_areas().size() > 0:
			pin_to_world(true)
			pinned_to_world.emit()

@warning_ignore("unused_parameter")
func _input_event(camera: Camera3D, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	
	if event.is_action_pressed("left_click"): 
		# "selectable" conditions -- refer to the diagram
		if is_pinned_to_world() and not opposite_segment.is_pinned_to_world(): return
		elif not is_pinned_to_world() and not opposite_segment.is_pinned_to_world(): return
		
		pin_to_world(false)
		_selected = true
	
	elif event.is_action_released("left_click"):
		if is_pinned_to_world(): return
		elif grab_surface_detection.get_overlapping_areas().size() == 0: return
		
		pin_to_world(true)

func _physics_process(_delta: float) -> void:
	
	if is_pinned_to_world(): return
	
	floor_check.target_position = to_local(
		global_position + Vector3(0.0, -.5001, 0.0)
	)
	
	# if selected, reach toward the mouse
	if _selected: 
		
		var move_target: Vector3 = callbacks.get_mouse_position.call()
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
	elif floor_check.is_colliding():# or grab_surface_detection.get_overlapping_areas().size() > 0: 
		pin_to_world(true)

func pin_to_world(pin: bool) -> void:
	if pin: 
		world_pin.node_a = get_path()
		pinned_to_world.emit()
	else: world_pin.node_a = NodePath("")

func is_pinned_to_world() -> bool:
	return world_pin.node_a != NodePath("")

func disable_world_pin(disable_time: float = 0.25) -> void:
	pin_to_world(false)
	floor_check.enabled = false
	grab_surface_detection.monitoring = false
	await get_tree().create_timer(disable_time).timeout
	floor_check.enabled = true
	grab_surface_detection.monitoring = true

func _on_grab_surface_area_entered(_area: Area3D) -> void:
	return
	#if _selected: return
	#pin_to_world(true)

extends RigidBody3D
class_name CaterpillarBodyEndSegment

const SEGMENT_MAX_DISTANCE_RAMP: float = 2.0
const SEGMENT_DRAG_DEADZONE: float = 0.1
const SEGMENT_MIN_TRAVEL_SPEED: float = 0.25
const SEGMENT_MAX_TRAVEL_SPEED: float = 16.0
const SLIDE_BODY_UID: String = "uid://cqy7e7a8unm80"
const DEFAULT_COLOR: Color = Color("00ff00")
const UNPINNED_COLOR: Color = Color("007f00")

@export var opposite_segment: CaterpillarBodyEndSegment

@onready var body_mesh: MeshInstance3D = $BodyMesh
@onready var world_pin: PinJoint3D = $WorldPin
@onready var floor_checks: Node3D = $FloorChecks
@onready var grab_surface_detection: Area3D = $GrabSurfaceDetection
@onready var pin_particles: CPUParticles3D = $PinParticles
@onready var jump_particles: CPUParticles3D = $JumpParticles
@onready var selected_sound: AudioStreamPlayer = $SelectedSound
@onready var pinned_sound: AudioStreamPlayer = $PinnedSound

var _selected: bool = false 
 # true will still defer to all auxiliary selectability logic, but false will always prevent selection
var _selectable: bool = true
var _max_extension_length: float = 0.0
var _opposite_segment_sliding: bool = false
var _slide_body: CharacterBody3D

# TODO - standardize this into a special Resource subclass if there is a need
var callbacks: Dictionary = {}

signal pinned_to_world
signal game_end_reached

func _ready() -> void:
	if not opposite_segment:
		printerr("CaterpillarBodyEndSegment @ _ready(): No opposite segment provided. This scene will not funciton as intended.")
		return
	
	_max_extension_length = global_position.distance_to(opposite_segment.global_position)
	
	grab_surface_detection.area_exited.connect(_on_grab_surface_area_exited)
	
	set_as_top_level(true)
	floor_checks.set_as_top_level(true)
	jump_particles.set_as_top_level(true)

@warning_ignore("unused_parameter")
func _input_event(camera: Camera3D, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	
	if not _selectable: return
	
	if event.is_action_pressed("left_click"): 
		# "selectable" conditions -- refer to the diagram
		if is_pinned_to_world() and not opposite_segment.is_pinned_to_world(): return
		elif not is_pinned_to_world() and not opposite_segment.is_pinned_to_world(): return
		
		pin_to_world(false)
		_selected = true
		_opposite_segment_sliding = opposite_segment.is_sliding()
		
		selected_sound.play()
	
	elif event.is_action_released("left_click"):
		if is_pinned_to_world(): return
		# TODO - "can't find overlappying areas when monitoring is off" :/
		elif grab_surface_detection.get_overlapping_areas().size() == 0: return
		
		pin_to_world(true)

func _input(event: InputEvent) -> void:
	
	if not _selectable: return
	
	if event.is_action_released("left_click") and _selected: 
		_selected = false
		if grab_surface_detection.get_overlapping_areas().size() > 0:
			pin_to_world(true)

func _physics_process(_delta: float) -> void:
	# Force release from grab surface if sliding too far away
	if is_instance_valid(_slide_body) and world_pin.node_b != NodePath(""):
		if _slide_body.is_on_wall() or _slide_body.is_on_ceiling() or _slide_body.is_on_floor():
			pin_to_world(false)
			return
		var slide_body_distance: float = opposite_segment.global_position.distance_to(_slide_body.global_position)
		if slide_body_distance > _max_extension_length + 0.5:
			pin_to_world(false)
	
	if is_pinned_to_world(): return
	
	#floor_check.target_position = to_local(
		#global_position + Vector3(0.0, -.5001, 0.0)
	#)
	floor_checks.global_position = global_position
	
	# Behavior when dragged by mouse
	if _selected:
		# Force de-select if opposite segment slides off of a grab surface
		if _opposite_segment_sliding and not opposite_segment.is_sliding():
			_selected = false
			return
		
		# Reach towards projected drag position
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
			
	# If not selected, pin to world once the segments lands on the ground or enters a grab surface
	elif _is_on_floor():
		pin_to_world(true)

func pin_to_world(pin: bool) -> void:
	world_pin.node_a = NodePath("")
	world_pin.node_b = NodePath("")
	if is_instance_valid(_slide_body): _slide_body.queue_free()
	if pin:
		world_pin.node_a = get_path()
		pinned_to_world.emit()
		pinned_sound.play(0.01)
		#body_mesh.mesh.material.albedo_color = DEFAULT_COLOR
		pin_particles.set_emitting(true)
		if _is_on_floor(): return
		if grab_surface_detection.get_overlapping_areas().size() == 0: return # is this necessary?
		var grab_surface: Node3D = grab_surface_detection.get_overlapping_areas()[0]
		if grab_surface.game_end:
			game_end_reached.emit()
			return
		if grab_surface.slide_velocity == Vector2.ZERO: return
		_slide_body = load(SLIDE_BODY_UID).instantiate()
		add_child(_slide_body)
		_slide_body.global_position = global_position
		_slide_body.set_velocity(
			Vector3(
				grab_surface.slide_velocity.x,
				grab_surface.slide_velocity.y,
				0.0
			)
		)
		# account for bizarre physics lurch 
		await get_tree().physics_frame # :/
		await get_tree().physics_frame # :(
		if not is_instance_valid(_slide_body): return
		world_pin.node_b = _slide_body.get_path()
	#else: body_mesh.mesh.material.albedo_color = UNPINNED_COLOR

func is_pinned_to_world() -> bool:
	return world_pin.node_a != NodePath("")

func is_sliding() -> bool:
	return is_instance_valid(_slide_body)

func disable_world_pin(disable_time: float = 0.25) -> void:
	pin_to_world(false)
	_enable_floor_checks(false)
	grab_surface_detection.monitoring = false
	await get_tree().create_timer(disable_time).timeout
	_enable_floor_checks(true)
	grab_surface_detection.monitoring = true

func set_selectable(selectable: bool) -> void:
	_selectable = selectable

func emit_jump_particles(jump_direction: Vector3) -> void:
	jump_particles.global_position = global_position
	# TODO - make sure target and up vector are not colinear
	jump_particles.look_at(jump_particles.global_position + jump_direction)
	jump_particles.set_emitting(true)

func _is_on_floor() -> bool:
	return (
		$FloorChecks/DownFloorCheck.is_colliding()
		and (
			$FloorChecks/SecondaryFloorCheck0.is_colliding() or
			$FloorChecks/SecondaryFloorCheck1.is_colliding()
		)
	)

func _enable_floor_checks(enabled: bool) -> void:
	for ray: Node3D in floor_checks.get_children():
		ray.enabled = enabled

func _on_grab_surface_area_exited(_area: Area3D) -> void:
	if _selected: return
	# editor was yelling at me for not checking this occasionally
	if grab_surface_detection.monitoring:
		# if we just slid off a slide surface onto another grabbable surface
		if is_instance_valid(_slide_body) and grab_surface_detection.get_overlapping_areas().size() > 0:
			pin_to_world(true)
		else: pin_to_world(false)

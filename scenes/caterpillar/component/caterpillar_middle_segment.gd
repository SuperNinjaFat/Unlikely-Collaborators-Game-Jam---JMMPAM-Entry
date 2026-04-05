extends RigidBody3D

const MAX_DRAG_DISTANCE: float = 2.0

@export var front_segment: CaterpillarBodyEndSegment
@export var end_segment: CaterpillarBodyEndSegment
@onready var launch_indicator_pivot: Node3D = $LaunchIndicatorPivot
@onready var launch_indicator_container: Node3D = $LaunchIndicatorPivot/LaunchIndicatorContainer
@onready var selected_sound: AudioStreamPlayer = $SelectedSound
@onready var launch_sound: AudioStreamPlayer = $LaunchSound


signal released

var _selected: bool = false
var _selectable: bool = true

# TODO - standardize this into a special Resource subclass if there is a need
var callbacks: Dictionary = {}

func _ready() -> void:
	launch_indicator_pivot.set_as_top_level(true)

func _process(_delta: float) -> void:
	if not _selected: return
	
	var mouse_position = callbacks.get_mouse_position.call()
	var launch_strength: float = clamp(
		(global_position.distance_to(mouse_position))/MAX_DRAG_DISTANCE,
		0.0, 1.0
	)
	launch_indicator_pivot.look_at(
		global_position + callbacks.get_launch_direction.call()
	)
	launch_indicator_container.scale.x = launch_strength

func _physics_process(_delta: float) -> void:
	launch_indicator_pivot.global_position = global_position

func _input(event: InputEvent) -> void:
	if not _selectable: return
	if not event.is_action_released("left_click"): return
	if not _selected: return
	_selected = false
	released.emit()
	launch_indicator_pivot.visible = false
	launch_sound.play()

@warning_ignore("unused_parameter")
func _input_event(camera: Camera3D, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if not _selectable: return
	if not event.is_action_pressed("left_click"): return
	if not front_segment.is_pinned_to_world() or not end_segment.is_pinned_to_world(): return
	_selected = true
	launch_indicator_pivot.visible = true
	selected_sound.play()

func set_selectable(selectable: bool) -> void:
	_selectable = selectable

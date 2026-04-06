extends Node

enum TutorialKey {
	MOVE,
	CLIMB,
	JUMP,
	LEAF
}
# Label3D does not have support for visible characters or automatic resizing yet 
# so we should just manually create newline characters here for now.
const TUTORIAL_TEXT: Array[String] = [
	"Click either end of the\ncaterpillar to move around.",
	"Drag one end of the\ncaterpillar to a climbing surface\nand release to grab hold.",
	"Drag and release the\ncaterpillar middle section to\njump!",
	"Grab leaves to open gates!"
]

## For developer convenience only. Value is only read on startup.
@export var enabled: bool = true

@onready var tutorial_label_container: Node3D = $TutorialLabelContainer
@onready var tutorial_label: Label3D = $TutorialLabelContainer/TutorialLabel

var _camera_pivot: Camera3D
var _caterpillar_player: Node3D
var _move_target_node: Node3D
var _current_tutorial: int = -1
var _tutorial_complete: bool = true

func _process(delta: float) -> void:
	if not _move_target_node: return
	
	tutorial_label_container.global_position = lerp(
		tutorial_label_container.global_position,
		_move_target_node.global_position,
		delta * 8.0
	)

func initialize(camera_pivot: Camera3D, caterpillar_player: Node3D) -> void:
	_camera_pivot = camera_pivot
	_camera_pivot.new_section_entered.connect(_on_new_section_entered)
	_caterpillar_player = caterpillar_player
	# cannot currently detect game start via _on_new_section_entered, so just
	# explicitly trigger the first tutorial on startup
	_give_tutorial(TutorialKey.MOVE)

func _give_tutorial(tutorial_key: TutorialKey) -> void:
	_tutorial_complete = false
	_current_tutorial = tutorial_key
	
	await get_tree().create_timer(1.0).timeout
	
	# update move target node on a per-tutorial basis
	match tutorial_key:
		TutorialKey.MOVE:
			_move_target_node = _caterpillar_player.front_caterpillar_end_segment
		TutorialKey.CLIMB:
			_move_target_node = _caterpillar_player.end_caterpillar_end_segment
		TutorialKey.JUMP:
			_move_target_node = _caterpillar_player.caterpillar_middle_segment
		TutorialKey.LEAF:
			_move_target_node = _caterpillar_player.caterpillar_middle_segment
	tutorial_label_container.global_position = _move_target_node.global_position
	
	await _write_text_to_label(TUTORIAL_TEXT[tutorial_key])
	
	_connect_competency_signals()
	_tutorial_complete = true

func _clear_tutorial() -> void:
	if not _tutorial_complete: return
	tutorial_label.text = ""

func _connect_competency_signals() -> void:
	match _current_tutorial:
		TutorialKey.MOVE:
			_caterpillar_player.front_caterpillar_end_segment.pinned_to_world.connect(_on_tutorial_complete.bind(TutorialKey.MOVE))
			_caterpillar_player.end_caterpillar_end_segment.pinned_to_world.connect(_on_tutorial_complete.bind(TutorialKey.MOVE))
		TutorialKey.CLIMB:
			_caterpillar_player.front_caterpillar_end_segment.pinned_to_world.connect(_on_tutorial_complete.bind(TutorialKey.CLIMB))
			_caterpillar_player.end_caterpillar_end_segment.pinned_to_world.connect(_on_tutorial_complete.bind(TutorialKey.CLIMB))
		TutorialKey.JUMP:
			_caterpillar_player.caterpillar_middle_segment.released.connect(_on_tutorial_complete.bind(TutorialKey.JUMP))
		TutorialKey.LEAF:
			get_tree().create_timer(5.0).timeout.connect(_on_tutorial_complete.bind(TutorialKey.LEAF))
			#TODO - some leaf get signal?

func _on_tutorial_complete(tutorial_key: TutorialKey) -> void:
	_clear_tutorial()
	match tutorial_key:
		TutorialKey.MOVE:
			# disconnect competency indicator signals
			_caterpillar_player.front_caterpillar_end_segment.pinned_to_world.disconnect(_on_tutorial_complete)
			_caterpillar_player.end_caterpillar_end_segment.pinned_to_world.disconnect(_on_tutorial_complete)
			# crtieria for next tutorial is only having finished this one
			_give_tutorial(TutorialKey.CLIMB) 
		TutorialKey.CLIMB:
			_caterpillar_player.front_caterpillar_end_segment.pinned_to_world.disconnect(_on_tutorial_complete)
			_caterpillar_player.end_caterpillar_end_segment.pinned_to_world.disconnect(_on_tutorial_complete)
			#_camera_pivot.new_section_entered.connect(_on_new_section_entered)
		TutorialKey.JUMP:
			_caterpillar_player.caterpillar_middle_segment.released.disconnect(_on_tutorial_complete)
			#_camera_pivot.new_section_entered.connect(_on_new_section_entered)
		TutorialKey.LEAF:
			pass
			#_camera_pivot.new_section_entered.disconnect(_on_new_section_entered)

# start tutorials based on entering a specific section
func _on_new_section_entered(section_id: int) -> void:
	match section_id:
		2: _give_tutorial(TutorialKey.JUMP)
		3: _give_tutorial(TutorialKey.LEAF)

func _write_text_to_label(text: String) -> void:
	if text == "": await get_tree().physics_frame
	for character: String in text:
		tutorial_label.text += character
		await get_tree().physics_frame
		await get_tree().physics_frame

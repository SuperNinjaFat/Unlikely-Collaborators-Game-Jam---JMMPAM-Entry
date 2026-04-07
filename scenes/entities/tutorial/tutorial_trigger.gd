extends Area3D
## A tutorial trigger that can be placed in any section.
## When the player enters the area, it displays a Label3D tutorial
## and waits for a completion condition before clearing it.

enum FollowTarget {
	FRONT,
	MIDDLE,
	BACK,
	FIXED_POSITION
}

enum CompletionMode {
	## Completes when any end segment is pinned to the world.
	PIN_TO_WORLD,
	## Completes when the middle segment is released (jump).
	MIDDLE_RELEASE,
	## Completes after a timeout.
	TIMEOUT
}

## The tutorial text to display. Use \n for line breaks since Label3D
## does not support automatic line wrapping.
@export_multiline var tutorial_text: String
## Which caterpillar body part the label should follow, or FIXED_POSITION
## to keep the label where you placed TutorialLabelContainer in the editor.
@export var follow_target: FollowTarget = FollowTarget.MIDDLE
## How the tutorial completes (dismissed).
@export var completion_mode: CompletionMode = CompletionMode.TIMEOUT
## Timeout duration when using TIMEOUT completion mode.
@export var timeout_duration: float = 5.0
## Delay before showing the tutorial after the player enters.
@export var show_delay: float = 1.0
## Unique ID for tracking whether this tutorial has been shown. Leave
## empty to show every time.
@export var tutorial_id: String

@onready var _label_container: Node3D = $TutorialLabelContainer
@onready var _label: Label3D = $TutorialLabelContainer/TutorialLabel

var _move_target_node: Node3D
var _is_showing: bool = false
var _triggered: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	input_ray_pickable = false
	# Check for bodies already overlapping (e.g. player spawned inside this trigger
	# from a checkpoint). We need to wait for the player to actually exist and for
	# the physics server to register overlaps, so wait a couple of physics frames.
	_check_existing_overlaps_delayed()

func _check_existing_overlaps_delayed() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	if _triggered:
		return
	for body in get_overlapping_bodies():
		_on_body_entered(body)
		if _triggered:
			break

func _process(delta: float) -> void:
	if follow_target == FollowTarget.FIXED_POSITION or not _move_target_node or not _is_showing:
		return
	_label_container.global_position = lerp(
		_label_container.global_position,
		_move_target_node.global_position,
		delta * 8.0
	)

func _on_body_entered(body: Node3D) -> void:
	if _triggered:
		return
	if not body.is_in_group("caterpillar_parts"):
		return

	# Check if already shown (if tracking by ID)
	if tutorial_id != "":
		var level_node := _find_level_node()
		if level_node:
			GameState.get_or_create_state()
			var level_state := GameState.get_level_state(level_node.scene_file_path)
			if tutorial_id in level_state.tutorials_seen:
				_triggered = true
				return

	_triggered = true
	_show_tutorial()

func _find_level_node() -> Node:
	# Walk up to find the level root (has level_won signal)
	var node := get_parent()
	while node:
		if node.has_signal("level_won"):
			return node
		node = node.get_parent()
	return null

func _show_tutorial() -> void:
	var player := get_tree().get_first_node_in_group("caterpillar")
	if not player:
		return

	_is_showing = true

	if show_delay > 0.0:
		await get_tree().create_timer(show_delay).timeout

	# Resolve which body part to follow (unless using fixed position)
	if not follow_target == FollowTarget.FIXED_POSITION:
		match follow_target:
			FollowTarget.FRONT:
				_move_target_node = player.front_caterpillar_end_segment
			FollowTarget.MIDDLE:
				_move_target_node = player.caterpillar_middle_segment
			FollowTarget.BACK:
				_move_target_node = player.end_caterpillar_end_segment
		_label_container.global_position = _move_target_node.global_position

	# Typewriter text animation
	_label.text = ""
	for character: String in tutorial_text:
		_label.text += character
		await get_tree().physics_frame
		await get_tree().physics_frame

	# Wait for completion
	match completion_mode:
		CompletionMode.PIN_TO_WORLD:
			var front = player.front_caterpillar_end_segment
			var back = player.end_caterpillar_end_segment
			# Use a one-shot connection; whichever fires first completes
			var completed := false
			var on_complete := func(_arg = null):
				if completed:
					return
				completed = true
				_complete_tutorial()
			front.pinned_to_world.connect(on_complete, CONNECT_ONE_SHOT)
			back.pinned_to_world.connect(on_complete, CONNECT_ONE_SHOT)
		CompletionMode.MIDDLE_RELEASE:
			player.caterpillar_middle_segment.released.connect(
				_complete_tutorial, CONNECT_ONE_SHOT
			)
		CompletionMode.TIMEOUT:
			get_tree().create_timer(timeout_duration).timeout.connect(_complete_tutorial)

func _complete_tutorial() -> void:
	_label.text = ""
	_is_showing = false
	_move_target_node = null

	# Mark as seen
	if tutorial_id != "":
		var level_node := _find_level_node()
		if level_node:
			var level_state := GameState.get_level_state(level_node.scene_file_path)
			level_state.tutorials_seen.append(tutorial_id)
			GlobalState.save()

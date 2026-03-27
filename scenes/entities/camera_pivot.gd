extends Node3D

@export var sections_parent: Node3D
# Array of sections, of type Node3D
var sections: Array[Node3D]
# Track the index of the current section
var current_section := 0
# Persisted level state for saving section progress
var level_state: LevelState

# On initialization, set up triggers and restore saved section.
func _ready() -> void:
	# Populate sections array
	for section in sections_parent.get_children():
		sections.append(section)

	for i in sections.size():
		# Find the trigger of the section, which will be an Area3D.
		var trigger := _find_trigger(sections[i])
		print("[CameraPivot] Section ", i, " (", sections[i].name, ") trigger: ", trigger)
		if trigger:
			trigger.section_entered.connect(_on_section_entered.bind(i))

		# Disable backtrack prevention on all sections at start
		_disable_backtrack_prevention(i)

	# Load persisted section state (ensure GameState exists first)
	var level_node := get_parent()
	if level_node:
		GameState.get_or_create_state()
		level_state = GameState.get_level_state(level_node.scene_file_path)

	# Restore saved section if resuming
	if level_state:
		print("[CameraPivot] level_state loaded | current_section saved: ", level_state.current_section)
	else:
		print("[CameraPivot] level_state: null")
	if level_state and level_state.current_section > 0:
		print("[CameraPivot] Restoring to section ", level_state.current_section)
		call_deferred("jump_to_section", level_state.current_section)

# Upon a section being entered, enable the new section, disable the old one
func _on_section_entered(index: int) -> void:
	print("[CameraPivot] _on_section_entered called with index: ", index, " (", sections[index].name, ") | current_section: ", current_section)
	# Track the previous section so we can disable it after it leaves the camera view
	var previous_section := current_section
	current_section = index

	# Persist section progress
	if level_state:
		level_state.current_section = index
		GlobalState.save()

	# Find the CameraSpot of the section, which is a Marker3D.
	var spot := _find_spot(sections[index])
	if spot:
		# Tween to the new CameraSpot.
		# TODO: Pause player physics while tweening
		var tween = create_tween()
		tween.tween_property(self , "global_position", spot.global_position, 0.5)
		_set_active_section(index)
		# Disable the previous section only once the camera stops panning.
		# Prevent going into the previous area by enabling backtrack-prevention geometry once tweening completes
		tween.finished.connect(func():
			_disable_section(previous_section)
			_enable_backtrack_prevention(current_section)
		)

# Instantly snap to a section (used when restoring from save, no tween).
func jump_to_section(index: int) -> void:
	if index < 0 or index >= sections.size():
		return
	current_section = index

	# Snap camera to section's CameraSpot
	var spot := _find_spot(sections[index])
	if spot:
		global_position = spot.global_position

	# Activate/deactivate sections and backtrack prevention
	for i in sections.size():
		if i == index:
			_set_active_section(i)
		else:
			_disable_section(i)
		if i <= index:
			_enable_backtrack_prevention(i)
		else:
			_disable_backtrack_prevention(i)

	# Teleport player to respawn point
	var player := get_parent().get_node_or_null("CatapillarPlayer")
	if player and player is RigidBody3D:
		player.global_position = get_respawn_position(index)
		player.linear_velocity = Vector3.ZERO
		player.angular_velocity = Vector3.ZERO

# Get the respawn position for a section (RespawnPoint Marker3D, or fallback to CameraSpot).
func get_respawn_position(index: int) -> Vector3:
	var section := sections[index]
	var respawn := section.get_node_or_null("RespawnPoint") as Marker3D
	if respawn:
		return respawn.global_position
	var spot := _find_spot(section)
	if spot:
		return spot.global_position + Vector3(0, -3, 0)
	return Vector3.ZERO

func _enable_backtrack_prevention(index: int) -> void:
	var container := sections[index].get_node_or_null("BacktrackPrevention")
	if container:
		container.visible = true
		container.process_mode = Node.PROCESS_MODE_INHERIT

func _disable_backtrack_prevention(index: int) -> void:
	var container := sections[index].get_node_or_null("BacktrackPrevention")
	if container:
		container.visible = false
		container.process_mode = Node.PROCESS_MODE_DISABLED

func _set_active_section(index: int) -> void:
	sections[index].visible = true
	sections[index].process_mode = Node.PROCESS_MODE_INHERIT

func _disable_section(index: int) -> void:
	# print("Disable section called: ", sections[index].name, " (", index, ") | Current: ", sections[current_section].name, " (", current_section, ") | Will disable: ", index != current_section)
	if index != current_section:
		# print("Disabling section ", index, ": visible=false, process_mode=DISABLED")
		sections[index].visible = false
		sections[index].process_mode = Node.PROCESS_MODE_DISABLED

func _find_trigger(section: Node3D) -> Area3D:
	for child in section.get_children():
		if child is Area3D:
			return child
	return null

func _find_spot(section: Node3D) -> Marker3D:
	for child in section.get_children():
		if child is Marker3D:
			return child
	return null

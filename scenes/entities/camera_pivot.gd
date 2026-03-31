extends Camera3D

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
	if level_state and level_state.current_section > 0:
		call_deferred("jump_to_section", level_state.current_section)
	else:
		# Fresh load — still apply selective rendering from section 0
		call_deferred("_update_active_sections", 0)

# Upon a section being entered, enable the new section, disable the old one
func _on_section_entered(index: int) -> void:
	# Skip if already in this section
	if index == current_section:
		return
	current_section = index

	# Persist section progress
	if level_state:
		level_state.current_section = index
		GlobalState.save()

	# Find the CameraSpot of the section, which is a Camera3D reference.
	var spot := _find_spot(sections[index])
	if spot:
		var tween = create_tween().set_parallel(true)
		tween.tween_property(self , "global_position", spot.global_position, 0.5)
		tween.tween_property(self , "size", spot.size, 0.5)
		tween.set_parallel(false)
		_update_active_sections(index)
		# Prevent going into the previous area by enabling backtrack-prevention geometry once tweening completes
		tween.finished.connect(func():
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
		size = spot.size

	# Activate adjacent sections, disable the rest
	_update_active_sections(index)
	# Enable backtrack prevention for all sections up to current
	for i in sections.size():
		if i <= index:
			_enable_backtrack_prevention(i)
		else:
			_disable_backtrack_prevention(i)

	# Teleport player to respawn point
	var player := get_parent().get_node_or_null("CaterpillarPlayer")
	if player:
		var respawn_pos := get_respawn_position(index)
		var offset: Vector3 = respawn_pos - player.global_position
		player.global_position = respawn_pos
		# Move all physics segments (RigidBody3Ds set as top_level) to follow
		var segment_container := player.get_node_or_null("PhysicsSegmentsContainer")
		if segment_container:
			for segment in segment_container.get_children():
				if segment is RigidBody3D:
					segment.global_position += offset
					segment.linear_velocity = Vector3.ZERO
					segment.angular_velocity = Vector3.ZERO

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

# Enable previous, current, and next sections; disable everything else.
func _update_active_sections(index: int) -> void:
	for i in sections.size():
		if i >= index - 1 and i <= index + 1:
			sections[i].visible = true
			sections[i].process_mode = Node.PROCESS_MODE_INHERIT
		else:
			sections[i].visible = false
			sections[i].process_mode = Node.PROCESS_MODE_DISABLED

func _find_trigger(section: Node3D) -> Area3D:
	return section.get_node_or_null("SectionTrigger") as Area3D

func _find_spot(section: Node3D) -> Camera3D:
	return section.get_node_or_null("CameraSpot") as Camera3D

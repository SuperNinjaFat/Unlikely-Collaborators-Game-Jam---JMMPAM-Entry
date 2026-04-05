extends Camera3D

const CaterpillarPlayerScene := preload("res://scenes/caterpillar/caterpillar_player.tscn")
# Local offset of the middle segment within the player scene
const MIDDLE_SEGMENT_LOCAL_OFFSET := Vector3(-1.5, 0, 0)

@export var end_cutscene: Cutscene
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

	# Determine which section to spawn at
	var spawn_section := 0
	if level_state and level_state.current_section > 0:
		spawn_section = level_state.current_section

	call_deferred("_initial_spawn", spawn_section)

# Spawn the player and set up the camera/sections for the initial load.
func _initial_spawn(index: int) -> void:
	_spawn_player(index)
	_update_active_sections(index)

	if index > 0:
		current_section = index
		var spot := _find_spot(sections[index])
		if spot:
			global_position = spot.global_position
			size = spot.size
		for i in sections.size():
			if i <= index:
				_enable_backtrack_prevention(i)
			else:
				_disable_backtrack_prevention(i)

# Instantiate a fresh CaterpillarPlayer with its center on the respawn point.
func _spawn_player(section_index: int) -> void:
	var player_instance := CaterpillarPlayerScene.instantiate()
	var respawn_pos := get_respawn_position(section_index)
	# Offset so the middle segment (at local x=-1.5) lands exactly on the respawn point
	player_instance.position = respawn_pos - MIDDLE_SEGMENT_LOCAL_OFFSET
	get_parent().add_child(player_instance)
	player_instance.engage_grip()
	player_instance.game_end_reached.connect(_on_game_end_reached)

func _on_game_end_reached() -> void:
	# play end cutscene
	var cutscene_manager = get_parent().get_node("CutsceneManager")
	await cutscene_manager.play_cutscene(end_cutscene)
	
	# end level after cutscene ends
	get_parent().level_won.emit()

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

# Destroy the current player and spawn a fresh one at the given section.
func jump_to_section(index: int) -> void:
	if index < 0 or index >= sections.size():
		return
	current_section = index

	# Snap camera to section's CameraSpot
	var spot := _find_spot(sections[index])
	if spot:
		global_position = spot.global_position
		size = spot.size

	_update_active_sections(index)
	for i in sections.size():
		if i <= index:
			_enable_backtrack_prevention(i)
		else:
			_disable_backtrack_prevention(i)

	# Remove old player, then spawn fresh
	var old_player := get_parent().get_node_or_null("CaterpillarPlayer")
	if old_player:
		old_player.queue_free()
		await get_tree().process_frame
	_spawn_player(index)

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

extends Node3D

# Array of sections, of type Node3D
@export var sections: Array[Node3D]
# Track the index of the current section
var current_section := 0

# On initialization, set up triggers.
func _ready() -> void:
	for i in sections.size():
		# Find the trigger of the section, which will be an Area3D.
		var trigger := _find_trigger(sections[i])
		if trigger:
			trigger.section_entered.connect(_on_section_entered.bind(i))

# Upon a section being entered, enable the new section, disable the old one
func _on_section_entered(index: int) -> void:
	# Track the previous section so we can disable it after it leaves the camera view
	var previous_section := current_section
	current_section = index
	# Find the CameraSpot of the section, which is a Marker3D.
	var spot := _find_spot(sections[index])
	if spot:
		# Tween to the new CameraSpot.
		var tween = create_tween()
		tween.tween_property(self , "global_position", spot.global_position, 0.5)
		#_set_active_section(index)
		# Disable the previous section only once the camera stops panning.
		#tween.finished.connect(func(): _disable_section(previous_section))


#func _set_active_section(index: int) -> void:
	#sections[index].visible = true
	#sections[index].process_mode = Node.PROCESS_MODE_INHERIT

#func _disable_section(index: int) -> void:
	#if index != current_section:
		#sections[index].visible = false
		#sections[index].process_mode = Node.PROCESS_MODE_DISABLED

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
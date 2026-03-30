extends Node3D

@onready var front_caterpillar_end_segment: RigidBody3D = $PhysicsSegmentsContainer/FrontCaterpillarEndSegment
@onready var caterpillar_middle_segment: RigidBody3D = $PhysicsSegmentsContainer/CaterpillarMiddleSegment
@onready var end_caterpillar_end_segment: RigidBody3D = $PhysicsSegmentsContainer/EndCaterpillarEndSegment
@onready var physics_segments_container: Node3D = $PhysicsSegmentsContainer
@onready var visual_segments_container: Node3D = $VisualSegmentsContainer

# Dictionary of Node3D[Transform3D]
#var _visual_segments: Dictionary = {}
var _visual_segments_0: Array[Node3D] = []
var _visual_segments_1: Array[Node3D] = []
var _physics_segment_spacing: float = 0.0
var _visual_segment_spacing: float = 0.0

func _ready() -> void:
	
	_physics_segment_spacing = (
		caterpillar_middle_segment.global_position - front_caterpillar_end_segment.global_position
	).length() 
	_visual_segment_spacing = _physics_segment_spacing / (float(visual_segments_container.get_child_count()) / 2.0)
	
	for i: int in range(visual_segments_container.get_child_count()):
		var segment: Node3D = visual_segments_container.get_child(i)
		@warning_ignore("integer_division")
		if i < visual_segments_container.get_child_count()/2: _visual_segments_0.append(segment)
		else: _visual_segments_1.append(segment)
		segment.set_as_top_level(true)

func _physics_process(delta: float) -> void:
	
	# Update segments between head and middle
	_update_visual_segments(
		front_caterpillar_end_segment, 
		caterpillar_middle_segment, 
		_visual_segments_0, 
		delta
	)
	
	# Update segments between middle and tail
	_update_visual_segments(
		caterpillar_middle_segment, 
		end_caterpillar_end_segment, 
		_visual_segments_1,
		delta
	)

func _update_visual_segments(start_physics_segment: RigidBody3D, end_physics_segment: RigidBody3D, visual_segments: Array[Node3D], _delta: float) -> void:
	
	var total_offset: Vector3 = end_physics_segment.global_position - start_physics_segment.global_position
	var direction: Vector3 = total_offset / _physics_segment_spacing
	
	for i: int in range(visual_segments.size()):
		
		var segment: Node3D = visual_segments[i]
		var distance_along: float = _visual_segment_spacing * float(i + 1)
		var target_position: Vector3 = start_physics_segment.global_position + direction * distance_along
		
		segment.global_position = target_position
		segment.look_at(start_physics_segment.global_position)

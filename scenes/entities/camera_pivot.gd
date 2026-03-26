extends Node3D

@onready var camera_spots = %CameraSpots
@onready var section_triggers = %SectionTriggers

func _ready() -> void:
    for trigger in section_triggers.get_children():
        trigger.section_entered.connect(_on_section_entered)

func _on_section_entered(index: int) -> void:
    var spots = camera_spots.get_children()
    if index < spots.size():
        var tween = create_tween()
        tween.tween_property(self , "global_position", spots[index].global_position, 0.5)

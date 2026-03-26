extends Area3D

@export var section_index: int

signal section_entered(index: int)

var triggered := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if not triggered and body.is_in_group("player"):
		section_entered.emit(section_index)
		triggered = true


# # Called every frame. 'delta' is the elapsed time since the previous frame.
# func _process(delta: float) -> void:
# 	pass

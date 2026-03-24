extends RigidBody3D

@onready var frontBody = $FrontBody
@onready var backBody = $BackBody

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# TODO: Use for freezing instead of ".freeze"
const FROZEN_MASS = 1000

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	backBody.freeze = backBody.get_colliding_bodies().size() > 0

	# Positive X impulse to a segment on keypress
	if Input.is_action_just_pressed("ui_up"):
		frontBody.apply_central_impulse(Vector3.UP * 4)

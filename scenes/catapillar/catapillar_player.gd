extends RigidBody3D

@onready var frontBody = $FrontBody
@onready var backBody = $BackBody

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# TODO: Remove. Temporary for testing.
	gravity_scale = 0
	frontBody.gravity_scale = 0
	backBody.gravity_scale = 0
	axis_lock_linear_z = true
	axis_lock_angular_z = true
	axis_lock_angular_x = true
	axis_lock_angular_y = true


# TODO: Use for freezing instead of ".freeze"
const FROZEN_MASS = 1000

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	# backBody.freeze = backBody.get_colliding_bodies().size() > 0
	# Positive forces to the center segment on keypress
	# TODO: Remove. Temporary for testing.
	var direction := Vector3.ZERO
	if Input.is_action_pressed("ui_up"):
		direction += Vector3.UP
	if Input.is_action_pressed("ui_down"):
		direction += Vector3.DOWN
	if Input.is_action_pressed("ui_left"):
		direction += Vector3.LEFT
	if Input.is_action_pressed("ui_right"):
		direction += Vector3.RIGHT
	
	if direction != Vector3.ZERO:
		apply_central_impulse(direction.normalized() * 1.0)

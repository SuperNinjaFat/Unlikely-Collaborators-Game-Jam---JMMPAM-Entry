extends Area3D

var _player_bodies_inside: int = 0
const REQUIRED_BODIES: int = 3

signal section_entered

func _ready() -> void:
	# On initialization, make player listen for a drag release (deferred to ensure player is ready)
	call_deferred("_connect_to_player")

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	# Prevent the trigger from intercepting mouse/physics picking events
	input_ray_pickable = false

func _connect_to_player() -> void:
	var caterpillar := get_tree().get_first_node_in_group("caterpillar")
	if caterpillar:
		if not caterpillar.drag_released.is_connected(_on_drag_released):
			caterpillar.drag_released.connect(_on_drag_released)
	else:
		# Player not spawned yet; retry next frame
		get_tree().process_frame.connect(_connect_to_player, CONNECT_ONE_SHOT)

func _on_drag_released():
	if _player_bodies_inside >= REQUIRED_BODIES:
		section_entered.emit()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("caterpillar_parts"):
		_player_bodies_inside += 1

func _on_body_exited(body: Node3D):
	if body.is_in_group("caterpillar_parts"):
		_player_bodies_inside -= 1

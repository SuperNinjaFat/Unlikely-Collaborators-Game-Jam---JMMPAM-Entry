extends Area3D

var _player_bodies_inside: int = 0
const REQUIRED_BODIES: int = 3

signal section_entered

func _ready() -> void:
	# On initialization, make player listen for a drag release (deferred to ensure player is ready)
	call_deferred("_connect_to_player")

	body_entered.connect(_on_body_entered)
	# Prevent the trigger from intercepting mouse/physics picking events
	input_ray_pickable = false
	print("[SectionTrigger] ", name, " ready. Monitoring: ", monitoring, " Collision layer: ", collision_layer, " Collision mask: ", collision_mask)

func _connect_to_player() -> void:
	var caterpillar := get_tree().get_first_node_in_group("caterpillar")
	if caterpillar:
		caterpillar.drag_released.connect(_on_drag_released)
		print("[SectionTrigger] ", name, " connected to drag_released on ", caterpillar.name)
	else:
		print("[SectionTrigger] WARNING: Could not find caterpillar node in group 'caterpillar'")

func _on_drag_released():
	print("[SectionTrigger] ", name, " _on_drag_released")
	if _player_bodies_inside >= REQUIRED_BODIES:
		print("[SectionTrigger] ", name, " -> emitting section_entered")
		section_entered.emit()

func _on_body_entered(body: Node3D) -> void:
	print("[SectionTrigger] ", name, " body_entered: ", body.name, " | Groups: ", body.get_groups(), " | Is in player group: ", body.is_in_group("caterpillar_parts"))
	if body.is_in_group("caterpillar_parts"):
		_player_bodies_inside += 1

func _on_body_exit(body: Node3D):
	if body.is_in_group("caterpillar_parts"):
		_player_bodies_inside -= 1

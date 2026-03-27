extends Area3D

var _player_bodies_inside: int = 0
const REQUIRED_BODIES: int = 3

signal section_entered

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Prevent the trigger from intercepting mouse/physics picking events
	input_ray_pickable = false
	print("[SectionTrigger] ", name, " ready. Monitoring: ", monitoring, " Collision layer: ", collision_layer, " Collision mask: ", collision_mask)

func _on_body_entered(body: Node3D) -> void:
	print("[SectionTrigger] ", name, " body_entered: ", body.name, " | Groups: ", body.get_groups(), " | Is in player group: ", body.is_in_group("player"))
	if body.is_in_group("player"):
		_player_bodies_inside += 1
		if _player_bodies_inside >= REQUIRED_BODIES:
			print("[SectionTrigger] ", name, " -> emitting section_entered")
			section_entered.emit()

func _on_body_exit(body: Node3D):
	if body.is_in_group("player"):
		_player_bodies_inside -= 1
extends Area3D

signal section_entered

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    # Prevent the trigger from intercepting mouse/physics picking events
    input_ray_pickable = false
    print("[SectionTrigger] ", name, " ready. Monitoring: ", monitoring, " Collision layer: ", collision_layer, " Collision mask: ", collision_mask)

func _on_body_entered(body: Node3D) -> void:
    print("[SectionTrigger] ", name, " body_entered: ", body.name, " | Groups: ", body.get_groups(), " | Is in player group: ", body.is_in_group("player"))
    if body.is_in_group("player"):
        print("[SectionTrigger] ", name, " -> emitting section_entered")
        section_entered.emit()

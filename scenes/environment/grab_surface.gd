extends Area3D

const WATER_MATERIAL_UID: String = "uid://cb5d5eh2m838j"

@onready var default_surface: MeshInstance3D = $DefaultSurface
#@onready var slide_surface: MeshInstance3D = $SlideSurface

@export var slide_velocity: Vector2 = Vector2.ZERO
@export var game_end: bool = false

func _ready() -> void:
	if slide_velocity == Vector2.ZERO: return

func _process(delta: float) -> void:
	if slide_velocity == Vector2.ZERO: return
	default_surface.get_active_material(0).uv1_offset.y += (delta * 0.25)
	if default_surface.get_active_material(0).uv1_offset.y >= 1.0:
		default_surface.get_active_material(0).uv1_offset.y += 1.0

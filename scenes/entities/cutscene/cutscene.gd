class_name Cutscene
extends Node3D

const BUTTERFLY_PACKED: String = "uid://dqe37o8xrie6g"

@onready var white_screen: ColorRect = $CanvasLayer/WhiteScreen

@export var camera_pivot: Node3D
var _player: Node3D

signal finished

func play() -> void:
	
	_player = camera_pivot.player_instance
	
	await create_tween().tween_property(
		white_screen, "modulate:a", 1.0, 2.0
	).finished
	
	_player.visible = false
	
	var butterfly: Node3D = load(BUTTERFLY_PACKED).instantiate()
	add_child(butterfly)
	var butterfly_spawn_position: Vector3 = global_position + Vector3(0.0, 0.0, 16.0)
	butterfly.global_position = butterfly_spawn_position
	butterfly.scale = Vector3(1.2, 1.2, 1.2)
	
	await get_tree().create_timer(1.0).timeout
	
	white_screen.modulate.a = 0.0
	
	await get_tree().create_timer(1.0).timeout
	
	await create_tween().tween_property(
		butterfly, "global_position", 
		butterfly.global_position + Vector3(4.0, -3.0, 0.0), 0.75
	).finished
	
	await create_tween().tween_property(
		butterfly, "global_position", 
		butterfly.global_position + Vector3(4.0, -1.0, 0.0), 0.5
	).finished
	
	await create_tween().tween_property(
		butterfly, "global_position", 
		butterfly.global_position + Vector3(2.0, 0.0, 0.0), 0.2
	).finished
	
	await create_tween().tween_property(
		butterfly, "global_position", 
		butterfly.global_position + Vector3(24.0, 12.0, 0.0), 1.5
	).finished
	
	await get_tree().create_timer(3.0).timeout
	
	white_screen.color = Color.BLACK
	await create_tween().tween_property(
		white_screen, "modulate:a", 1.0, 2.0
	).finished
	
	await get_tree().create_timer(2.0).timeout
	
	finished.emit()

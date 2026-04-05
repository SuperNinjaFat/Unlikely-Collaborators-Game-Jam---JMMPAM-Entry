class_name Cutscene
extends Node3D

signal finished

func play() -> void:
	# override in subclasses or unique instances
	# TEST: Spoof a cutscene playing out with a timeout.
	await get_tree().create_timer(2.0).timeout

	finished.emit()
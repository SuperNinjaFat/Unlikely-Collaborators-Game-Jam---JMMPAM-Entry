extends Node3D

func play_cutscene(cutscene: Cutscene) -> void:
	cutscene.play()
	await cutscene.finished
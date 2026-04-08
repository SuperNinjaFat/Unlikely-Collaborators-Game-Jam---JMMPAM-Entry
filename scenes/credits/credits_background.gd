extends Control

@onready var back_button = $BackButtonMargin/BackButton

func _ready() -> void:
	back_button.pressed.connect(hide)

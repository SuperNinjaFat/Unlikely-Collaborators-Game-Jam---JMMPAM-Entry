extends Area3D

@onready var collect_sound: AudioStreamPlayer = $CollectSound
@onready var animation_sprite: AnimatedSprite3D = $AnimatedSprite3D

signal leaf_collected

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Set and play a random idle animation
	var anims := animation_sprite.sprite_frames.get_animation_names()
	animation_sprite.play(anims[randi() % anims.size()])

# Get collected upon the player touching it
func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("caterpillar_parts"):
		visible = false
		set_deferred("monitoring", false)
		
		# Alert leaf puzzle logic of the collection
		leaf_collected.emit()

		# TODO: play particles
		# Play the collection sound
		collect_sound.play()
		# Let the collection sound play out until we remove the leaf
		await collect_sound.finished
		queue_free()

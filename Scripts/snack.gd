class_name Snack extends RigidBody2D

@onready var sprite : Sprite2D = %Sprite
@onready var letter_label : Label = %Letter
@onready var drop_sfx : AudioStreamPlayer = %DropSFX

var letter : String
var texture : CompressedTexture2D

func _ready() -> void:
	hide()
	letter_label.set_text(letter)
	sprite.set_texture(texture)
	show()
	apply_central_impulse(Vector2(randf_range(-150.0, 150.0), randf_range(-250.0, -150.0)))
	set_angular_velocity(randf_range(-5.0, 5.0))

func _on_hurtbox_entered(area: Area2D) -> void:
	if area.is_in_group("dispense_area"):
		drop_sfx.play()
		await drop_sfx.finished
		hide()
		queue_free()

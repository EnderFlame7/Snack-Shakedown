class_name MissingPoster extends Control

@onready var position_label : Label = %Position
@onready var name_label : Label = %Name
@onready var reward_label : Label = %Reward

func _ready() -> void:
	position_label.hide()
	name_label.hide()
	reward_label.hide()

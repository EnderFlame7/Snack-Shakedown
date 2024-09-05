class_name SlotLabel extends Control

@onready var label : Label = %Label
var label_text : String = ""

func _ready() -> void:
	label.set_text(label_text)

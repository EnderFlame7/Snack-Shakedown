class_name Demands extends Control

@onready var snack_demands : VBoxContainer = %SnackDemands

func _ready() -> void:
	Global.demands = self
	clear_demands()
	
	
func update_demands() -> void:
	for i in range(Global.main.quota_snacks.size()):
		snack_demands.get_child(i).get_child(1).set_texture(Global.main.snack_textures[Global.main.quota_snacks[i]])	# TEXTURE
		snack_demands.get_child(i).get_child(0).set_text(str(Global.main.quota_amounts[i]))								# LABEL
	
	
func clear_demands() -> void:
	for i in range(snack_demands.get_child_count()):
		snack_demands.get_child(i).get_child(1).set_texture(null)	# TEXTURE
		snack_demands.get_child(i).get_child(0).set_text("")		# LABEL

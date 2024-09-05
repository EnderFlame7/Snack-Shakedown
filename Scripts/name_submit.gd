extends Control


func _on_button_pressed() -> void:
	Global.player_name = $LineEdit.text
	Global.score = randi_range(50000, 150000)
	var sw_result : Dictionary = await SilentWolf.Scores.save_score(Global.player_name, Global.score).sw_save_score_complete
	print("Score persisted successfully: " + str(sw_result.score_id))
	#self.hide()

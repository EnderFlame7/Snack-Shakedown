class_name Leaderboard extends Control

@onready var posters : Node2D = %Posters

var player_list_with_pos = []

func _ready() -> void:
	Global.leaderboard = self
	refresh()


func add_player_to_leaderboard(player_list):
	
	for i in range(posters.get_child_count()):
		posters.get_child(i).position_label.hide()
		posters.get_child(i).name_label.hide()
		posters.get_child(i).reward_label.hide()
	
	for i in range(player_list_with_pos.size()):
		posters.get_child(i).position_label.text = str(player_list_with_pos[i]["position"])
		posters.get_child(i).position_label.show()
	
	for i in range(player_list_with_pos.size()):
		posters.get_child(i).name_label.text = str(player_list_with_pos[i]["player_name"].to_upper())
		posters.get_child(i).name_label.show()
	
	for i in range(player_list_with_pos.size()):
		var opt_thousand : String = str(floor(player_list_with_pos[i]["score"] / 1000)) if player_list_with_pos[i]["score"] >= 1000 else ""
		var opt_comma : String = "," if player_list_with_pos[i]["score"] >= 1000 else ""
		var opt_hundred_zero : String = "0" if fmod(player_list_with_pos[i]["score"], 1000) < 100 else ""
		var opt_ten_zero : String = "0" if fmod(player_list_with_pos[i]["score"], 1000) < 10 else ""
		
		posters.get_child(i).reward_label.text = "$" + opt_thousand + opt_comma + opt_hundred_zero + opt_ten_zero + str(fmod(player_list_with_pos[i]["score"], 1000))
		posters.get_child(i).reward_label.show()
		print(str(player_list_with_pos[i]["score"]))
		

func sort_players_and_add_position(player_list):
	var position = 1
	for player in player_list:
		player["position"] = position
		position += 1
		
	return player_list
	
	
func refresh() -> void:
	var sw_result: Dictionary = await SilentWolf.Scores.get_scores(10).sw_get_scores_complete
	player_list_with_pos = sort_players_and_add_position(SilentWolf.Scores.scores)
	add_player_to_leaderboard(player_list_with_pos)

extends Node

var main : Main
var ui : UI
var snack_grid : SnackGrid
var leaderboard : Leaderboard
var demands : Demands

const FIRST_SLOT_CODE : int = 10
const SNACK_COLS : int = 5
const SNACK_ROWS : int = 6
const SNACK_SLOTS : int = SNACK_COLS * SNACK_ROWS

const SNACK_VARIETY : int = 5


var player_name : String
var player_list = []

var score = 0

func _ready() -> void:
	SilentWolf.configure({
		"api_key": "DdwyouPkwF8NHJ1ZBbhhA4Tca92yj3cl8pzTg51s",
		"game_id": "snackshakedown",
		"log_level": 1
	})
	
	SilentWolf.configure_scores({
		"open_scene_on_close": "res://Scenes/main.tscn"
	})


func _process(delta: float) -> void:
	leaderboard_func()
	
	
func leaderboard_func() -> void:
	for score in Global.score:
		Global.player_list.append(Global.player_name)

class_name SnackGrid extends Control

@onready var snack_slot_grid : GridContainer = %SnackSlotGrid
@onready var slot_label_grid : GridContainer = %SlotLabelGrid
@onready var snack_slot_scene : PackedScene = preload("res://Scenes/snack_slot.tscn")
@onready var slot_label_scene : PackedScene = preload("res://Scenes/slot_label.tscn")

var snack_array : Array[Array]
var connection_amount_per_snack : Array[int]
var dispensing : bool = false
var signal_connected : bool = false

signal quota_met
signal game_over

func _ready() -> void:
	Global.snack_grid = self
	for i in range(Global.SNACK_SLOTS):
		var snack_slot : SnackSlot = snack_slot_scene.instantiate()
		snack_slot.slot_num = i
		snack_slot.dispensed.connect(_check_for_connections)
		snack_slot_grid.add_child(snack_slot)
	for i in range(Global.SNACK_SLOTS):
		var slot_label : SlotLabel = slot_label_scene.instantiate()
		slot_label.label_text = str(Global.FIRST_SLOT_CODE + i)
		slot_label_grid.add_child(slot_label)
	snack_array = update_snack_array()
	
	
func _process(delta: float) -> void:
	if Global.main and not signal_connected:
		quota_met.connect(Global.main._quota_met)
		game_over.connect(Global.main._game_over)
		signal_connected = true
		

# called from using ui "input_recieved" signal
func _dispense_slot(snack_slot_index : int) -> void:
	#print("DISPENSING SLOT ", str(snack_slot_index))
	snack_slot_grid.get_child(snack_slot_index)._dispense()
	dispensing = true


# Called by dispensed snack_slot via "dispensed" signal
func _check_for_connections(snack_dispensed : int, slot : int) -> Array[int]:
	
	dispensing = false
	snack_array = update_snack_array()
	var max_connections : Array[int]
	
	if Global.main.game_started and not Global.main.game_over:
		for snack_type in range(Global.SNACK_VARIETY):
			var max_connection : int = 0
			for i in range(Global.SNACK_ROWS):
				#snack_array
				for j in range(Global.SNACK_COLS):
					if snack_array[i][j] == snack_type:
						var snack : Vector2i = Vector2i(i, j)
						var connection : int = 0
						var connected_slots : Array[Vector2i] = []
						var slot_stack : Array[Vector2i] = []
						while not snack == Vector2i(-1, -1):
							connection += 1
							connected_slots.append(snack)
							# Check UP
							if (snack.x > 0) and (snack_array[snack.x - 1][snack.y] == snack_type) and (connected_slots.find(Vector2i(snack.x - 1, snack.y)) == -1):
								if slot_stack.find(Vector2i(snack.x - 1, snack.y)) == -1:
									slot_stack.append(Vector2i(snack.x - 1, snack.y))
							# Check DOWN
							if (snack.x < Global.SNACK_ROWS - 1) and (snack_array[snack.x + 1][snack.y] == snack_type) and (connected_slots.find(Vector2i(snack.x + 1, snack.y)) == -1):
								if slot_stack.find(Vector2i(snack.x + 1, snack.y)) == -1:
									slot_stack.append(Vector2i(snack.x + 1, snack.y))
							# Check LEFT
							if (snack.y > 0) and (snack_array[snack.x][snack.y - 1] == snack_type) and (connected_slots.find(Vector2i(snack.x, snack.y - 1)) == -1):
								if slot_stack.find(Vector2i(snack.x, snack.y - 1)) == -1:
									slot_stack.append(Vector2i(snack.x, snack.y - 1))
							# Check RIGHT
							if (snack.y < Global.SNACK_COLS - 1) and (snack_array[snack.x][snack.y + 1] == snack_type) and (connected_slots.find(Vector2i(snack.x, snack.y + 1)) == -1):
								if slot_stack.find(Vector2i(snack.x, snack.y + 1)) == -1:
									slot_stack.append(Vector2i(snack.x, snack.y + 1))
								
							if slot_stack.size() > 0:
								snack = slot_stack.pop_back()
							else:
								snack = Vector2i(-1, -1)
						if connection > max_connection:
							max_connection = connection
			print("Snack: ", snack_type, " Max Connection: ", max_connection)
			max_connections.append(max_connection)
		var is_quota_met : bool = true
		for quota_snack in Global.main.quota_snacks:
			if not max_connections[quota_snack] >= Global.main.quota_amounts[Global.main.quota_snacks.find(quota_snack)]:
				is_quota_met = false
				break
		if is_quota_met and not Global.main.quota_met:
			quota_met.emit()
		elif Global.main.money == 0 and not Global.main.quota_met:
			game_over.emit()
	elif Global.main.menu:
		if snack_dispensed == 1:
			Global.main._start_game()
		elif snack_dispensed == 2:
			Global.main._show_leaderboard()
	elif Global.main.name_submit:
		handle_name_submition(slot)
	connection_amount_per_snack = max_connections
	return max_connections
	
	
func handle_name_submition(slot : int) -> void:
	var alph_string : String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	if slot == 28:
		Global.ui._write_letter("", true)
		Global.ui._write_letter("  ")
	elif slot == 29:
		Global.player_name = Global.ui.middle_label.text.substr(2)
		Global.score = Global.main.score
		var sw_result : Dictionary = await SilentWolf.Scores.save_score(Global.player_name, Global.score).sw_save_score_complete
		print("Score persisted successfully: " + str(sw_result.score_id))
		Global.main.leaderboard_wall.refresh()
		Global.main.vending_machine._generate_menu_vending_machine()
		Global.main._show_leaderboard()
	elif slot < alph_string.length():
		Global.ui._write_letter(alph_string[slot])


func update_snack_array() -> Array[Array]:
	var updated_snack_array : Array[Array] = []
	var snack_index : int = 0
	for i in range(Global.SNACK_ROWS):
		updated_snack_array.append([])
		for j in range(Global.SNACK_COLS):
			updated_snack_array[i].append(snack_slot_grid.get_child(snack_index).get_snack())
			snack_index += 1
	return updated_snack_array
	
	
func _randomize() -> void:
	for snack_slot in snack_slot_grid.get_children():
		snack_slot.randomize_snacks()


func _setup_menu() -> void:
	for i in range(snack_slot_grid.get_child_count()):
		if i == 11:
			snack_slot_grid.get_child(i).menu(1)
		elif i == 13:
			snack_slot_grid.get_child(i).menu(2)
		else:
			snack_slot_grid.get_child(i).menu(0)
			
			
func _setup_name_submit() -> void:
	var alph_string : String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	for i in range(snack_slot_grid.get_child_count()):
		if i == 28:
			snack_slot_grid.get_child(i).name_submit(1)
		elif i == 29:
			snack_slot_grid.get_child(i).name_submit(2)
		else:
			snack_slot_grid.get_child(i).name_submit(0)
			if i < alph_string.length():
				snack_slot_grid.get_child(i).letter_label.set_text(alph_string[i])
				snack_slot_grid.get_child(i).letter_label.show()

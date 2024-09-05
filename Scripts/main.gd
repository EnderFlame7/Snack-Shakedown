class_name Main extends Node2D

@onready var vending_machine : VendingMachine = %VendingMachine
@onready var camera : Camera2D = %Camera
@onready var shake_timer : Timer = %ShakeTimer
@onready var leaderboard_wall : Leaderboard = %Leaderboard
@onready var anim_player : AnimationPlayer = %AnimPlayer

# SFX
@onready var ambience_sfx : AudioStreamPlayer = %AmbienceSFX
@onready var countdown_sfx : AudioStreamPlayer = %CountdownSFX
@onready var warning_sfx : AudioStreamPlayer = %WarningSFX
@onready var quota_met_sfx : AudioStreamPlayer = %QuotaMetSFX

# TEXTURE ARRAYS
@export var snack_textures : Array[CompressedTexture2D]
@export var menu_snack_textures : Array[CompressedTexture2D]
@export var name_snack_textures : Array[CompressedTexture2D]

var level : int = 0
var score : int = 0
var init_money : int = 0
var money : int = 0
var init_time : float = 60.0
var time : float = 60.0
var prev_time : int = time - 1

var quota_snacks : Array[int]
var quota_amounts : Array[int]

var menu : bool = true
var name_submit : bool = false
var leaderboard : bool = false

var game_started : bool = false
var quota_met : bool = false
var game_over : bool = false

func _ready() -> void:
	Global.main = self
	anim_player.set_current_animation("RESET")
	anim_player.play()
	ambience_sfx.play()
	
	# START ON MAIN MENU
	vending_machine._generate_menu_vending_machine()


func _process(delta: float) -> void:
	if game_started and not quota_met and not game_over:
		if money == 1:
			vending_machine._on_open_flap()
		handle_time(delta)
	elif game_over:
		camera_shake()


func set_money(new_money : int) -> void:
	money = new_money
	money = clamp(money, 0, 999)
	
	
func handle_time(delta: float) -> void:
	time -= delta
	time = clamp(time, 0, 60.0)
	if time < prev_time and time > 10:
		countdown_sfx.play()
		if money > 1: vending_machine._on_close_flap()
	elif time < prev_time and time <= 10:
		warning_sfx.play()
		if time <= 5:
			vending_machine._on_open_flap()
	elif time == 0:
		_game_over()
	prev_time = floor(time)


# Called from snack_grid signal "quota_met"
func _quota_met() -> void:
	if game_started and not game_over:
		quota_met = true
		level += 1
		
		if level > 1:
			score += 100
			if time > 0:
				score += snappedf((time / init_time) * init_time, 1)
			if money > 0:
				score += (snappedf(money / (init_money * 1.0), 0.2) * 125)
			var max_connections : Array[int] = await Global.snack_grid._check_for_connections(0, 0)
			for snack in quota_snacks:
				if max_connections[snack] > quota_amounts[quota_snacks.find(snack)]:
					score += (snappedf(max_connections[snack] / (quota_amounts[quota_snacks.find(snack)] * 1.0), 0.2) * 500)
		
		quota_met_sfx.play()
		await get_tree().create_timer(1.0).timeout
		vending_machine._generate_random_vending_machine()
		await get_tree().create_timer(1.0).timeout
		time = 60.0 - clamp(floorf(level / 10.0) * 5.0, 0.0, 35.0)
		init_time = time
		print("LEVEL: ", level, " TIME: ", time)
		generate_quota()
		
		
# Called from snack_grid signal "game_over"
func _game_over() -> void:
	if game_started and not game_over:
		game_started = false
		game_over = true
		vending_machine._on_shoot()


func generate_quota() -> void:
	var max_connections : Array[int] = await Global.snack_grid._check_for_connections(0, 0)
	print(max_connections)
	var smallest_snacks : Array[int] = []
	var smallest_connections : Array[int] = []
	for i in range(max_connections.size()):
		var smallest_snack : int
		var smallest_connection : int = 999
		for j in range(max_connections.size()):
			if (max_connections[j] < smallest_connection) and smallest_snacks.find(j) == -1:
				smallest_snack = j
				smallest_connection = max_connections[j]
		smallest_snacks.append(smallest_snack)
		smallest_connections.append(smallest_connection)
	print("SMALLEST SNACKS: ", smallest_snacks)
	print("SMALLEST CONNECTIONS: ", smallest_connections)
		
	var quota_variety : int = 1
	if level > 1:
		quota_variety = clamp(ceil(level / 5), 1, 3)
		
	quota_snacks.clear()
	quota_amounts.clear()
	for variety in range(quota_variety):
		quota_snacks.append(smallest_snacks[variety])
		quota_amounts.append(smallest_connections[variety] + 3)
	set_money(calculate_minimum_cost(quota_snacks, quota_amounts))
	init_money = money
	quota_met = false
	for i in range(quota_snacks.size()):
		print("QUOTA: ", quota_amounts[i], " ", (quota_snacks[i] + 1), "'s")
	Global.demands.update_demands()

func camera_shake() -> void:
	if not shake_timer.is_stopped():
		camera.global_position = Vector2(randf_range(-25.0, 25.0), randf_range(-25.0, 25.0))
	else:
		camera.global_position = Vector2.ZERO
		
		
func _start_game() -> void:
	if menu:
		menu = false
		game_started = true
		
		# TEMPORARY WAY TO START GAME
		level = 0
		_quota_met()
		score = 0
	
func _show_leaderboard() -> void:
	menu = false
	name_submit = false
	leaderboard = true
	leaderboard_wall.refresh()
	anim_player.set_current_animation("show_leaderboard")
	anim_player.play()
	
	
func _hide_leaderboard() -> void:
	leaderboard = false
	menu = true
	anim_player.set_current_animation("hide_leaderboard")
	anim_player.play()
	
	
func calculate_minimum_cost(quota_snacks : Array[int], quota_amounts : Array[int]) -> int:
	var snack_array = Global.snack_grid.update_snack_array()
	var final_result
	print(snack_array)
	var total_min_cost : int = 0
	for quota_snack in range(quota_snacks.size()):
		var min_cost : int = 999
		var all_connected_slots : Array[Vector2i] = []
		for i in range(Global.SNACK_ROWS - 1):
			for j in range(Global.SNACK_COLS - 1):
				var slot : Vector2i = Vector2i(i, j)
				var cost : int = calculate_slot_cost(snack_array[slot.x][slot.y], quota_snacks[quota_snack])
				all_connected_slots.append(slot)
				#var slot_stack : Array[Vector2i] = []
				for num in range(quota_amounts[quota_snack] - 1):
					var min_cost_to_add : int = 999
					var slot_with_min_cost : Vector2i
					# Check UP
					if (slot.x > 0) and (all_connected_slots.find(Vector2i(slot.x - 1, slot.y)) == -1):
						var up_snack_cost : int = calculate_slot_cost(snack_array[slot.x - 1][slot.y], quota_snacks[quota_snack])
						if up_snack_cost < min_cost_to_add:
							min_cost_to_add = up_snack_cost
							slot_with_min_cost = Vector2i(slot.x - 1, slot.y)
						#if slot_stack.find(Vector2i(slot.x - 1, slot.y)) == -1:
							#slot_stack.append(Vector2i(slot.x - 1, slot.y))
					# Check DOWN
					if (slot.x < Global.SNACK_ROWS - 1) and (all_connected_slots.find(Vector2i(slot.x + 1, slot.y)) == -1):
						var down_snack_cost : int = calculate_slot_cost(snack_array[slot.x + 1][slot.y], quota_snacks[quota_snack])
						if down_snack_cost < min_cost_to_add:
							min_cost_to_add = down_snack_cost
							slot_with_min_cost = Vector2i(slot.x + 1, slot.y)
						#if slot_stack.find(Vector2i(slot.x + 1, slot.y)) == -1:
							#slot_stack.append(Vector2i(slot.x + 1, slot.y))
					# Check LEFT
					if (slot.y > 0) and (all_connected_slots.find(Vector2i(slot.x, slot.y - 1)) == -1):
						var left_snack_cost : int = calculate_slot_cost(snack_array[slot.x][slot.y - 1], quota_snacks[quota_snack])
						if left_snack_cost < min_cost_to_add:
							min_cost_to_add = left_snack_cost
							slot_with_min_cost = Vector2i(slot.x, slot.y - 1)
						#if slot_stack.find(Vector2i(slot.x, slot.y - 1)) == -1:
							#slot_stack.append(Vector2i(slot.x, slot.y - 1))
					# Check RIGHT
					if (slot.y < Global.SNACK_COLS - 1) and (all_connected_slots.find(Vector2i(slot.x, slot.y + 1)) == -1):
						var right_snack_cost : int = calculate_slot_cost(snack_array[slot.x][slot.y + 1], quota_snacks[quota_snack])
						if right_snack_cost < min_cost_to_add:
							min_cost_to_add = right_snack_cost
							slot_with_min_cost = Vector2i(slot.x, slot.y + 1)
						#if slot_stack.find(Vector2i(slot.x, slot.y + 1)) == -1:
							#slot_stack.append(Vector2i(slot.x, slot.y + 1))
					slot = slot_with_min_cost
					all_connected_slots.append(slot)
					cost += min_cost_to_add
				if cost < min_cost:
					min_cost = cost
					#final_result = connected_slots
		#for coord in final_result:
			#print(((coord.x + 1) * (coord.y + 1)) + 9)
		total_min_cost += min_cost
	print("MONEY GIVEN: ", total_min_cost)
	return total_min_cost


func calculate_slot_cost(from : int, to : int) -> int:
	var cost : int = 0
	while from != to:
		from += 1
		cost += 1
		if from == Global.SNACK_VARIETY:
			from = 0
	return cost

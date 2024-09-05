class_name SnackSlot extends Control

@onready var snack_sprites : Array[Sprite2D] = [%SnackFront, %SnackMid, %SnackBack, %SnackAdd]
@onready var letter_label : Label = %Letter
@onready var dispense_sfx : AudioStreamPlayer = %DispenseSFX
@onready var anim_player : AnimationPlayer = %AnimPlayer

var slot_num : int
var current_snack : int
var snack_order : Array[int]
var randomized : bool = false
var letter : String = ""

signal dispensed(snack_dispensed : int)

func _ready() -> void:
	letter_label.hide()
	anim_player.set_current_animation("RESET")
	anim_player.play()


func _process(delta: float) -> void:
	if Global.main and not randomized:
		randomized = true
		randomize_snacks()


func randomize_snacks() -> void:
	var front_snack : int = randi_range(0, Global.SNACK_VARIETY - 1)
	var snack : int = front_snack
	#print(snack)
	snack_order.clear()
	for i in range(snack_sprites.size()):
		snack_order.append(snack)
		snack_sprites[i].set_texture(Global.main.snack_textures[snack_order[i]])
		snack_sprites[i].rotation = deg_to_rad(randi_range(-7, 7))
		snack += 1
		if snack >= Global.SNACK_VARIETY:
			snack = 0
	current_snack = front_snack


# called from snack_grid
func _dispense() -> void:
	
	if Global.main.game_started:
		Global.main.set_money(Global.main.money - 1)
	
	dispense_sfx.play()
	anim_player.set_current_animation("dispense")
	anim_player.play()
	await anim_player.animation_finished
	var snack_dispensed : int = snack_order.pop_front()
	
	var snack : Snack = preload("res://Scenes/snack.tscn").instantiate()
	snack.global_position = position
	if Global.main.game_started:
		snack.letter = ""
		snack.texture = Global.main.snack_textures[snack_dispensed]
	elif Global.main.menu:
		snack.letter = ""
		snack.texture = Global.main.menu_snack_textures[snack_dispensed]
	elif Global.main.name_submit:
		var alph_string : String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
		if slot_num < alph_string.length(): snack.letter = alph_string[slot_num]
		else: snack.letter = ""
		snack.texture = Global.main.name_snack_textures[snack_dispensed]
	get_parent().add_child(snack)
	
	if Global.main.game_started:
		var snack_to_add : int = snack_order[snack_order.size() - 1] + 1
		if snack_to_add >= Global.SNACK_VARIETY:
			snack_to_add = 0
		snack_order.append(snack_to_add)
		current_snack = snack_order[0]
		for i in range(snack_sprites.size() - 1):
			snack_sprites[i].set_texture(Global.main.snack_textures[snack_order[i]])
	else:
		snack_order.append(snack_dispensed)
		current_snack = snack_order[0]
		if Global.main.menu:
			for i in range(snack_sprites.size() - 1):
				snack_sprites[i].set_texture(Global.main.menu_snack_textures[snack_order[i]])
		elif Global.main.name_submit:
			for i in range(snack_sprites.size() - 1):
				snack_sprites[i].set_texture(Global.main.name_snack_textures[snack_order[i]])
			
	anim_player.set_current_animation("RESET")
	snack_sprites[snack_sprites.size() - 1].rotation = deg_to_rad(randi_range(-7, 7))
	snack_sprites[0].rotation = deg_to_rad(randi_range(-7, 7))
	#print("DISPENSED SNACK ", snack_dispensed)
	dispensed.emit(snack_dispensed, slot_num)


func get_snack() -> int:
	return current_snack
	
	
func menu(menu_snack : int) -> void:
	letter_label.set_text("")
	snack_order.clear()
	for i in range(snack_sprites.size()):
		snack_order.append(menu_snack)
		snack_sprites[i].set_texture(Global.main.menu_snack_textures[snack_order[i]])
		snack_sprites[i].rotation = deg_to_rad(randi_range(-7, 7))
	current_snack = snack_order[0]
	
	
func name_submit(name_submit_snack : int) -> void:
	snack_order.clear()
	for i in range(snack_sprites.size()):
		snack_order.append(name_submit_snack)
		snack_sprites[i].set_texture(Global.main.name_snack_textures[snack_order[i]])
		snack_sprites[i].rotation = deg_to_rad(randi_range(-7, 7))
	current_snack = snack_order[0]

class_name UI extends Control

@onready var top_label : Label = %TopText
@onready var middle_label : Label = %MiddleText
@onready var bottom_label : Label = %BottomText
@onready var input_label : Label = %Input
@onready var num_grid : GridContainer = %NumGrid
@onready var button_sfx : AudioStreamPlayer = %ButtonSFX
@onready var invalid_sfx : AudioStreamPlayer = %InvalidSFX

var input : String = ""
var signal_connected : bool = false

signal input_recieved(input : int)

func _ready() -> void:
	Global.ui = self
	update_screen(0.0)
	for button in num_grid.get_children():
		button.pressed.connect(_on_button_press)


func _process(delta: float) -> void:
	if Global.snack_grid and not signal_connected:
		input_recieved.connect(Global.snack_grid._dispense_slot)
		signal_connected = true
		
	if Global.main.quota_met:
		disable_buttons(true)
	else:
		disable_buttons(false)

	update_screen(delta)

func _on_button_press() -> void:
	if not Global.snack_grid.dispensing:
		for button in num_grid.get_children():
			if button.button_pressed:
				if button.get_groups()[0].is_valid_int() and ((Global.main.game_started and Global.main.money > 0) or (not Global.main.game_started)):
					if button.get_groups()[0].is_valid_int():
						button_sfx.set_pitch_scale(1.0)
						button_sfx.play()
						input += str(button.get_groups()[0])
						#print(input)
						if input.length() == 2:
							""" returns snack slot as index (minus Global.FIRST_SLOT_CODE
							because first slot has code Global.FIRST_SLOT_CODE,  check
							Global script).
							"""
							if ((input.to_int() - Global.FIRST_SLOT_CODE) < Global.SNACK_SLOTS) and ((input.to_int() - Global.FIRST_SLOT_CODE) >= 0):
								if Global.main.name_submit and middle_label.text.length() == 8 and not input.to_int() >= 26:
									invalid_sfx.play()
									input = "TOO LONG!"
								elif Global.main.name_submit and middle_label.text.length() <= 2 and input == "39":
									invalid_sfx.play()
									input = "EMPTY!"
								else:
									input_recieved.emit(input.to_int() - Global.FIRST_SLOT_CODE)
							else:
								invalid_sfx.play()
								input = "INVALID!"
						elif input.length() > 2:
							input = str(button.get_groups()[0])
				elif button.get_groups()[0].is_valid_int() and Global.main.money <= 0:
					invalid_sfx.play()
					#print("BROKE!")
					input = "BROKE!"
				elif button.is_in_group("X"):
					button_sfx.set_pitch_scale(0.8)
					button_sfx.play()
					input = ""
					if Global.main.leaderboard:
						Global.main._hide_leaderboard()
					#print(input)
					
					
func update_timer() -> void:
	var opt_sec_zero : String = "0" if floor(fmod(Global.main.time, 60)) < 10 else ""
	var opt_milli_sec_zero : String = "0" if snapped(100 * (snapped(Global.main.time, 0.01) - floor(Global.main.time)), 1) < 10 else ""
	middle_label.set_text("    " + opt_sec_zero + str(String.num(floor(fmod(Global.main.time, 60)), 0)) + "." + opt_milli_sec_zero + str(snapped(100 * (snapped(Global.main.time, 0.01) - floor(Global.main.time)), 1)))
	middle_label.show()


func disable_buttons(disable : bool) -> void:
	if disable:
		for button in num_grid.get_children():
			button.set_deferred("disabled", true)
	else:
		for button in num_grid.get_children():
			button.set_deferred("disabled", false)


func update_screen(delta : float) -> void:
	if Global.main:
		if Global.main.game_started:
			top_label.set_text("BALANCE:\n$" + str(Global.main.money) + ".00")
			update_timer()
			bottom_label.set_text("*" + str(Global.main.score) + "*")
			bottom_label.show()
		elif Global.main.menu:
			top_label.set_text("WHAT WOULD YOU LIKE?")
			middle_label.set_text("")
			bottom_label.hide()
		elif Global.main.name_submit:
			top_label.set_text("WHAT WAS YOUR NAME?")
			bottom_label.hide()
		elif Global.main.leaderboard:
			top_label.set_text("IGNORE THOSE. \"X\" FOR SNACK!")
			middle_label.hide()
			bottom_label.hide()
	input_label.set_text(input)


func _write_letter(letter : String, clear : bool = false) -> void:
	if not clear:
		middle_label.set_text(middle_label.text + letter)
	else:
		middle_label.set_text("")

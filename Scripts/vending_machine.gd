class_name VendingMachine extends Node2D

@onready var flap : AnimatedSprite2D = %Flap
@onready var light : PointLight2D = %LampPostLight
@onready var darkness : Polygon2D = %Darkness
@onready var muzzle_flash : PointLight2D = %MuzzleFlash
@onready var blood : Sprite2D = %Blood
@onready var demands : Control = %Demands
@onready var anim_player : AnimationPlayer = %AnimPlayer

# SFX
@onready var flap_open_sfx : AudioStreamPlayer = %FlapOpenSFX
@onready var flap_close_sfx : AudioStreamPlayer = %FlapCloseSFX
@onready var gun_cock_sfx : AudioStreamPlayer = %GunCockSFX
@onready var gun_holster_sfx : AudioStreamPlayer = %GunHolsterSFX
@onready var gun_shot_sfx : AudioStreamPlayer = %GunShotSFX
@onready var flicker_sfx : AudioStreamPlayer = %FlickerSFX

var flap_open : bool = false
var shoot : bool = false

func _ready() -> void:
	anim_player.set_current_animation("reset")
	anim_player.play()
	demands.hide()
	muzzle_flash.hide()
	blood.hide()
	flap.set_animation("reset")
	flap_open = false
	
	
func _process(delta: float) -> void:
	pass
	#if Input.is_action_just_pressed("rmb"):
		#anim_player.set_current_animation("randomize")
		#anim_player.play()
		
		
func _generate_random_vending_machine() -> void:
	anim_player.set_current_animation("randomize")
	anim_player.play()
	
	
func _generate_menu_vending_machine() -> void:
	Global.main.game_over = false
	Global.main.menu = true
	anim_player.set_current_animation("menu")
	anim_player.play()
	
	
func _generate_name_submit_vending_machine() -> void:
	Global.main.game_over = false
	Global.main.name_submit = true
	Global.ui._write_letter("", true) # CLEARS MIDDLE STRING FOR NAME
	Global.ui._write_letter("  ") # ADDS SPACE
	anim_player.set_current_animation("name_submit")
	anim_player.play()


func _on_open_flap() -> void:
	if not flap_open:
		flap_open_sfx.play()
		flap.set_animation("open")
		flap.play()
		await flap.animation_finished
		flap_open = true


func _on_close_flap() -> void:
	if flap_open:
		flap_close_sfx.play()
		flap.set_animation("open")
		flap.play_backwards()
		await flap.animation_finished
		flap_open = false
		if not Global.main.game_started and Global.main.game_over:
			var sw_result: Dictionary = await SilentWolf.Scores.get_scores(10).sw_get_scores_complete
			var player_list_with_pos = Global.leaderboard.sort_players_and_add_position(SilentWolf.Scores.scores)
			var bottom_leaderboard_player
			if player_list_with_pos.size() >= 10:
				bottom_leaderboard_player = player_list_with_pos[9]
			elif player_list_with_pos.size() > 0:
				bottom_leaderboard_player = player_list_with_pos[player_list_with_pos.size() - 1]
			if player_list_with_pos.size() < 10 or (Global.main.score > bottom_leaderboard_player["score"]):
				_generate_name_submit_vending_machine()
			else:
				_generate_menu_vending_machine()


func _on_shoot() -> void:
	if not shoot:
		shoot = true
		gun_cock_sfx.play()
		flap.set_animation("shoot")
		flap.play()
		await flap.animation_finished
		await gun_cock_sfx.finished
		gun_shot_sfx.play()
		muzzle_flash.show()
		blood.show()
		Global.main.shake_timer.set_wait_time(0.25)
		Global.main.shake_timer.start(0.25)
		await get_tree().create_timer(0.05).timeout
		muzzle_flash.hide()
		await gun_shot_sfx.finished
		_on_dont_shoot()


func _on_dont_shoot() -> void:
	if shoot:
		shoot = false
		gun_holster_sfx.play()
		flap.set_animation("shoot")
		flap.play_backwards()
		await flap.animation_finished
		_on_close_flap()


func toggle_lamp(on : bool) -> void:
	if on:
		light.show()
		darkness.hide()
	else:
		light.hide()
		darkness.show()
		blood.hide()

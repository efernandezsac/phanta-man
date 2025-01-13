extends CanvasLayer

@onready var main_options = $MarginContainer/PanelContainer/MarginContainer/MainContainer
@onready var quit_confirm = $MarginContainer/PanelContainer/MarginContainer/QuitContainer
@onready var reset_confirm = $MarginContainer/PanelContainer/MarginContainer/ResetContainer

func _ready() -> void:
	# Inicializa focus en ResumeButton
	$MarginContainer/PanelContainer/MarginContainer/MainContainer/ResumeButton.grab_focus()
	# Hide QuitContainer and ResetContainer
	quit_confirm.hide()
	reset_confirm.hide()
	
func resume():
	get_tree().paused = false
	$AnimationPlayer.play_backwards("pause_menu_on")
	queue_free()

func _input(event):
	if Input.is_action_just_pressed("return_to_main_menu"):
		get_viewport().set_input_as_handled() # Evitar propagación
		if quit_confirm.visible:
			show_main_options()
		else:
			resume()

func show_main_options():
	main_options.show()
	reset_confirm.hide()
	quit_confirm.hide()
	# Devolver focus a ResumeButton
	$MarginContainer/PanelContainer/MarginContainer/MainContainer/ResumeButton.grab_focus()

func show_reset_options():
	main_options.hide()
	reset_confirm.show()
	quit_confirm.hide()
	# Devolver focus a BackButton
	$"MarginContainer/PanelContainer/MarginContainer/ResetContainer/BackButton".grab_focus()

func show_quit_confirm():
	main_options.hide()
	reset_confirm.hide()
	quit_confirm.show()
	# Dar focus a NoButton
	$MarginContainer/PanelContainer/MarginContainer/QuitContainer/NoButton.grab_focus()

# ======== MainContainer Buttons
func _on_resume_button_pressed() -> void:
	resume()

func _on_reset_button_pressed() -> void:
	show_reset_options()

func _on_quit_button_pressed() -> void:
	show_quit_confirm()
	
	
# ======== #QuitContainer Buttons
func _on_no_button_pressed() -> void:
	show_main_options()

func _on_yes_button_pressed() -> void:
	Global.last_checkpoint_position = Vector2(-100,-100)
	get_tree().change_scene_to_file("res://Scenes/Levels/main_menu.tscn")
	resume()

# ======== # ResetContainer Buttons

func _on_reset_checkpoint_button_pressed() -> void:
	get_tree().reload_current_scene.call_deferred()
	resume()

func _on_reset_level_button_pressed() -> void:
	Global.last_checkpoint_position = Vector2(-100,-100)
	get_tree().reload_current_scene.call_deferred()
	resume()

func _on_back_button_pressed() -> void:
	show_main_options()

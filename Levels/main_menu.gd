extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Inicializa focus en StartButton
	$Options/StartButton.grab_focus()
	
	# Conecta las señales necesarias para cada botón
	for button in $Options.get_children():
		if button is Button:
			button.connect("focus_entered", Callable(self, "_on_button_hovered"))
			button.connect("mouse_entered", Callable(self, "_on_button_hovered"))
			button.connect("pressed", Callable(self, "_on_button_pressed"))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
#	if Input.is_action_just_pressed("confirm"):
#		get_tree().change_scene_to_file("res://Levels/level_1.tscn")

# Play HoverSound
func _on_button_hovered() -> void:
	$HoverSound.play()
# Play PressSound

func _on_button_pressed() -> void:
	$PressSound.play()

# Start Button
func _on_start_button_pressed() -> void:
	_on_button_pressed()  # Reproducir el sonido
	get_tree().call_deferred("change_scene_to_file", "res://Levels/level_1.tscn")

# Fullscreen Button
func _on_fullscreen_button_pressed() -> void:
	_on_button_pressed()
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	elif DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

# Quit Button
func _on_quit_button_pressed() -> void:
	_on_button_pressed()
	get_tree().quit()

extends CanvasLayer

@onready var title_node = $Title
@onready var title_moved_node = $TitleMoved

@onready var hover_sound = $Sounds/HoverSound
@onready var press_sound = $Sounds/PressSound

func _ready() -> void:
	title_moved_node.hide()
	$Options.hide()
	$AnimationPlayer.play("logo_intro")
	await $AnimationPlayer.animation_finished
	title_node.hide() # Ocultar el nodo Title
	title_moved_node.show() # Mostrar el nodo TitleMoved
	$AnimationPlayer.play("move_title")
	await $AnimationPlayer.animation_finished
	$ColorRect.queue_free()
	$Options.show()
	
	# Inicializa focus en StartButton
	$Options/StartButton.grab_focus()
	
	# Conecta las señales necesarias para cada botón
	for button in $Options.get_children():
		if button is Button:
			button.connect("focus_entered", Callable(self, "_on_button_hovered"))
			button.connect("mouse_entered", Callable(self, "_on_button_hovered"))
			button.connect("pressed", Callable(self, "_on_button_pressed"))

# Play HoverSound
func _on_button_hovered() -> void:
	hover_sound.play()
	
# Play PressSound
func _on_button_pressed() -> void:
	press_sound.play()

# Start Button
func _on_start_button_pressed() -> void:
	_on_button_pressed()  # Reproducir sonido
	get_tree().call_deferred("change_scene_to_file", "res://Scenes/Levels/level_selector.tscn")

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

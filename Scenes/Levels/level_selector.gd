extends CanvasLayer

# Screenshot display
@onready var level_screenshot: Sprite2D = $LevelScreenshot

# Sounds
@onready var level_selector_music = $Sounds/LevelSelectorMusic
@onready var hover_sound = $Sounds/HoverSound
@onready var press_sound = $Sounds/PressSound
@onready var time_sound = $Sounds/TimeLabelSfx

@onready var option_ending_container = $OptionsEnding
@onready var level3_label = $OptionsEnding/Label
@onready var level3_button = $OptionsEnding/Level3Button
@onready var credits_label = $OptionsEnding/Label2
@onready var credits_button = $OptionsEnding/CreditsButton


# Animation Player
@onready var animation_player = $AnimationPlayer

# Dictionary to map buttons to their respective screenshot textures
var level_textures = {}

# Random string
var random_text = ""

func _ready() -> void:
	level_selector_music.play()
	# Initialize the dictionary mapping buttons to their textures after the scene is ready
	level_textures = {
		$Options/Level1Button: preload("res://assets/images/ui/screenshots/screenshot_level1.png"),
		$Options/Level1BossButton: preload("res://assets/images/ui/screenshots/screenshot_level2.png"),
		$Options/Level2Button: preload("res://assets/images/ui/screenshots/screenshot_level3.png"),
		$Options/Level2BossButton: preload("res://assets/images/ui/screenshots/screenshot_level4.png"),
		$OptionsEnding/Level3Button: preload("res://assets/images/ui/screenshots/screenshot_level5.png"),
		$OptionsEnding/CreditsButton: preload("res://assets/images/ui/screenshots/screenshot_level6.png")
	}
	# Focus a ResumeButton
	$Options/Level1Button.grab_focus() 
	
	# First Level Screenshot in
	animation_player.play("move_selection")
	
	# Get and display the current date
	var date = Time.get_date_dict_from_system()
	$DateLabel.text = "%04d/%02d/%02d" % [date.year, date.month, date.day]
	
	# Generate Random Text
	random_text = generate_random_text()
	
	# Conecta las señales necesarias para cada botón
	for button in $Options.get_children():
		if button is Button:
			button.connect("focus_entered", Callable(self, "_on_button_hovered"))
			button.connect("mouse_entered", Callable(self, "_on_button_hovered"))
			button.connect("pressed", Callable(self, "_on_button_pressed"))
		
	# Connect signals for button focus
	$Options/Level1Button.focus_entered.connect(_on_button_focus_entered.bind($Options/Level1Button))
	$Options/Level1Button.focus_exited.connect(_on_button_focus_exited.bind($Options/Level1Button))
	$Options/Level1BossButton.focus_entered.connect(_on_button_focus_entered.bind($Options/Level1BossButton))
	$Options/Level1BossButton.focus_exited.connect(_on_button_focus_exited.bind($Options/Level1BossButton))
	$Options/Level2Button.focus_entered.connect(_on_button_focus_entered.bind($Options/Level2Button))
	$Options/Level2Button.focus_exited.connect(_on_button_focus_exited.bind($Options/Level2Button))
	$Options/Level2BossButton.focus_entered.connect(_on_button_focus_entered.bind($Options/Level2BossButton))
	$Options/Level2BossButton.focus_exited.connect(_on_button_focus_exited.bind($Options/Level2BossButton))
	$OptionsEnding/Level3Button.focus_entered.connect(_on_button_focus_entered.bind($OptionsEnding/Level3Button))
	$OptionsEnding/Level3Button.focus_exited.connect(_on_button_focus_exited.bind($OptionsEnding/Level3Button))
	$OptionsEnding/CreditsButton.focus_entered.connect(_on_button_focus_entered.bind($OptionsEnding/CreditsButton))
	$OptionsEnding/CreditsButton.focus_exited.connect(_on_button_focus_exited.bind($OptionsEnding/CreditsButton))

	# Ocultar de inicio OptionsEnding
	option_ending_container.visible = false
	
	# Update button visibility based on conditions
	_update_button_visibility()

func _update_button_visibility():
		if Global.Boss1_defeated && Global.Boss2_defeated:
				option_ending_container.visible = true
				level3_button.visible = true
				level3_label.visible = true
		else:
				level3_button.visible = false
				level3_label.visible = false
				credits_button.visible = false
				credits_label.visible = false
				return  # Exit early if Level 3 is not available

		if Global.Boss3_defeated:
				credits_button.visible = true
				credits_label.visible = true
		else:
				credits_button.visible = false
				credits_label.visible = false


# Play HoverSound
func _on_button_hovered() -> void:
	hover_sound.play()


# Play PressSound
func _on_button_pressed() -> void:
	press_sound.play()


func _on_button_focus_entered(button):
	print("Focus entered on:", button.name)
	if level_textures.has(button):
		level_screenshot.texture = level_textures[button]
		level_screenshot.visible = true
	
	# Play the move_selection animation
	animation_player.play("move_selection")


func _on_button_focus_exited(button):
		print("Focus exited on:", button.name)
		level_screenshot.visible = false


func _input(event):
		if event.is_action_pressed("return_to_main_menu"):
				get_tree().change_scene_to_file("res://Scenes/Levels/main_menu.tscn")
		
		if option_ending_container.visible:
			if Global.Boss1_defeated && Global.Boss2_defeated:
				if event.is_action_pressed("ui_left"):
					$Options/Level1Button.grab_focus() 
				if event.is_action_pressed("ui_right"):
					level3_button.grab_focus()


# Udates the time label
func _on_timer_timeout() -> void:
		var time = Time.get_time_dict_from_system()
		$TimeLabel.text = "%02d\n:\n%02d\n:\n%02d" % [time.hour, time.minute, time.second]
		time_sound.play()


func generate_random_text():
		var text = ""
		for i in range(30):
				var char_type = randi() % 2
				if char_type == 0:
						var case_type = randi() % 2
						if case_type == 0:
								text += char(65 + randi() % 26) # Letra mayúscula
						else:
								text += char(97 + randi() % 26) # Letra minúscula
				else:
						text += str(randi() % 10) # Número
		return text


# Called when the fast timer times out (updates the random label)
func _on_timer_fast_timeout() -> void:
	random_text = generate_random_text()
	$RandomLabel.text = random_text


# --- Button Press Handlers ---

func _on_level_1_button_pressed() -> void:
		await get_tree().create_timer(press_sound.stream.get_length()).timeout
		get_tree().change_scene_to_file("res://Scenes/Levels/level_1.tscn")

func _on_level_1_boss_button_pressed() -> void:
		await get_tree().create_timer(press_sound.stream.get_length()).timeout
		get_tree().change_scene_to_file("res://Scenes/Levels/level_1_boss.tscn")

func _on_level_2_button_pressed() -> void:
		await get_tree().create_timer(press_sound.stream.get_length()).timeout
		get_tree().change_scene_to_file("res://Scenes/Levels/level_2.tscn")

func _on_level_2_boss_button_pressed() -> void:
		await get_tree().create_timer(press_sound.stream.get_length()).timeout
		get_tree().change_scene_to_file("res://Scenes/Levels/level_2_boss.tscn")


func _on_level_3_button_pressed() -> void:
		await get_tree().create_timer(press_sound.stream.get_length()).timeout
		get_tree().change_scene_to_file("res://Scenes/Levels/level_3_boss.tscn")


func _on_credits_button_pressed() -> void:
		await get_tree().create_timer(press_sound.stream.get_length()).timeout
		get_tree().change_scene_to_file("res://Scenes/Levels/credits.tscn")

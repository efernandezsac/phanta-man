extends Node2D #Funciona

var pause_menu_screen = preload("res://Scenes/UI/pause_menu_screen.tscn")
var level_start_manager_scene = preload("res://Scenes/UI/level_start.tscn")

@export var level_num = 0
@export var level_start_music = preload("res://assets/audio/bgm/LevelStart.wav")
@onready var player = get_tree().get_nodes_in_group("Player")[0] # Asegúrate de que tu jugador esté en un grupo llamado "Player"
@onready var initial_player_position = player.global_position # Guarda la posición inicial del jugador

# Dictionary to map level numbers to their respective background music files
var level_bgm = {
		1: preload("res://assets/audio/bgm/Level1.wav"),
		2: preload("res://assets/audio/bgm/BossBattle.mp3"),
		3: preload("res://assets/audio/bgm/Level2.wav"),
		4: preload("res://assets/audio/bgm/BossBattle.mp3"),
		5: preload("res://assets/audio/bgm/BossBattle.mp3"),
		6: preload("res://assets/audio/bgm/credits.mp3")
		# Add more levels and their music files here
}

@onready var bgm_player = AudioStreamPlayer.new()

func _ready() -> void:
		# Configuración inicial del nivel
		Global.current_health = Global.max_health
		$HUD.level(level_num)
		print("Level " + str(level_num) + " ready")
		set_coins_label()
		for coin in $Coins.get_children():
				coin.coin_collected.connect(_on_coin_collected)

		# Add the background music player as child
		add_child(bgm_player)

		# Instanciar la escena de inicio del nivel
		call_deferred("_setup_level_start")
		# Play the level-specific background music
		if level_bgm.has(level_num):
				bgm_player.stream = level_bgm[level_num]
				bgm_player.play()

		# Posiciona al jugador al inicio o en el último checkpoint
		if Global.last_checkpoint_position != Vector2(-100, -100):
				player.global_position = Global.last_checkpoint_position
		else:
				player.global_position = initial_player_position


func _setup_level_start() -> void:
		var level_start_manager_instance = level_start_manager_scene.instantiate()
		level_start_manager_instance.level_start_music = level_start_music
		add_child(level_start_manager_instance)


func _on_coin_collected() -> void:
		$HUD/CoinsLabel.text = str(Global.coins_collected)

func set_coins_label():
		$HUD.coins(Global.coins_collected)

# Called when a bullet is destroyed
func _on_bullet_destroyed():
		pass

func _on_door_player_entered(level) -> void:
		get_tree().call_deferred("change_scene_to_file", level)

func _input(event):
		if event.is_action_pressed("reset_level"):
				reset_level()

		# Solo permitir abrir el menú de pausa si el juego no está en el estado de pausa inicial
		if event.is_action_pressed("return_to_main_menu") and not get_tree().paused:
				get_tree().paused = true
				var pause_menu_screen_instance = pause_menu_screen.instantiate()
				get_tree().get_root().add_child(pause_menu_screen_instance)

func reset_level():
		get_tree().reload_current_scene.call_deferred()
		Global.coins_collected = 0
		Global.current_health = Global.max_health
		set_coins_label()
		# Restablece la posición del jugador al último checkpoint o al inicio
		if Global.last_checkpoint_position != Vector2(-100, -100):
				player.global_position = Global.last_checkpoint_position
		else:
				player.global_position = initial_player_position

func _on_door_1_to_2_player_entered(level: Variant) -> void:
	get_tree().change_scene_to_file("res://Scenes/Levels/level_1_boss.tscn")

func _on_boss_defeated():
		print("¡Felicidades! ¡Has derrotado al jefe!")
		
		if level_num == 2:
			Global.Boss1_defeated = true
		if level_num == 4:
			Global.Boss2_defeated = true
		if level_num == 5:
			Global.Boss3_defeated = true
			
		# Detener la música de fondo
		bgm_player.stop()

		# Reproducir el sonido de fanfarria
		var victory_sound_stream = preload("res://assets/audio/bgm/Victory.wav")
		var victory_sound_player = AudioStreamPlayer.new()
		victory_sound_player.stream = victory_sound_stream
		add_child(victory_sound_player)
		victory_sound_player.play()

		# Animar al jugador
		player.get_node("AnimationPlayer").play("spawn")

		# **Aplicar ralentización aquí DESPUÉS de iniciar la música**
		var slow_motion_factor = 0.3 # Ajusta este valor para la intensidad de la ralentización (0.01 es muy lento, 0.5 es la mitad de la velocidad normal)
		Engine.time_scale = slow_motion_factor

		# Iniciar el temporizador para cambiar de escena
		await get_tree().create_timer(1.5).timeout

		# Restablecer la escala de tiempo a la normalidad antes de cambiar de escena (importante)
		Engine.time_scale = 1.0

		# Volver al selector de niveles
		_go_to_level_selector()

		# Liberar el reproductor de sonido después de que termine el temporizador (opcional)
		victory_sound_player.queue_free()
		
func _go_to_level_selector():
	# Asumiendo que tienes una escena para el selector de niveles
	if Global.Boss1_defeated == true && Global.Boss2_defeated == true && Global.Boss3_defeated == true:
		get_tree().call_deferred("change_scene_to_file", "res://Scenes/Levels/credits.tscn")
	elif Global.Boss1_defeated == true && Global.Boss2_defeated == true:
		get_tree().call_deferred("change_scene_to_file", "res://Scenes/Levels/level_3_boss.tscn")
	else:
		get_tree().call_deferred("change_scene_to_file", "res://Scenes/Levels/level_selector.tscn")

func _on_boss_ship_level_won() -> void:
	_on_boss_defeated()

func end_credits(level: Variant) -> void:
	print("FIN")
	get_tree().change_scene_to_file("res://Scenes/Levels/intro.tscn")

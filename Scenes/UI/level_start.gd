extends Node2D

@export var level_start_music : AudioStream
@onready var intro_music_player = $LevelStartMusic

func _ready() -> void:
		# Configurar el audio
		intro_music_player.stream = level_start_music
		intro_music_player.play()

		# Pausar el juego, pero permitir que la música siga sonando
		get_tree().paused = true
		process_mode = Node.PROCESS_MODE_ALWAYS  # Permite que este nodo siga funcionando durante la pausa

		# Conectar la señal finished
		intro_music_player.finished.connect(_on_intro_music_finished)

func _on_intro_music_finished() -> void:
		# Despausar el juego cuando termina la música de inicio
		_release_level()

func _input(event):
		if event.is_action_pressed("confirm"):
				_skip_intro()

func _skip_intro():
		# Detener la música si está sonando
		if intro_music_player.playing:
				intro_music_player.stop()

		# Desconectar la señal para evitar que se llame _on_intro_music_finished
		intro_music_player.finished.disconnect(_on_intro_music_finished)

		# Liberar el nivel
		_release_level()

func _release_level():
		# Despausar el juego
		get_tree().paused = false
		# Eliminar la escena de la música de inicio
		queue_free()

extends Area2D

@export var lines: Array[String] = []
@export var is_forced_dialog = false
@onready var speech_sound = preload("res://assets/audio/sfx/HoverSound.wav")

var player_in_area = false
var can_start_dialog = true

# Variables para la animación de flotación
var initial_y: float
var float_speed: float = 2  # Velocidad de flotación
var float_amplitude: float = 8.0  # Amplitud de la flotación
var time_offset: float = randf() * 100 # Offset de tiempo para que no todos floten al mismo tiempo

# Area2D para el rango de interacción
@onready var range_area = $RangeArea

func _ready() -> void:
	DialogManager.dialog_ended.connect(_on_dialog_ended) # Conectar la señal
	initial_y = position.y  # Guardar la posición inicial en Y
 
func _process(delta: float) -> void:
	# Animación de flotación
	position.y = initial_y + sin((Time.get_ticks_msec() / 1000.0 * float_speed) + time_offset) * float_amplitude
		
	if (
		player_in_area &&
		Input.is_action_pressed("advance_dialog") &&
		!DialogManager.is_dialog_active &&
		can_start_dialog
	):
		print("Pulsaste E para iniciar diálogo.")
		start_dialog()

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		print("Player in DialogArea")
		player_in_area = true
		if is_forced_dialog && can_start_dialog && !DialogManager.is_dialog_active:
			start_dialog()

func _on_body_exited(body: Node2D) -> void:
	print("Saliste del area para activar diálogo")
	if body.name == "Player":
		player_in_area = false

func start_dialog():
	print("Iniciando diálogo...")
	DialogManager.start_dialog(global_position, lines, speech_sound)
	can_start_dialog = false
	
func _on_dialog_ended():
	print("señal te dice que dialog fin")

	
	# Crear un timer para el delay
	if get_tree():
		print("HAY TREEEEEEEEEEEEEEE")
		var timer = get_tree().create_timer(0.2)
		timer.timeout.connect(func(): can_start_dialog = true)

func _on_range_area_body_exited(body: Node2D) -> void:
	print("saliste del rango de diálogo")
	if body.name == "Player":
		if DialogManager.is_dialog_active:
				DialogManager.end_dialog()
		#Reiniciar can_start_dialog si el jugador sale del rango
		can_start_dialog = true

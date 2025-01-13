extends CanvasLayer

var level_timer: Timer
var display_timer: Timer # Nuevo temporizador para mostrar el texto

func _ready():
	level_timer = Timer.new()
	add_child(level_timer)
	level_timer.one_shot = true

	display_timer = Timer.new() # Inicializar el nuevo temporizador
	add_child(display_timer)
	display_timer.one_shot = true
	display_timer.autostart = false # No iniciar automáticamente

func level(num):
	$CurrentLevel.text = "" # Aseguramos que esté vacío al inicio
	display_timer.wait_time = 1
	display_timer.stop()
	display_timer.start()
	display_timer.timeout.connect(_on_display_timer_timeout.bind(num)) # Conectar con el número de nivel

func _on_display_timer_timeout(level_num):
	match level_num:
		1:
			$CurrentLevel.text = "Planet Zezenia"
		2:
			$CurrentLevel.text = "Planet Zezenia"
		3:
			$CurrentLevel.text = "Oligo-freniks Laboratories"
		4:
			$CurrentLevel.text = "Lineal City"

			

	level_timer.wait_time = 4 # 4 segundos después del delay de 1 segundo
	level_timer.stop()
	level_timer.start()
	level_timer.timeout.connect(_on_level_timer_timeout)

func _on_level_timer_timeout():
	$CurrentLevel.text = ""

func coins(num):
	$CoinsLabel.text = str(num)

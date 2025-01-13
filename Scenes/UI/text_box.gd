extends MarginContainer

@onready var label = $MarginContainer/Label
@onready var timer = $LetterDisplayTimer
@onready var audio_player = $AudioStreamPlayer

const MAX_WIDTH = 256

var text = ""
var letter_index = 0

var letter_time = 0.03
var space_time = 0.06
var punctuation_time = 0.2

signal finished_displaying()

func display_text(text_to_display: String, speech_sfx: AudioStream):
	text = text_to_display
	label.text = text_to_display
	audio_player.stream = speech_sfx # Asigna el sonido al AudioStreamPlayer existente
	
	await resized
	custom_minimum_size.x = min(size.x, MAX_WIDTH)
	
	if size.x > MAX_WIDTH:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		await resized # await for x resize
		custom_minimum_size.y = size.y
		
	global_position.x -= size.x /2
	global_position.y -= size.y + 24
	
	label.text = ""
	letter_index = 0 # Reinicia el índice aquí
	_display_letter()

func _display_letter():
	if letter_index < text.length():
		label.text += text[letter_index]
		
		# Reproduce el sonido con variaciones
		audio_player.pitch_scale = 1.0 + randf_range(-0.1, 0.1)
		if text[letter_index] in ["a", "e", "i", "o", "u"]:
			audio_player.pitch_scale += 0.2
		audio_player.play() # Reproduce el sonido inmediatamente

		letter_index += 1
		
		match text[letter_index -1 if letter_index > 0 else 0]: # Comprueba la letra actual, no la siguiente
			"!", ".", ",", "?":
				timer.start(punctuation_time)
			" ":
				timer.start(space_time)
			_:
				timer.start(letter_time)
	else:
		finished_displaying.emit()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_letter_display_timer_timeout() -> void:
	_display_letter()

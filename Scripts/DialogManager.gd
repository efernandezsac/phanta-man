extends Node

@onready var text_box_scene = preload("res://Scenes/UI/text_box.tscn")
@onready var auto_advance_timer = Timer.new() # Creamos un nuevo Timer

var dialog_lines: Array[String] = []
var current_line_index = 0

var text_box
var text_box_position: Vector2

var is_dialog_active = false
var can_advance_line = false
var auto_advance = false  # Nueva variable para controlar el avance automático
@export var auto_advance_delay = 1.5 # Tiempo de espera para el avance automático

var sfx: AudioStream

signal dialog_ended

func _ready():
	add_child(auto_advance_timer)
	auto_advance_timer.timeout.connect(_on_auto_advance_timer_timeout)

func start_dialog(position: Vector2, lines: Array[String], speech_sfx: AudioStream, auto_advance_dialog: bool = false):
	if is_dialog_active:
		return
	
	dialog_lines = lines
	text_box_position = position
	sfx = speech_sfx
	auto_advance = auto_advance_dialog # Establecer el modo de avance
	_show_text_box()
	
	is_dialog_active = true
	can_advance_line = false # No se puede avanzar hasta que se muestre el texto
	if auto_advance:
		auto_advance_timer.start(auto_advance_delay)
	
func _show_text_box():
	if current_line_index >= dialog_lines.size():
		end_dialog()
		return
		
	text_box = text_box_scene.instantiate()
	text_box.finished_displaying.connect(_on_text_box_finished_displaying)
	get_tree().root.add_child(text_box)
	text_box.global_position = text_box_position
	text_box.display_text(dialog_lines[current_line_index], sfx)


func _on_text_box_finished_displaying():
	can_advance_line = true
	if auto_advance:
		auto_advance_timer.start(auto_advance_delay)
		
func _on_auto_advance_timer_timeout():
	if is_dialog_active and auto_advance:
		_advance_dialog_line()
	
func _unhandled_input(event):
	if (
		Input.is_action_pressed("advance_dialog") &&
		is_dialog_active &&
		can_advance_line &&
		not auto_advance # Solo permitir el avance manual si no es automático
	):
		_advance_dialog_line()
		
func _advance_dialog_line():
	if text_box:
		text_box.queue_free()
				
	current_line_index +=1
	if current_line_index >= dialog_lines.size():
		end_dialog() # Usamos end_dialog() para simplificar
		return
	
	_show_text_box()
	can_advance_line = false # No se puede avanzar hasta que se muestre el texto

func end_dialog():
	if is_dialog_active:
		if text_box:
			text_box.queue_free()
		is_dialog_active = false
		current_line_index = 0
		can_advance_line = false
		auto_advance = false
		auto_advance_timer.stop()
		emit_signal("dialog_ended")

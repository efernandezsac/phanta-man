"""
# spikes_row.gd
extends Node2D

@export var spike_scene : PackedScene # Asigna la escena Spikes aquí
@export var num_spikes : int = 5 # Número de pinchos en la fila
@export var spacing : float = 32.0 # Espacio entre pinchos
@export var time_switch : float = 0.5 # Tiempo de switch para todos los pinchos

func _ready():
	for i in num_spikes:
		var spike_instance = spike_scene.instantiate()
		add_child(spike_instance)
		spike_instance.position.x = i * spacing
		# Modifica el timer.wait_time después de instanciar
		spike_instance.timer.wait_time = time_switch
"""
# spikes_row.gd
@tool
extends Node2D

@export var num_spikes : int = 1 # Número de pinchos en la fila
@export var spacing : float = 15.0 # Espacio entre pinchos
@export var time_on : float = 0.5 # Tiempo de encendido para todos los pinchos
@export var time_off : float = 0.5 # Tiempo de apagado para todos los pinchos

var _editor_spikes : Array[Node2D] = [] # Almacena los pinchos creados en el editor
var spike_scene : PackedScene = load("res://Scenes/Enviroment/spikes.tscn") # Carga la escena directamente

func _ready():
	for i in num_spikes:
		var spike_instance = spike_scene.instantiate()
		add_child(spike_instance)
		spike_instance.position.x = i * spacing
		spike_instance.time_on = time_on
		spike_instance.time_off = time_off
		spike_instance.timer.wait_time = time_on # Inicializa el timer con el tiempo de encendido

func _update_editor_spikes():
	# Eliminar los pinchos anteriores
	for spike in _editor_spikes:
		spike.queue_free()
	_editor_spikes.clear()

	for i in num_spikes:
		var spike_instance = spike_scene.instantiate()
		add_child(spike_instance)
		spike_instance.position.x = i * spacing
		_editor_spikes.append(spike_instance)

func _process(delta):
	if Engine.is_editor_hint():
		_update_editor_spikes()

func _on_property_changed(_property):
	if Engine.is_editor_hint():
		_update_editor_spikes()

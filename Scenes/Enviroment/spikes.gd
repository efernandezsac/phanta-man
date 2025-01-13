"""# spikes.gd
extends Node2D

@export var time_switch : float = 0.5 # Tiempo en segundos entre cambios de textura
@export var textura_on: Texture2D
@export var textura_off: Texture2D
@export var damage_amount : int = 3

@onready var sprite: Sprite2D = $Sprite2D
@onready var area: Area2D = $Area2D
@onready var collision: CollisionShape2D = $Area2D/CollisionShape2D
@onready var timer: Timer = $Timer

func _ready():
	timer.wait_time = time_switch
	timer.autostart = true
	collision.disabled = true # Inicia con la colisión desactivada

func _on_timer_timeout():
	if sprite.texture == textura_on:
		sprite.texture = textura_off
		collision.disabled = true # Desactiva la colisión
	else:
		sprite.texture = textura_on
		collision.disabled = false # Activa la colisión
"""
# spikes.gd
extends Node2D

@export var time_on : float = 0.5 # Tiempo en segundos que los pinchos están activos
@export var time_off : float = 0.5 # Tiempo en segundos que los pinchos están inactivos
@export var textura_on: Texture2D
@export var textura_off: Texture2D
@export var damage_amount : int = 1

@onready var sprite: Sprite2D = $Sprite2D
@onready var area: Area2D = $Area2D
@onready var collision: CollisionShape2D = $Area2D/CollisionShape2D
@onready var timer: Timer = $Timer

var is_on : bool = false # Variable para saber si los pinchos están activos

func _ready():
	timer.autostart = true
	collision.disabled = true # Inicia con la colisión desactivada
	_set_timer() # Inicializa el timer

func _set_timer():
	if is_on:
		timer.wait_time = time_on
	else:
		timer.wait_time = time_off
	timer.start()

func _on_timer_timeout():
	is_on = not is_on # Cambia el estado de los pinchos
	if is_on:
		sprite.texture = textura_on
		collision.disabled = false # Activa la colisión
	else:
		sprite.texture = textura_off
		collision.disabled = true # Desactiva la colisión
	_set_timer() # Reinicia el timer con el tiempo correcto

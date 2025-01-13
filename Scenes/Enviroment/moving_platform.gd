extends CharacterBody2D

@export var move_speed: float = 100.0
@export var can_move_horizontally: bool = true
@export var can_move_vertically: bool = false
@export var num_middle_platforms: int = 1

@onready var middle_base = $Middle
@onready var left_light = $LeftLight
@onready var right_light = $RightLight
@onready var collision_shape = $CollisionShape2D
@onready var left_area = $LeftArea
@onready var right_area = $RightArea
@onready var top_area = $TopArea
@onready var bottom_area = $BottomArea
@onready var collision_top = $TopArea/CollisionTop
@onready var collision_bottom = $BottomArea/CollisionBottom


# Variables locales para cada plataforma
var horizontal_direction: int = 1
var vertical_direction: int = 1

# Variables para guardar las formas de colisión originales
var original_top_shape: RectangleShape2D
var original_bottom_shape: RectangleShape2D


func _ready():
	print("Plataforma: ", name, " _ready() ejecutado")
	
	# Guardar las formas de colisión originales
	original_top_shape = collision_top.shape.duplicate()
	original_bottom_shape = collision_bottom.shape.duplicate()

	
	_setup_platform()
	_update_area_widths()
	_update_area_positions()

func _physics_process(delta):
	var velocity = Vector2.ZERO

	if can_move_horizontally:
					velocity.x = horizontal_direction * move_speed

	if can_move_vertically:
					velocity.y = vertical_direction * move_speed

	velocity *= delta
	move_and_collide(velocity)

func _setup_platform():
	# Aseguramos que haya al menos un Middle
	num_middle_platforms = max(1, num_middle_platforms)

	# Guardamos el ancho del Middle y de las luces
	var middle_width = middle_base.texture.get_width()
	var left_light_width = left_light.sprite_frames.get_frame_texture("default", 0).get_width()
	var right_light_width = right_light.sprite_frames.get_frame_texture("default", 0).get_width()

	# Calculamos el ancho total de la plataforma
	var total_platform_width = left_light_width + (num_middle_platforms * middle_width) + right_light_width

	# Calculamos el desplazamiento necesario para centrar la plataforma
	var platform_offset = -total_platform_width / 2.0

	# Posicionamos el Middle base (el primero) centrado
	middle_base.position.x = platform_offset + left_light_width + middle_width / 2.0

	# Eliminamos los Middle adicionales existentes
	for child in get_children():
					if child != middle_base and child.name.begins_with("Middle_"):
									child.queue_free()

	# Creamos y posicionamos los Middle adicionales
	for i in range(1, num_middle_platforms):
					var new_middle = Sprite2D.new()
					new_middle.texture = middle_base.texture
					new_middle.name = "Middle_" + str(i)
					new_middle.position.x = platform_offset + left_light_width + middle_width / 2.0 + i * middle_width
					add_child(new_middle)

	# Posicionamos las luces
	left_light.position.x = platform_offset + left_light_width / 2.0
	right_light.position.x = platform_offset + left_light_width + (num_middle_platforms * middle_width) + right_light_width / 2.0

	# Ajustamos el CollisionShape2D
	var new_platform_shape = CapsuleShape2D.new()
	new_platform_shape.height = total_platform_width
	new_platform_shape.radius = 8 # Valor por defecto
	collision_shape.shape = new_platform_shape
	collision_shape.position.x = 0.0  # Centramos la colisión horizontalmente
	collision_shape.position.y = 0.0  # El centro vertical se mantiene en 0

	# Reordenamos los nodos para mantener la jerarquía deseada (opcional)
	move_child(left_light, 0)
	move_child(middle_base, 1)
	for i in range(num_middle_platforms - 1):
					var middle_node = get_node("Middle_" + str(i))
					if middle_node:
									move_child(middle_node, i + 2)
	move_child(right_light, get_child_count() - 1)
	move_child(collision_shape, get_child_count())

func _update_area_widths():
	# Optimización: obtener las referencias solo una vez
	var middle_width = middle_base.texture.get_width()
	var left_light_width = left_light.sprite_frames.get_frame_texture("default", 0).get_width()
	var right_light_width = right_light.sprite_frames.get_frame_texture("default", 0).get_width()
	var platform_width = left_light_width + (num_middle_platforms * middle_width) + right_light_width
	var central_platform_width = middle_width * num_middle_platforms

	# Reconstruir las formas de colisión (top y bottom)
	var new_top_shape = original_top_shape.duplicate()
	new_top_shape.size.x = platform_width
	collision_top.shape = new_top_shape

	var new_bottom_shape = original_bottom_shape.duplicate()
	new_bottom_shape.size.x = platform_width
	collision_bottom.shape = new_bottom_shape

	# Centrar las colisiones horizontalmente
	collision_top.position.x = 0
	collision_bottom.position.x = 0

	# Posicionar las áreas verticalmente (optimizado)
	var half_platform_height = middle_base.texture.get_height() / 2.0
	top_area.position.y = -half_platform_height - collision_top.shape.size.y / 2
	bottom_area.position.y = half_platform_height + collision_bottom.shape.size.y / 2


func _update_area_positions():
	var left_light = $LeftLight
	var right_light = $RightLight
	var left_area = $LeftArea
	var right_area = $RightArea
	
	var left_light_width = left_light.sprite_frames.get_frame_texture("default", 0).get_width()
	var right_light_width = right_light.sprite_frames.get_frame_texture("default", 0).get_width()
	
	# Ajustar la posición de las áreas laterales
	left_area.position.x = left_light.position.x
	right_area.position.x = right_light.position.x
	
	queue_redraw()

func _on_left_area_body_entered(body: Node2D) -> void:
	if can_move_horizontally:
		horizontal_direction = 1 # Invertir la dirección directamente

func _on_right_area_body_entered(body: Node2D) -> void:
	if can_move_horizontally:
		horizontal_direction = -1 # Invertir la dirección directamente

func _on_top_area_body_entered(body: Node2D) -> void:
	if can_move_vertically:
		vertical_direction = 1 # Invertir la dirección directamente

func _on_bottom_area_body_entered(body: Node2D) -> void:
	if can_move_vertically:
		vertical_direction = -1 # Invertir la dirección directamente

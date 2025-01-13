extends Node2D

@export var lifecube_full: Texture2D
@export var lifecube_empty: Texture2D

@onready var lifecubes = [$LifeCube1, $LifeCube2, $LifeCube3]
var last_life_tween: Tween
var shake_tween: Tween
var original_first_cube_position: Vector2  # Variable para guardar la posición original del primer cubo

func _ready() -> void:
	Global.on_health_changed.connect(on_player_health_changed)
	# Inicializar todos los cubos
	for cube in lifecubes:
		cube.scale = Vector2.ONE
		cube.visible = true
		cube.texture = lifecube_full
	
	# Guardar la posición original del primer cubo
	original_first_cube_position = lifecubes[0].position

func on_player_health_changed(player_current_health: int) -> void:
	# Detener la animación de último cubo si existe
	if last_life_tween:
			last_life_tween.kill()

	# Detener el temblor si existe
	if shake_tween:
			shake_tween.kill()

	# Resetear color y posición del cubo que estaba parpadeando
	lifecubes[0].modulate = Color.WHITE
	lifecubes[0].position = original_first_cube_position # Restaurar la posición original

	# Procesar los cubos de derecha a izquierda (3->1)
	for i in range(lifecubes.size() - 1, -1, -1):
		if i < player_current_health:
			# Mostrar y llenar el cubo si estaba vacío
			if not lifecubes[i].visible:
					lifecubes[i].texture = lifecube_full
					play_grow_animation(i)
		else:
			# Ocultar el cubo si estaba visible
			if lifecubes[i].visible:
				lifecubes[i].texture = lifecube_empty
				play_shrink_animation(i)

	# Si queda 1 de vida, hacer parpadear el último cubo
	if player_current_health == 1:
		play_last_life_animation()

func play_shrink_animation(cube_index: int) -> void:
	var tween = create_tween()
	tween.tween_property(lifecubes[cube_index], "scale", Vector2.ZERO, 0.3)
	await tween.finished
	lifecubes[cube_index].visible = false

func play_grow_animation(cube_index: int) -> void:
	lifecubes[cube_index].scale = Vector2.ZERO
	lifecubes[cube_index].visible = true
	var tween = create_tween()
	tween.tween_property(lifecubes[cube_index], "scale", Vector2.ONE, 0.3)

func play_last_life_animation() -> void:
	last_life_tween = create_tween()
	last_life_tween.set_loops()

	# Parpadeo en rojo
	last_life_tween.parallel().tween_property(lifecubes[0], "modulate", Color(1, 0, 0, 1), 0.5)
	last_life_tween.tween_property(lifecubes[0], "modulate", Color.WHITE, 0.5)

	# Temblor (shake)
	shake_tween = create_tween()
	shake_tween.set_loops()
	shake_tween.tween_property(lifecubes[0], "position", original_first_cube_position + Vector2(1, 1), 0.05)
	shake_tween.tween_property(lifecubes[0], "position", original_first_cube_position - Vector2(1, 1), 0.05)
	shake_tween.tween_property(lifecubes[0], "position", original_first_cube_position, 0.05)

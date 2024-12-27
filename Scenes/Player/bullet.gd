extends Area2D

var bullet_impact_effect = preload("res://Scenes/Player/bullet_impact_effect.tscn")

# --- Movement Constants ---
@export var speed: float = 500.0  # Velocidad del proyectil
var direction: Vector2 = Vector2.RIGHT  # Dirección predeterminada del proyectil
var damage_amount : int = 1

func _physics_process(delta: float) -> void:
	# Mover el proyectil en la dirección especificada
	position += direction * speed * delta
	$AnimationBullet.play("shot")

func _on_area_entered(area: Area2D) -> void:
	# Detectar si el área es un hurtbox
	if area.has_method("get_damage_amount"):
		print("Bullet hit hurtbox: ", area.name)
		if area.get_parent().has_method("take_damage"):
			area.get_parent().take_damage(get_damage_amount())
	else:
		print("Bullet hit area: ", area.name)
	
	# Siempre destruir la bala después de una colisión
	bullet_impact()

func _on_body_entered(body: Node2D) -> void:
	# Esto ocurre si la bala impacta un PhysicsBody2D (cuerpo principal o suelo)
	print("Bullet hit body: ", body.name)
	bullet_impact()

func get_damage_amount() -> int:
	return damage_amount

func bullet_impact():
	var bullet_impact_effect_instance = bullet_impact_effect.instantiate() as Node2D
	bullet_impact_effect_instance.global_position = global_position
	get_parent().add_child(bullet_impact_effect_instance)
	queue_free()

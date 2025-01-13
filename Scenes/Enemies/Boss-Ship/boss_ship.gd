extends CharacterBody2D

# --- Enemy spawn settings ---
const ENEMY_SCENE_PATH = "res://Scenes/Enemies/Crab/crab.tscn"
const MAX_ENEMIES_ON_SCREEN = 8
const SPAWN_INTERVAL = 1.0

# --- Motion Settings ---
const SPEED = 50.0
const PLAYER_DETECTION_MARGIN = 10.0 # Margin of error for player detection on the X axis

# --- Variables ---
var moving_right = true  # Current direction of movement
var spawn_timer = 0.0
var enemies_on_screen = []
@export var health_amount : int = 50
var damage_amount : int = 1

# --- Nodes ---
@onready var spawner = $Spawner
@onready var spawn_sfx = $SpawnSfx
@onready var ray_cast = $RayCast2D
@onready var enemy_scene = preload(ENEMY_SCENE_PATH)
@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_polygon = $CollisionPolygon2D
@onready var hurtbox_shape = $Hurtbox/HurtboxShape
@onready var explosion_sound = $ExplosionSfx


# --- Reference to the player ---
var player: CharacterBody2D = null

# --- Death status ---
var is_dead = false
signal level_won



func _ready() -> void:
	# Activate physical processing
	set_physics_process(true)

	# Search the player in the scene
	player = get_parent().find_child("Player")
	if not player:
		push_error("Player node not found in the scene!")

func _physics_process(delta: float) -> void:
	if is_dead:
			velocity = Vector2.ZERO  # Stop movement if dead
			return  # Don't run move logic

	# Timer control and enemy generation
	spawn_timer += delta
	if spawn_timer >= SPAWN_INTERVAL and enemies_on_screen.size() < MAX_ENEMIES_ON_SCREEN:
			spawn_enemy()
			spawn_timer = 0.0

	# Clear enemies that no longer exist
	cleanup_enemies()

	# Ship movement management
	handle_movement(delta)

func handle_movement(delta: float) -> void:
		# --- Obstacle detection ---
		if ray_cast.is_colliding():
				moving_right = not moving_right  # Change direction
				flip_elements()  # Adjust the flip of elements
				print("Obstacle detected, changing direction")

		# --- Player Detection ---
		if player and abs(player.global_position.x - global_position.x) < PLAYER_DETECTION_MARGIN:
				velocity.x = 0 # Stop if player is close on the X axis
				animated_sprite.play("default")
				animated_sprite.stop() # Stop animation when player is nearby
		else:
				# --- Movimiento ---
				velocity.x = SPEED if moving_right else -SPEED
				animated_sprite.play("default")

		# --- Move the ship ---
		move_and_slide()

func flip_elements() -> void:
		# --- Girar el sprite ---
		animated_sprite.flip_h = not moving_right
		
		# --- Girar el spawner ---
		spawner.position.x *= -1
		
		# --- Girar el CollisionPolygon2D ---
		var shape = collision_polygon.polygon
		for i in range(shape.size()):
				shape[i].x *= -1  # Invierte el eje X de cada punto del polígono
		collision_polygon.polygon = shape
		
		# --- Girar el HurtboxShape ---
		var hurtbox_shape_polygon = hurtbox_shape.polygon
		for i in range(hurtbox_shape_polygon.size()):
				hurtbox_shape_polygon[i].x *= -1  # Invierte el eje X de cada punto del polígono
		hurtbox_shape.polygon = hurtbox_shape_polygon
		
		# --- Girar el RayCast2D ---
		ray_cast.position.x *= -1
		ray_cast.rotation += PI  # Gira el RayCast2D 180 grados

func spawn_enemy() -> void:
		var enemy = enemy_scene.instantiate()
		enemy.global_position = spawner.global_position
		get_tree().current_scene.add_child(enemy)
		enemies_on_screen.append(enemy)
		spawn_sfx.play()

func cleanup_enemies() -> void:
		enemies_on_screen = enemies_on_screen.filter(func(enemy):return is_instance_valid(enemy))

func _on_hurtbox_area_entered(area: Area2D) -> void:
		print("Boss_Ship. Hurtbox area entered by: ", area.name)
		if area.has_method("get_damage_amount"):
				print("Boss_Ship. get_damage_amount method found")
				var damage = area.get_damage_amount()
				health_amount -= damage
				print("Boss_Ship. Health after hit: ", health_amount)
				if health_amount <= 0 and not is_dead:
						die()


func die() -> void:
	is_dead = true
	
	# Desactivar ambas colisiones inmediatamente
	collision_polygon.set_deferred("disabled", true)
	hurtbox_shape.set_deferred("disabled", true)
	
	# Reproducir la animación de muerte
	animated_sprite.scale = Vector2(8, 8)
	animated_sprite.play("death")
	
	# Reproducir el sonido de la explosión
	explosion_sound.play()
	
	# Esperar a que termine la animación
	await animated_sprite.animation_finished
	
	level_won.emit()
	
	# Eliminar la nave
	queue_free()

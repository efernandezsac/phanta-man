extends CharacterBody2D

const SPEED = 90
const STICK_PREVENTION_TIME = 0.8
const POST_COLLISION_COOLDOWN = 0.5
const STICK_THRESHOLD = 0.1 # Time in seconds to be considered "stuck"

@export var health_amount : int = 2
var damage_amount : int = 1

# Node references
@onready var sprite = $AnimatedSprite2D # Reference to the enemy's sprite
@onready var detection_area = $DetectionArea # Detection area for player
@onready var hurtbox = $Hurtbox # Hurtbox for receiving damage
@export var detect_left: bool = true

@export var is_boss : bool = false
signal level_won

var player: Node2D = null           # Reference to the player
var player_detected: bool = false   # Detect if player is within range
var is_colliding_with_player: bool = false
var stick_prevention_timer: float = 0.0
var post_collision_timer: float = 0.0
var is_stuck_to_player: bool = false
var stuck_timer: float = 0.0

var enemy_death_effect = preload("res://Scenes/Effects/enemy_death_effect.tscn")
@onready var hitted_sfx = $Sfx/HittedSfx
@onready var death_sfx = $Sfx/DeathSfx

func _ready():
		# Invertir área de detección si detect_left está habilitado
		if detect_left:
				$DetectionArea.scale.x = -1

func _physics_process(delta: float):
		# Update timers
		if stick_prevention_timer > 0:
				stick_prevention_timer -= delta
		if post_collision_timer > 0:
				post_collision_timer -= delta

		# Check sticking
		if is_colliding_with_player:
				stuck_timer += delta
				if stuck_timer >= STICK_THRESHOLD:
						is_stuck_to_player = true
		else:
				stuck_timer = 0.0
				is_stuck_to_player = false

		# Handle movement and attack
		if player_detected and player and not is_colliding_with_player and post_collision_timer <= 0:
				_attack_player()
		elif is_stuck_to_player:
				# Apply a stronger force to break free if stuck
				var direction_away = (position - player.position).normalized()
				velocity = direction_away * (SPEED * 1.5)
				stick_prevention_timer = STICK_PREVENTION_TIME
		elif not is_colliding_with_player:
				velocity = Vector2.ZERO # Stop if not colliding and not chasing

		move_and_slide()

		# Check for collisions with the player after moving
		is_colliding_with_player = false
		for i in get_slide_collision_count():
				var collision = get_slide_collision(i)
				if collision.get_collider() == player:
						is_colliding_with_player = true
						if stick_prevention_timer <= 0:
								velocity = -collision.get_normal() * (SPEED * 1.3)
								stick_prevention_timer = STICK_PREVENTION_TIME
								post_collision_timer = POST_COLLISION_COOLDOWN


func _attack_player() -> void:
		sprite.play("flying")
		var player_position = player.position
		var direction = (player_position - position).normalized()
		velocity = direction * SPEED
		# Voltear sprite para mirar hacia el jugador
		$AnimatedSprite2D.flip_h = direction.x < 0

func handle_movement_input(_delta: float) -> void:
		var direction = Input.get_axis("move_left", "move_right")

		if direction != 0:
				velocity.x = direction * SPEED # Move at constant speed
				$AnimatedSprite2D.flip_h = direction < 0 # Flip sprite based on direction


func death():
		print("Buitre defeated!")
		death_sfx.play()
		# Instanciar el efecto de muerte
		var enemy_death_effect_instance = enemy_death_effect.instantiate() as Node2D
		var sprite_height = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame).get_height()
		enemy_death_effect_instance.global_position = global_position - Vector2(0, sprite_height / 2)
		get_parent().add_child(enemy_death_effect_instance)
		
		# Emitir una señal si este enemigo es el jefe
		if is_boss:
			print("Vulture Boss defeated!")
			level_won.emit()
		
		# Eliminar al enemigo después de instanciar el efecto
		queue_free()

# Detectar cuando el jugador entra en el área de detección
func _on_detection_area_body_entered(body: Node2D) -> void:
		if body.name == "Player":
				player = body
				player_detected = true  # Activar detección


# Detectar cuando el jugador sale del área de detección
func _on_detection_area_body_exited(body: Node2D) -> void:
		if body == player:
				player_detected = false  # Desactivar detección


# Recibir daño cuando un área entra en el hurtbox
func _on_hurtbox_area_area_entered(area: Area2D) -> void:
		if area.has_method("get_damage_amount"):
				hitted_sfx.play()
				var damage = area.get_damage_amount()
				health_amount -= damage
				await get_tree().create_timer(0.1).timeout
				print("Buitre. Health after hit: ", health_amount)
				if health_amount <= 0:
						death()

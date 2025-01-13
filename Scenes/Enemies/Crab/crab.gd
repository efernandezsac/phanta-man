extends CharacterBody2D

# Constants for movement
const WALK_SPEED = 80.0        # Speed when patrolling
const CHASE_SPEED = 150.0      # Speed when chasing the player
const IDLE_TIME = 2.0          # Time to stay idle at edges or walls
const CHASE_TIMEOUT = 3.0      # Time to forget the player after losing detection

# States for the enemy
enum State { IDLE, WALK, CHASE }
var current_state: State = State.IDLE

# Internal Variables
var moving_left: bool = true        # Direction the crab is moving
var idle_timer: float = 0.0         # Timer for the idle state
var chase_timer: float = 0.0        # Timer to forget the player after losing detection
var player: Node2D = null           # Reference to the player
var player_detected: bool = false   # Bandera para detección del jugador
var health_amount : int = 3
var damage_amount : int = 1

# Node references
@onready var sprite = $AnimatedSprite2D # Reference to the enemy's sprite
@onready var raycast = $FloorRayCast2D # RayCast to detect ground or walls
@onready var detection_shape = $DetectionArea/DetectionShape # Detection area for player

@onready var crab_audio_player = $CrabAudioPlayer
@onready var visibility_notifier = $VisibleOnScreenNotifier2D
@onready var sound_timer = $SoundTimer

var is_on_screen = false

var enemy_death_effect = preload("res://Scenes/Effects/enemy_death_effect.tscn")

# Variables para el cambio de escala
var original_scale: Vector2
var enlarged_scale: Vector2
var scale_timer: float = 0.0
var is_scale_enlarged: bool = false

# Offsets for flipping raycast and detection area
var raycast_offset: float           # Horizontal offset for the RayCast2D
var detection_offset: float         # Horizontal offset for the CollisionShape2D

func _ready():
	# Get the initial positions of RayCast2D and CollisionShape2D
	raycast_offset = abs(raycast.position.x)
	detection_offset = abs(detection_shape.position.x)
	
	visibility_notifier.screen_entered.connect(_on_visible_on_screen_notifier_2d_screen_entered)
	visibility_notifier.screen_exited.connect(_on_visible_on_screen_notifier_2d_screen_exited)
	sound_timer.timeout.connect(_on_sound_timer_timeout)
	sound_timer.wait_time = randf_range(3.0, 8.0) # Intervalo aleatorio entre sonidos
	
	original_scale = $CollisionShape2D.scale # Guardar la escala original
	enlarged_scale = original_scale * 1.05 # Calcular la escala ampliada
	
func _physics_process(delta: float):
	# Apply gravity to ensure the enemy stays grounded
	velocity.y += get_gravity().y * delta
	
	# Execute logic based on the current state
	match current_state:
		State.IDLE:
			handle_idle(delta)
		State.WALK:
			handle_walk()
		State.CHASE:
			handle_chase(delta)
	
	if current_state == State.CHASE:
		scale_timer -= delta
		if scale_timer <= 0:
			is_scale_enlarged = !is_scale_enlarged # Alternar la escala
			$CollisionShape2D.scale = enlarged_scale if is_scale_enlarged else original_scale
			scale_timer = 0.2 # Ajusta la frecuencia del cambio de escala
	move_and_slide()

func handle_idle(delta: float):
	# Stop movement and play the idle animation
	velocity.x = 0
	sprite.play("idle")
	
	# Wait for the idle timer to end and return to WALK state
	idle_timer -= delta
	if idle_timer <= 0:
		moving_left = not moving_left
		update_flip_and_positions()
		change_state(State.WALK)

func handle_walk() -> void:
	# Move in the current direction
	velocity.x = -WALK_SPEED if moving_left else WALK_SPEED
	
	# Update sprite flip and node positions
	update_flip_and_positions()
	
	# Play the walk animation
	sprite.play("walk")
	
	# Detect walls or edges to transition to IDLE state
	if is_on_wall() or not raycast.is_colliding():
		change_state(State.IDLE)

func handle_chase(delta: float):
	# Calculate the horizontal distance to the player
	var distance_x = abs(player.global_position.x - global_position.x)
	
	# Update movement direction and velocity towards the player
	if distance_x > 2: # Move if not already aligned horizontally
		moving_left = player.global_position.x < global_position.x
		velocity.x = -CHASE_SPEED if moving_left else CHASE_SPEED
	elif distance_x > 0: # Pequeño movimiento si está muy cerca
		velocity.x = -10 if moving_left else 10 # Ajusta este valor
	else:
		velocity.x = 0  # Stop if aligned with the player
	
	# Update sprite flip and node positions
	update_flip_and_positions()
	sprite.play("walk")
	
	# Manage the chase timer based on player detection
	if player_detected:
		chase_timer = CHASE_TIMEOUT # Reset the timer while the player is detected
	else:
		chase_timer -= delta # Reduce the timer if the player is not detected
		if chase_timer <= 0:
			change_state(State.WALK) # Return to WALK state when the timer runs out

func change_state(new_state: State):
	# Change the current state and initialize its behavior
	current_state = new_state
	match new_state:
		State.IDLE:
			idle_timer = IDLE_TIME # Set idle timer
		State.WALK:
			raycast.enabled = true # Enable ground detection
		State.CHASE:
			raycast.enabled = false # Disable ground detection while chasing
			chase_timer = CHASE_TIMEOUT # Initialize chase timer

func update_flip_and_positions():
	# Flip the sprite horizontally to face the movement direction (default facing left)
	sprite.flip_h = not moving_left
	
	# Flip the position of the RayCast2D
	raycast.position.x = -raycast_offset if moving_left else raycast_offset
	
	# Flip the position of the CollisionShape2D (detection area)
	detection_shape.position.x = -detection_offset if moving_left else detection_offset

# Signal: The player enters the detection area
func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_detected = true  # Set player detected flag to true
		player = body           # Store reference to the player
		change_state(State.CHASE)

# Signal: Triggered when the player exits the detection area
func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_detected = false  # Set player detected flag to false

func _on_hurtbox_area_entered(area: Area2D):
	print("Crab. Hurtbox area entered by: ", area.name)
	if area.has_method("get_damage_amount"):
		print("Crab. get_damage_amount method found")
		var damage = area.get_damage_amount()
		health_amount -= damage
		print("Crab. Health after hit: ", health_amount)

		if health_amount <= 0:
			death() # Llamar a la función de muerte


func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	is_on_screen = true
	print("Cangrejo entró en la pantalla")

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	is_on_screen = false
	print("Cangrejo salió de la pantalla")
	crab_audio_player.stop() # Detener el sonido si sale de la pantalla

func _on_sound_timer_timeout() -> void:
	if is_on_screen:
			crab_audio_player.play()
	sound_timer.wait_time = randf_range(3.0, 8.0) # Reiniciar con un nuevo intervalo
	sound_timer.start()


func _on_hurtbox_body_entered(body: Node2D) -> void:
	if body.name != "Player":
		death()

func death():
	print("Enemy defeated!")
	
	# Instanciar el efecto de muerte
	var enemy_death_effect_instance = enemy_death_effect.instantiate() as Node2D
	var sprite_height = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame).get_height()
	enemy_death_effect_instance.global_position = global_position - Vector2(0, sprite_height / 2)
	get_parent().add_child(enemy_death_effect_instance)  # Añadir al árbol de la escena
	
	# Eliminar al enemigo después de instanciar el efecto
	queue_free()

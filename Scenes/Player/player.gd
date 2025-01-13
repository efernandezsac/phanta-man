extends CharacterBody2D

var player_death_effect = preload("res://Scenes/Effects/player_death_effect.tscn")
var can_input: bool = true # Flag para controlar la entrada
@onready var lantern_light: PointLight2D = $Lantern

# --- Movement Constants ---
const SPEED = 200.0 # Player's horizontal movement speed
const JUMP_VELOCITY = -300.0 # Initial velocity for jumping (negative because up is negative in 2D)
const COYOTE_TIME = 0.2 # Time allowed to jump after leaving a platform
const MIN_JUMP_VELOCITY = -150.0 # Minimum upward speed when releasing the jump button early

# --- Physics Constants --- SE PUEDEN CAMBIAR EN EL INSPECTOR
const FLOOR_SNAP_LENGTH = 4.0  # Distance to snap to the floor when descending slopes
const FLOOR_MAX_ANGLE = deg_to_rad(45)  # Maximum angle considered a floor
var gravity: float = 0.0 # Gravity force applied to the player (initialized in _ready)

# --- State Management ---
enum State { IDLE, RUN, JUMP, FALL, DOUBLE_JUMP, SHOOT, RUN_SHOOT, AIR_SHOOT, KNOCKBACK, DEATH } # Enum to define Player states
var current_state: State = State.IDLE # Player's initial state
var previous_state: State = current_state # Store the previous state for animation optimization

# --- Timers and flags ---
var coyote_time_remaining = 0.0 # Remaining time for coyote jump
var double_jump_available = false # Flag to track if the double jump is available

# --- Knockback Variables ---
@export var knockback_force: float = 200.0
@export var knockback_duration: float = 0.2
@export var knockback_jump_velocity: float = -200.0
var knockback_timer: float = 0.0
var is_in_knockback: bool = false
var knockback_direction: Vector2 = Vector2.ZERO

# --- Invulnerability Variables ---
@export var invulnerability_duration: float = 1.0
@onready var invulnerability_timer: Timer = $InvulnerabilityTimer
@onready var hurtbox_collision: CollisionShape2D = $Hurtbox/HurtboxCollision

# --- Sounds ---
@onready var jump_sfx = $Sfx/JumpSfx
@onready var doublejump_sfx = $Sfx/DoubleJumpSfx
@onready var shoot_sfx = $Sfx/ShootSfx
@onready var hithurt_sfx = $Sfx/HithurtSfx

# --- CollisionShape2D Adjustment ---
@onready var collision_shape: CollisionShape2D = $CollisionShape2D # Referencia a la CapsuleShape2D
const ORIGINAL_COLLISION_HEIGHT = 38 # Altura original de la colisión
const DOUBLE_JUMP_COLLISION_HEIGHT = 22 # Altura reducida de la colisión durante el doble salto
const DOUBLE_JUMP_COLLISION_POSITION_Y = -26 # Posición Y de la colisión durante el doble salto


# ============================
# --- Ready Function ---
# ============================

func _ready():
	# Restaurar la colisión al inicio
	restore_collision_shape()
	
	# --- Configure physics properties ---
	gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
	$AnimationPlayer.play("spawn")
	
	# --- Configure floor snap and slope handling ---
	set_floor_snap_length(FLOOR_SNAP_LENGTH) # Set floor snap for slopes
	set_floor_max_angle(FLOOR_MAX_ANGLE) # Max angle considered as floor
	
	invulnerability_timer.wait_time = invulnerability_duration
	invulnerability_timer.one_shot = true
	
# ============================
# --- Physics Process ---
# ============================

func _physics_process(delta: float) -> void:
	# Avoid processing physics if the player is dead
	if current_state == State.DEATH:
		return  # Exit the method and do not execute any more physics logic
	
	#print("Current state: " + State.keys()[current_state] + ", Previous state: " + State.keys()[previous_state])
	
	handle_input(delta)  # Process user input
	handle_knockback(delta) # Knockback ANTES de move_and_slide()
	apply_physics(delta) # Apply gravity and movement
	update_animation()   # Update animations based on state

# ============================
# --- Input Handling ---
# ============================

# Handle player input
func handle_input(delta: float) -> void:
	if not can_input: # Si la entrada está desactivada, no procesar nada
		return
		
	if is_in_knockback: # Ignorar la entrada durante el knockback
		return
	
	handle_movement_input(delta) # Handle horizontal movement input
	handle_jump_input(delta) # Handle jump and double jump input
	handle_shoot_input()  # Handle shooting input
	handle_state_transitions() # Update player state

# --- Handle horizontal movement ---
func handle_movement_input(_delta: float) -> void:
	var direction = Input.get_axis("move_left", "move_right")
	
	if direction != 0:
		velocity.x = direction * SPEED # Move at constant speed
		$AnimatedSprite2D.flip_h = direction < 0 # Flip sprite based on direction
		
		# Ajustar la posición del Muzzle (punto de spawn del proyectil)
		$Muzzle.position.x = abs($Muzzle.position.x) * (-1 if $AnimatedSprite2D.flip_h else 1)
		# Orientar la linterna
		if $AnimatedSprite2D.flip_h: # Mirando a la izquierda
			lantern_light.rotation_degrees = 180  # Apunta a la izquierda
			# Ajustar la posición x para que la luz quede delante del personaje cuando mira a la izquierda
			lantern_light.position.x = -abs(lantern_light.position.x)
		else: # Mirando a la derecha
			lantern_light.rotation_degrees = 0  # Apunta a la derecha
			lantern_light.position.x = abs(lantern_light.position.x)
	else:
		# Gradually slow down to a stop
		velocity.x = move_toward(velocity.x, 0, SPEED)

# --- Handle jump, double jump, and coyote time ---
func handle_jump_input(delta: float) -> void:
	# Update coyote time if on the floor
	if is_on_floor():
		coyote_time_remaining = COYOTE_TIME
		double_jump_available = true
	else:
		coyote_time_remaining -= delta
	
	# Variable jump height when releasing the button early
	if Input.is_action_just_released("jump"):
		if velocity.y < MIN_JUMP_VELOCITY and current_state in [State.JUMP, State.DOUBLE_JUMP]:
			velocity.y = MIN_JUMP_VELOCITY
	
	# Handle jump and double jump
	if Input.is_action_just_pressed("jump"):
		if is_on_floor() or coyote_time_remaining > 0:
			jump()
			double_jump_available = true
			coyote_time_remaining = 0.0
		elif double_jump_available:
			double_jump()

# --- Handle shooting input ---
func handle_shoot_input() -> void:
	if Input.is_action_just_pressed("shoot"):
		shoot()
		if is_on_floor():  # Si está en el suelo
			if not is_zero_approx(velocity.x):  # Si se está moviendo
				change_state(State.RUN_SHOOT)
				$AnimatedSprite2D.play("run_shoot")
				current_state = State.RUN
			else:  # Si está quieto
				change_state(State.SHOOT)
				$AnimatedSprite2D.play("shoot")
				await $AnimatedSprite2D.animation_finished
				current_state = State.IDLE
		else: # Si está en el aire
			change_state(State.AIR_SHOOT)
			$AnimatedSprite2D.play("air_shoot")
			await $AnimatedSprite2D.animation_finished
			current_state = State.JUMP

# ============================
# --- State Management ---
# ============================

# Update the player's state based on conditions
func handle_state_transitions() -> void:
	if current_state == State.DEATH: # Ignorar si está muerto
			return
	
	if is_in_knockback:  # Mantener el estado KNOCKBACK mientras esté activo
		return  # No cambiar de estado mientras esté en knockback
	
	if current_state == State.SHOOT or current_state == State.AIR_SHOOT or current_state == State.RUN_SHOOT:
		return
	
	if is_on_floor():
			# If on the floor, check if the player is moving or idle
			if not is_zero_approx(velocity.x):
					change_state(State.RUN)
			else:
					change_state(State.IDLE)
	else:
			# If in the air, determine if jumping or falling
			if velocity.y < 0: # Moving upwards
					if current_state != State.DOUBLE_JUMP:
							change_state(State.JUMP)
			else: # Moving downwards
					change_state(State.FALL)

# Change the player state and update previous state
func change_state(new_state: State) -> void:
	if current_state != new_state:
		if current_state == State.DOUBLE_JUMP: # Restaurar la colisión al salir de DOUBLE_JUMP
			restore_collision_shape()
		previous_state = current_state
		current_state = new_state

# ============================
# --- Physics Application ---
# ============================

# Apply physics calculations (gravity and movement)
func apply_physics(delta: float) -> void:
		# Apply gravity
		if not is_on_floor():
				velocity.y += gravity * delta
		
		move_and_slide() # Handle movement and collisions

# ============================
# --- Knockback Functions ---
# ============================

func apply_knockback():
	is_in_knockback = true
	knockback_timer = knockback_duration
	velocity.y = knockback_jump_velocity
	change_state(State.KNOCKBACK)

func handle_knockback(delta: float):
		if is_in_knockback:
				velocity.x = knockback_direction.x * knockback_force
				knockback_timer -= delta
				if knockback_timer <= 0: # Desactivar knockback cuando el temporizador llega a cero, independientemente de si está en el suelo
						is_in_knockback = false
						# NO resetear velocity.x aquí, permitir que la gravedad y el movimiento normal afecten
# ============================
# --- Animation Management ---
# ============================

# Update animations based on the current state
func update_animation() -> void:
	if current_state != previous_state:
		match current_state:
			State.IDLE:
				$AnimatedSprite2D.play("idle")
			State.RUN:
				$AnimatedSprite2D.play("run")
			State.JUMP:
				$AnimatedSprite2D.play("jump")
			State.FALL:
				$AnimatedSprite2D.play("fall")
			State.DOUBLE_JUMP:
				$AnimatedSprite2D.play("double_jump")
			State.KNOCKBACK:
				$AnimatedSprite2D.play("knockback")
		previous_state = current_state

func _on_animated_sprite_2d_animation_finished() -> void:
	pass

# ============================
# --- Jump Functions ---
# ============================

# Perform the initial jump
func jump() -> void:
		velocity.y = JUMP_VELOCITY # Apply upward velocity
		jump_sfx.play() # Play jump sound effect
		change_state(State.JUMP)

# Perform a double jump
func double_jump() -> void:
		velocity.y = JUMP_VELOCITY # Apply upward velocity
		doublejump_sfx.play() # Play double jump sound effect
		double_jump_available = false # Consume the double jump
		change_state(State.DOUBLE_JUMP)
		
		# Reducir la altura de la colisión
		collision_shape.shape.height = DOUBLE_JUMP_COLLISION_HEIGHT
		collision_shape.position.y = DOUBLE_JUMP_COLLISION_POSITION_Y
		print("nueva colision")
		
# Perform the shooting action
func shoot() -> void:
	print("Disparo realizado")
	##print("Current state: " + State.keys()[current_state] + ", Previous state: " + State.keys()[previous_state])
	shoot_sfx.play() # Play shoot sound effect
	
	# Instanciar un proyectil si existe una escena de proyectil
	var projectile_scene = preload("res://Scenes/Effects/bullet.tscn")  # Ruta de la escena del proyectil
	var projectile = projectile_scene.instantiate()
	get_parent().add_child(projectile)  # Agregar el proyectil a la escena
	
	# Posicionar el proyectil
	projectile.global_position = $Muzzle.global_position

	# Configurar la dirección del proyectil
	if $AnimatedSprite2D.flip_h:  # Si el sprite está volteado hacia la izquierda
		projectile.direction = Vector2.LEFT
	else:
		projectile.direction = Vector2.RIGHT
		

func hitted(damage_hitted : int):
		hithurt_sfx.play()
		$AnimationPlayer.play("hit")
		
		Global.decrease_health(damage_hitted)
		print("Tu vida es: ", Global.current_health, ". Daño recibido: ", damage_hitted)
		
		if Global.current_health <= 0:
			death()
		else:
			apply_knockback() # Aplicar knockback
			start_invulnerability()
	

func death():
	can_input = false # Desactivar la entrada
	Global.decrease_health(Global.max_health)
	change_state(State.DEATH)
	var player_death_effect_instance = player_death_effect.instantiate() as Node2D
	player_death_effect_instance.global_position = global_position
	get_parent().add_child(player_death_effect_instance)
	hide()
	hurtbox_collision.disabled = true # Desactivar el Hurtbox
# ============================
# --- Collision Handling ---
# ============================

func _on_hurtbox_body_entered(body: Node2D) -> void:
	if hurtbox_collision.disabled: # Ignorar si ya es invulnerable
		return
	if body.is_in_group("Enemy"):
		if body.global_position.x < global_position.x:
			print("# Impacto desde la izquierda")
			knockback_direction = Vector2.RIGHT
		else:
			print("# Impacto desde la derecha")
			knockback_direction = Vector2.LEFT
		print(body.name, " EnemyBody touched you. Deals ", body.damage_amount)
		hitted(body.damage_amount)
	else:
		print("Body colisionó que no es Enemy") #Muerte por TileSet Capa 4
		death()

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if hurtbox_collision.disabled: # Ignorar si ya es invulnerable
		return
	if area.global_position.x < global_position.x:
		print("# Impacto desde la izquierda")
		knockback_direction = Vector2.RIGHT
	else:
		print("# Impacto desde la derecha")
		knockback_direction = Vector2.LEFT
	if area.is_in_group("EnemyAttack"):
		var enemy = area.get_parent()  # Obtiene el nodo del enemigo para sacar damage_amount
		print(enemy.name, " EnemyArea touched you. Deals ", enemy.damage_amount)
		hitted(enemy.damage_amount)
	else:
		print("Area colisionó que no es Enemy")

func start_invulnerability():
		hurtbox_collision.disabled = true # Desactivar la colisión
		invulnerability_timer.start()
		print("Invulnerabilidad activada")
		
func _on_invulnerability_timer_timeout() -> void:
	hurtbox_collision.disabled = false # Reactivar la colisióndy.
	print("Invulnerabilidad desactivada")

func restore_collision_shape():
	collision_shape.shape.height = ORIGINAL_COLLISION_HEIGHT
	collision_shape.position.y = -19
	print("colision reestablecida")

func _on_trapped_area_body_entered(body: Node2D) -> void:
	if current_state != State.DEATH:
		Global.decrease_health(Global.max_health)
		change_state(State.DEATH)
		death()

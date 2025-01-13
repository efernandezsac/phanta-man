extends CharacterBody2D

# Constants for movement
const JUMP_FORCE = -400.0     # Vertical jump force (controls jump height)
const JUMP_SPEED = 120.0      # Horizontal jump speed during jumps
const IDLE_TIME = 1.0         # Time to stay idle between jumps
const CHASE_SPEED = 150.0     # Horizontal speed when chasing the player
const CHASE_TIMEOUT = 3.0     # Time to forget the player after losing detection

# States for the enemy
enum State { IDLE, JUMP, CHASE }
var current_state: State = State.IDLE  # Initial state

# Internal Variables
var moving_left: bool = true        # Direction the enemy is moving
var idle_timer: float = 0.0         # Timer for the idle state
var chase_timer: float = 0.0        # Timer to forget the player after losing detection
var player: Node2D = null           # Reference to the player
var player_detected: bool = false   # Flag for player detection

# Node references
@onready var sprite = $AnimatedSprite2D         # Reference to the enemy's sprite
@onready var raycast = $FloorRayCast2D          # RayCast to check for ground
@onready var detection_shape = $Area2D          # Detection area to find the player

func _ready():
	# Initialize the state
	change_state(State.IDLE)

func _physics_process(delta: float):
	# Apply gravity
	velocity.y += get_gravity().y * delta

	# Execute logic based on the current state
	match current_state:
		State.IDLE:
			handle_idle(delta)
		State.JUMP:
			handle_jump()
		State.CHASE:
			handle_chase(delta)

	move_and_slide()

### STATE HANDLERS ###

func handle_idle(delta: float):
	# Stop movement and play idle animation
	velocity.x = 0
	sprite.play("idle")

	# Countdown the idle timer
	idle_timer -= delta
	if idle_timer <= 0:
		change_state(State.JUMP)  # Move to JUMP state after idle time ends

func handle_jump():
	# Perform a jump with horizontal movement
	if is_on_floor():
		velocity.y = JUMP_FORCE  # Apply vertical force
		velocity.x = -JUMP_SPEED if moving_left else JUMP_SPEED  # Apply horizontal movement

		# Flip direction after each jump
		moving_left = not moving_left
		sprite.flip_h = moving_left

		sprite.play("jump")  # Play jump animation

	# Transition back to IDLE when the jump ends
	if velocity.y > 0 and is_on_floor():
		change_state(State.IDLE)

func handle_chase(delta: float):
	# Calculate direction towards the player
	var direction = sign(player.global_position.x - global_position.x)
	velocity.x = direction * CHASE_SPEED

	# Perform jump movement when touching the ground
	if is_on_floor():
		velocity.y = JUMP_FORCE
		sprite.play("jump")

	# Manage chase timer
	if player_detected:
		chase_timer = CHASE_TIMEOUT  # Reset the timer while the player is detected
	else:
		chase_timer -= delta
		if chase_timer <= 0:
			change_state(State.IDLE)  # Return to IDLE state when timer runs out

### STATE TRANSITION FUNCTION ###

func change_state(new_state: State):
	# Change the current state and initialize its behavior
	current_state = new_state
	match new_state:
		State.IDLE:
			idle_timer = IDLE_TIME  # Reset idle timer
			velocity.x = 0          # Stop horizontal movement
		State.JUMP:
			pass  # No initialization needed for JUMP
		State.CHASE:
			chase_timer = CHASE_TIMEOUT  # Reset chase timer

### SIGNALS FOR DETECTION ###

func _on_area_2d_body_entered(body: Node2D):
	if body.name == "Player":
		player_detected = true
		player = body
		change_state(State.CHASE)

func _on_area_2d_body_exited(body: Node2D):
	if body.name == "Player":
		player_detected = false

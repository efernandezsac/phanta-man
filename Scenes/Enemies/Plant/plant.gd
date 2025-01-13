extends CharacterBody2D

# --- Nodos ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hurtbox_area: Area2D = $HurtboxArea
@onready var hurtbox_seed: CollisionShape2D = $HurtboxArea/HurtboxSeed
@onready var hurtbox_idle: CollisionShape2D = $HurtboxArea/HurtboxIdle
@onready var hurtbox_whip_left: CollisionPolygon2D = $HurtboxArea/HurtboxWhipLeft
@onready var hurtbox_whip_right: CollisionPolygon2D = $HurtboxArea/HurtboxWhipRight
@onready var detection_area_left: Area2D = $DetectionAreaLeft
@onready var detection_area_right: Area2D = $DetectionAreaRight
@onready var whip_timer: Timer = $WhipTimer

# --- Estados ---
enum State { FALL, GROW, IDLE, WHIP }
var current_state: State = State.FALL

# --- Variables de detección ---
var player_detected_side: String = "" # "left", "right", ""

# --- Variables de Daño ---
var health_amount: int = 5
var damage_amount: int = 1

# --- Escena de muerte ---
var enemy_death_effect = preload("res://Scenes/Effects/enemy_death_effect.tscn")

func _ready():
		# Inicialización
		hurtbox_idle.disabled = true
		hurtbox_whip_left.disabled = true
		hurtbox_whip_right.disabled = true
		whip_timer.one_shot = true
		whip_timer.wait_time = 2.0

		# Conectar señales
		animated_sprite.animation_finished.connect(_on_animated_sprite_2d_animation_finished)
		hurtbox_area.area_entered.connect(_on_hurtbox_area_area_entered)
		hurtbox_area.body_entered.connect(_on_hurtbox_area_body_entered)
		detection_area_left.body_entered.connect(_on_detection_area_left_body_entered)
		detection_area_left.body_exited.connect(_on_detection_area_left_body_exited)
		detection_area_right.body_entered.connect(_on_detection_area_right_body_entered)
		detection_area_right.body_exited.connect(_on_detection_area_right_body_exited)
		whip_timer.timeout.connect(_on_whip_timer_timeout)

func _physics_process(delta: float) -> void:
		match current_state:
				State.FALL:
						apply_gravity(delta)
						if is_on_floor():
								change_state(State.GROW)

func apply_gravity(delta: float) -> void:
		velocity.y += ProjectSettings.get_setting("physics/2d/default_gravity") * delta
		move_and_slide()

func change_state(new_state: State) -> void:
		if current_state == new_state:
				return

		current_state = new_state
		
		match current_state:
				State.FALL:
						animated_sprite.play("fall")
						hurtbox_seed.disabled = false
						hurtbox_idle.disabled = true
						hurtbox_whip_left.disabled = true
						hurtbox_whip_right.disabled = true
				State.GROW:
						animated_sprite.play("grow")
						hurtbox_seed.disabled = true
						hurtbox_idle.disabled = true
						hurtbox_whip_left.disabled = true
						hurtbox_whip_right.disabled = true
				State.IDLE:
						animated_sprite.play("idle")
						hurtbox_seed.disabled = true
						hurtbox_idle.disabled = false
						hurtbox_whip_left.disabled = true
						hurtbox_whip_right.disabled = true
				State.WHIP:
						hurtbox_idle.disabled = true
						if player_detected_side == "left":
								animated_sprite.play("whip_left")
								hurtbox_whip_left.disabled = false
								hurtbox_whip_right.disabled = true
						elif player_detected_side == "right":
								animated_sprite.play("whip_right")
								hurtbox_whip_right.disabled = false
								hurtbox_whip_left.disabled = true
						
						whip_timer.start()

# --- Señales de detección izquierda ---
func _on_detection_area_left_body_entered(body: Node2D) -> void:
		if body.name == "Player" and current_state == State.IDLE:
				player_detected_side = "left"
				change_state(State.WHIP)

func _on_detection_area_left_body_exited(body: Node2D) -> void:
		if body.name == "Player" and player_detected_side == "left":
				player_detected_side = ""

# --- Señales de detección derecha ---
func _on_detection_area_right_body_entered(body: Node2D) -> void:
		if body.name == "Player" and current_state == State.IDLE:
				player_detected_side = "right"
				change_state(State.WHIP)

func _on_detection_area_right_body_exited(body: Node2D) -> void:
		if body.name == "Player" and player_detected_side == "right":
				player_detected_side = ""

func _on_animated_sprite_2d_animation_finished() -> void:
		if current_state == State.GROW:
				change_state(State.IDLE)
		elif current_state == State.WHIP:
				# Si el jugador sigue detectado, reiniciar ataque
				if player_detected_side != "":
						change_state(State.WHIP)
				else:
						# Si no hay detección, regresar a IDLE
						change_state(State.IDLE)

func _on_whip_timer_timeout():
		if current_state == State.WHIP:
				change_state(State.IDLE)
				

# --- Función de muerte ---
func death():
		print("Plant defeated!")

		# Instanciar el efecto de muerte
		var enemy_death_effect_instance = enemy_death_effect.instantiate() as Node2D
		var sprite_height = animated_sprite.sprite_frames.get_frame_texture(animated_sprite.animation, animated_sprite.frame).get_height()
		enemy_death_effect_instance.global_position = global_position - Vector2(0, sprite_height / 2)
		get_parent().add_child(enemy_death_effect_instance)

		# Eliminar al enemigo después de instanciar el efecto
		queue_free()

# --- Hurtbox area ---
func _on_hurtbox_area_area_entered(area: Area2D) -> void:
		print("Plant. HurtBoxArea Entered: ", area.name) # Imprimir el nombre del área que entra
		if area.has_method("get_damage_amount"):
				var damage = area.get_damage_amount()
				health_amount -= damage
				print("Plant. Health after hit: ", health_amount)
				if health_amount <= 0:
						death()

func _on_hurtbox_area_body_entered(body: Node2D) -> void:
		if body.name != "Player":
				death()

extends Node

var coins_collected = 0
var max_health : int = 3
var current_health : int

signal on_health_changed

var last_checkpoint_position: Vector2 = Vector2(-100, -100) # Default position outside

var Boss1_defeated = false
var Boss2_defeated = false
var Boss3_defeated = false

func _ready() -> void:
	print ("Global Ready")
	current_health = max_health

func _process(_delta: float) -> void:
	pass

func decrease_health(health_amount : int):
	current_health -= health_amount
	
	if current_health <0:
			current_health = 0
	print("decrease health called")
	on_health_changed.emit(current_health)

func increase_health(health_amount : int):
	current_health += health_amount
	
	if current_health > max_health:
			current_health = max_health
	print("increase health called")
	on_health_changed.emit(current_health)

extends Node

var coins_collected = 0

var max_health : int = 3
var current_health : int

signal on_health_changed


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print ("Global Ready") # Replace with function body.
	current_health = max_health

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _input(event):
	if event.is_action_pressed("return_to_main_menu"):
		get_tree().change_scene_to_file("res://Levels/main_menu.tscn")
		

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

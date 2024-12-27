extends NodeState


@export var character_body_2d : CharacterBody2D
@export var animated_sprite_2d : AnimatedSprite2D
@export var speed : int

var player : CharacterBody2D

func on_process(delta: float):
	pass

func on_physics_process(delta: float):
	pass
	
func enter():
	player = get_node("Player") as CharacterBody2D
	
func exit():
	pass

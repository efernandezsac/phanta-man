extends Node2D

@onready var animation_intro = $AnimationPlayer

func _ready():
 animation_intro.play("intro")
 get_tree().create_timer(10).timeout.connect(start_menu_scene)
 
func start_menu_scene():
 get_tree().change_scene_to_file("res://Scenes/Levels/main_menu.tscn")

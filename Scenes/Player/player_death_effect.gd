extends Node2D

func _on_timer_timeout() -> void:
	queue_free()
	print("¡Has muerto!")
	get_tree().reload_current_scene()

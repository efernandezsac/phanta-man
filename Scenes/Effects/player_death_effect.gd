extends Node2D

func _on_timer_timeout() -> void:
	queue_free()
	print("PlayerDeathEffect running")
	get_tree().reload_current_scene()
	Global.current_health = Global.max_health

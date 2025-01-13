extends Node2D

func _on_timer_timeout() -> void:
	print("PlayerSpawnEffect running")
	$AnimatedSprite2D.play("spawn_effect")
	await $AnimatedSprite2D.animation_finished

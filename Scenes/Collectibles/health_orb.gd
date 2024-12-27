extends Area2D

signal health_orb_collected

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		Global.increase_health(1)
		print_debug("Health Orb picked. Your health is: ", Global.current_health)
		$CollectedHealthOrbSfx.play()
		# Hide the health_orb and disable collision
		hide()
		$CollisionShape2D.set_deferred("disabled", true)

func _on_collected_healt_orb_sfx_finished() -> void:
	queue_free()

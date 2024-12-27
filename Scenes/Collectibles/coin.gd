extends Area2D

signal coin_collected

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		Global.coins_collected += 1
		print_debug("Coin Collected: ", Global.coins_collected)
		coin_collected.emit()
		$CollectedCoinSfx.play()
		# Hide the coin and disable collision
		hide()
		$CollisionShape2D.set_deferred("disabled", true)

func _on_collected_coin_sfx_finished() -> void:
	queue_free()

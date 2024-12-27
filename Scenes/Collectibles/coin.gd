extends Area2D

signal coin_collected

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		Global.coins_collected += 1
		print_debug(Global.coins_collected)
		coin_collected.emit()
		$CollectedCoinSfx.play()
		# Hide the coin and disable collision
		hide()
		$CollisionShape2D.set_deferred("disabled", true)

func _on_collected_coin_sfx_finished() -> void:
	queue_free()

extends Area2D

@export var level = ""
signal player_entered(level)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		Global.last_checkpoint_position = Vector2(-100,-100)
		player_entered.emit(level)

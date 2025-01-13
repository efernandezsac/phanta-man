extends Area2D

signal checkpoint_activated(checkpoint_position)

@export var dialog_lines: Array[String] = ["C H E C K P O I N T"]
@export var speech_sound: AudioStream
var was_activated = false

func _on_body_entered(body):
	if body.is_in_group("Player"):
		if !was_activated:
			Global.last_checkpoint_position = global_position
			checkpoint_activated.emit(global_position)
			print("Checkpoint activado en: ", global_position)
			DialogManager.start_dialog(global_position, dialog_lines, speech_sound, true)
			was_activated = true
			$AnimatedSprite2D.play

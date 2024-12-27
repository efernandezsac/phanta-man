extends Node

@export var node_finite_state_machine : NodeFiniteStateMachine

func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		node_finite_state_machine.transition_to("attack")


func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		node_finite_state_machine.transition_to("idle")

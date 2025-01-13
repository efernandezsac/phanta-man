extends RigidBody2D

@onready var lifespan_timer = $LifespanTimer

func _ready():
		lifespan_timer.wait_time = 19
		lifespan_timer.one_shot = true
		lifespan_timer.start()

func _on_lifespan_timer_timeout() -> void:
	queue_free() # Elimina el bloque de la escena

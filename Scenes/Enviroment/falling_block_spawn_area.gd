@tool
extends Node2D

@export var block_scene: PackedScene
@export var spawn_interval = 0.5
@export var block_gravity_scale = 0.5  # Property to control block gravity
@export var spawn_area_width: float = 100.0  # Property for the spawn area width

@onready var spawn_area = $SpawnArea

func _ready():
		if not Engine.is_editor_hint():
				$SpawnTimer.wait_time = spawn_interval
				$SpawnTimer.autostart = true
				$SpawnTimer.timeout.connect(_on_spawn_timer_timeout)

		_update_spawn_area_width()

func spawn_block():
		if not block_scene:
				printerr("Error: Block Scene no asignada en FallingBlockSpawnArea.")
				return

		var block_instance = block_scene.instantiate()
		block_instance.gravity_scale = block_gravity_scale

		# Get the global position of the Area2D (which is the center)
		var global_pos = spawn_area.global_position

		# Calculate the min and max X coordinates based on the exported width
		var min_x = global_pos.x - spawn_area_width / 2.0
		var max_x = global_pos.x + spawn_area_width / 2.0

		# Generate a random X position within the bounds
		var spawn_x = randf_range(min_x, max_x)

		# Set the initial position of the block
		block_instance.global_position = Vector2(spawn_x, global_position.y)
		get_parent().add_child(block_instance)

func _update_spawn_area_width():
		if Engine.is_editor_hint():
				var collision_shape_2d = spawn_area.get_node("CollisionShape2D")
				collision_shape_2d.shape.size.x = spawn_area_width


func _on_spawn_timer_timeout() -> void:
		spawn_block()

func _process(delta):
		if Engine.is_editor_hint():
				_update_spawn_area_width()

func _on_property_changed(property):
		if Engine.is_editor_hint() and property == "spawn_area_width":
				_update_spawn_area_width()

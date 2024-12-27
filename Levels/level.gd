extends Node2D

@export var level_num = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$HUD.level(level_num)
	print("Level " + str(level_num) + " ready")
	set_coins_label()
	for coin in $Coins.get_children():
		coin.coin_collected.connect(_on_coin_collected)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _on_coin_collected() -> void:
	$HUD/CoinsLabel.text = str(Global.coins_collected)

func set_coins_label():
	$HUD.coins(Global.coins_collected)

# Called when a bullet is destroyed
func _on_bullet_destroyed():
	pass

func _on_door_player_entered(level) -> void:
	get_tree().call_deferred("change_scene_to_file", level)

func _input(event):
	if event.is_action_pressed("reset_level"):
		get_tree().reload_current_scene.call_deferred()
		Global.coins_collected = 0
		Global.current_health = Global.max_health
		set_coins_label()

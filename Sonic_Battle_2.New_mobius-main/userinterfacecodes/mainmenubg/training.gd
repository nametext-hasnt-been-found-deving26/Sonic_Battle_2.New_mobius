extends Button

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	print("Training button pressed!")
	get_tree().change_scene_to_file("res://character_select_screen.tscn")

func _on_focus_entered() -> void:
	modulate = Color(1,1,1,1)
	$"../../../AnimationPlayer".play("fade_in_training")
	%info.text = str("Lab combos with your favorite character.")

func _on_focus_exited() -> void:
	modulate = Color(1,1,1,0)

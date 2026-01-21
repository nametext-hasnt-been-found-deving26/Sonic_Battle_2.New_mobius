extends Button  # This is the correct base class for UI buttons


func _ready() -> void:
	pressed.connect(_on_pressed)
	
func _on_pressed() -> void:
	print("Battle Mode button pressed!")
	get_tree().change_scene_to_file("res://characterselect.tscn")

func _on_focus_entered() -> void:
	modulate = Color(1,1,1,1)
	$"../../../AnimationPlayer".play("fade_in_battle")
	%info.text = str("Duke it out on the arena!")

func _on_focus_exited() -> void:
	modulate = Color(1,1,1,0)
	
	

extends Button

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	print("Story Mode button pressed!")
	get_tree().change_scene_to_file("res://characterselect.tscn")

func _on_focus_entered() -> void:
	modulate = Color(1,1,1,1)
	$"../../../AnimationPlayer".play("fade_in_story_mode")
	%info.text = str("Embark on the new mobuis with each character's story.")
	


func _on_focus_exited() -> void:
	modulate = Color(1,1,1,0)

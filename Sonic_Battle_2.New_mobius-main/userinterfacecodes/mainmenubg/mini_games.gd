extends Button

func _on_focus_entered() -> void:
	modulate = Color(1,1,1,1)
	$"../../../AnimationPlayer".play("fade_in_mini_games")


func _on_focus_exited() -> void:
	modulate = Color(1,1,1,0)

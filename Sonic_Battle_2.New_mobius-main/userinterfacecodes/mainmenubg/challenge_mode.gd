extends Button

func _on_focus_entered() -> void:
	modulate = Color(1,1,1,1)
	$"../../../AnimationPlayer".play("fade_in_challenge_mode")
	%info.text = str("Challenge yourself by facing foes!")


func _on_focus_exited() -> void:
	modulate = Color(1,1,1,0)

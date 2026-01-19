extends SonicState

func _on_enter(_context : Dictionary = {}) -> void:
	print("Entered %s" % name)

func _on_exit() -> void:
	print("Exited %s" % name)

func _on_update(_delta : float) -> void:
	pass

func _on_physics_update(delta : float) -> void:
	sonic.apply_gravity(delta)
	sonic.handle_ground_movement(delta)
	
	handle_transitions()

func handle_transitions() -> void:
	if sonic.input.is_equal_approx(Vector2.ZERO):
		transition("Idle")
		return
	
	if Input.is_action_just_pressed("jump") and sonic.is_on_floor():
		transition("Airborne", {"HasJumped" : true})
		return
	
	if not sonic.is_on_floor():
		transition("Airborne")
		return

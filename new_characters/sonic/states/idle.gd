extends SonicState


func _on_enter(_context : Dictionary = {}) -> void:
	#print("Entered %s" % name)
	sonic.animator_ctrl.set_base("Idle")
	
	if _context.has("Stopping"):
		var stopping : bool = _context.get("Stopping")
		
		if stopping:
			sonic.animator_ctrl.play("Stopping",true)

func _on_exit() -> void:
	#print("Exited %s" % name)
	pass

func _on_update_(_delta : float) -> void:
	pass

func _on_physics_update(delta : float) -> void:
	sonic.apply_gravity(delta)
	sonic.apply_ground_friction()
	sonic.apply_velocity(delta)
	
	handle_transitions()

func handle_transitions() -> void:
	
	if not sonic.input.is_equal_approx(Vector2.ZERO):
		transition("Ground")
		return
	
	if Input.is_action_just_pressed("jump") and sonic.is_on_floor():
		transition("Airborne", {"HasJumped" : true})
		return
	
	if not sonic.is_on_floor():
		transition("Airborne")
		return

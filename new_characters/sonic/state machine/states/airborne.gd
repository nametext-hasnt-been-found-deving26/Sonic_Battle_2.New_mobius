extends SonicState

var coyote_time_max : float = 0.12 # 120 ms
# how long has sonic been off the ground
var airborne_duration : float = 0.0

func _on_enter(_context : Dictionary = {}) -> void:
	print("Entered %s" % name)
	
	if _context.has("HasJumped"):
		sonic.velocity.y = sonic.jump_force
		# if sonic jump coyote time is not possible
		airborne_duration = 100

func _on_exit() -> void:
	print("Exited %s" % name)
	airborne_duration = 0.0

func _on_update(_delta : float) -> void:
	pass

func _on_physics_update(delta : float) -> void:
	airborne_duration += delta
	
	# coyote jump!
	if airborne_duration < coyote_time_max and Input.is_action_just_pressed("jump"):
		sonic.velocity.y = sonic.jump_force
	
	sonic.apply_gravity(delta)
	sonic.handle_ground_movement(delta)
	
	handle_transitions()

func handle_transitions() -> void:
	pass
	if sonic.input.is_equal_approx(Vector2.ZERO) and sonic.is_on_floor():
		transition("Idle")
		return
	
	if not sonic.input.is_equal_approx(Vector2.ZERO) and sonic.is_on_floor():
		transition("Ground")
		return

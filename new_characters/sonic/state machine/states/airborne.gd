extends SonicState

var has_jumped : bool = false
var coyote_time_max : float = 0.18 # 180 ms
# how long has sonic been off the ground
var airborne_duration : float = 0.0

func _on_enter(_context : Dictionary = {}) -> void:
	#print("Entered %s" % name)
	sonic.animator_ctrl.set_base("Falling")
	
	if _context.has("HasJumped"):
		has_jumped = true
		sonic.animator_ctrl.stop_update = true
		sonic.animator_ctrl.play("Jumping",true)
		sonic.velocity.y = sonic.jump_force
		# If sonic jumps, coyote time is not possible.
		airborne_duration = 100

func _on_exit() -> void:
	#print("Exited %s" % name)
	airborne_duration = 0.0
	sonic.animator_ctrl.stop_update = false
	has_jumped = false

func _on_update(_delta : float) -> void:
	pass

func _on_physics_update(delta : float) -> void:
	airborne_duration += delta
	
	# coyote jump!
	if airborne_duration < coyote_time_max and Input.is_action_just_pressed("jump"):
		has_jumped = true
		sonic.animator_ctrl.stop_update = true
		sonic.velocity.y = sonic.jump_force
		print("Coyote Jump!")
	
	if has_jumped and sonic.velocity.y < 0.0 and not sonic.animator_ctrl.is_busy():
		sonic.animator_ctrl.play("Falling",true)
	
	if sonic.input.x != 0:
		if sonic.facing_dir != sign(sonic.input.x):
			sonic.facing_dir = sign(sonic.input.x)
			sonic.animator.flip_h = sonic.facing_dir != 1
	
	sonic.apply_gravity(delta)
	sonic.handle_ground_movement(delta)
	
	handle_transitions()

func handle_transitions() -> void:
	
	if sonic.input.is_equal_approx(Vector2.ZERO) and sonic.is_on_floor():
		transition("Idle")
		play_landing()
		return
	
	if not sonic.input.is_equal_approx(Vector2.ZERO) and sonic.is_on_floor():
		transition("Ground")
		play_landing()
		return
		
func play_landing() -> void:
	sonic.animator_ctrl.play("Landing",true)
	await sonic.animator.animation_finished

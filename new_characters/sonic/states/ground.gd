extends SonicState

# temporary gfx
@export var dash_effect: AnimatedSprite3D
var offset_position : Vector3

enum modifiers {Ground,Dash}
var current_modifier : modifiers = modifiers.Ground
var dash_force : float = 5.0
var dash_start_time : float = 0.0
var max_dash_time : float = 0.4
var min_dash_time : float = 0.2
var has_released_dash : bool = false

var dash_dir : Vector2

func _on_enter(_context : Dictionary = {}) -> void:
	has_released_dash = false
	if not dash_effect.top_level:
		offset_position = dash_effect.position
		dash_effect.top_level = true
	#print("Entered %s" % name)
	sonic.animator_ctrl.set_base("Running")

func _on_exit() -> void:
	#print("Exited %s" % name)
	pass

func _on_update(_delta : float) -> void:
	pass

func _on_physics_update(delta : float) -> void:
	
	if current_modifier != modifiers.Dash and not sonic.input.is_equal_approx(Vector2.ZERO):
		dash_dir = sonic.input.normalized()
	
	handle_modifiers(delta)
	

func handle_transitions() -> void:
	
	if Input.is_action_just_pressed("jump") and sonic.is_on_floor():
		transition("Airborne", {"HasJumped" : true})
		return
	
	if sonic.velocity.is_equal_approx(Vector3.ZERO) and sonic.input.is_equal_approx(Vector2.ZERO):
		if sonic.is_on_floor():
			transition("Idle")
			return
	
	
	if not sonic.is_on_floor():
		transition("Airborne")
		return

func handle_modifiers(delta : float) -> void:
	match current_modifier:
		modifiers.Ground:
			sonic.apply_gravity(delta)
			sonic.handle_ground_movement(delta)
			
			if sonic.input.x != 0:
				if sonic.facing_dir != sign(sonic.input.x):
					sonic.facing_dir = sign(sonic.input.x)
					sonic.animator_ctrl.play("Turning around fast",true)
					await sonic.animator.animation_finished
					sonic.animator.flip_h = sonic.facing_dir != 1
			
			if Input.is_action_just_pressed("dash"):
				sonic.animator_ctrl.stop_update = true
				sonic.animator_ctrl.play("Dashing toward opponent",true)
				dash_effect.global_position = sonic.global_position + offset_position
				dash_effect.scale.x = -1 if sonic.facing_dir == -1 else 1
				dash_effect.play("default")
				current_modifier = modifiers.Dash
				sonic.velocity = Vector3(dash_dir.x,0.0,dash_dir.y) * dash_force
				dash_start_time = Time.get_ticks_msec() / 1000.0
				return
			
			handle_transitions()
			
		modifiers.Dash:
			
			if Input.is_action_just_released("dash") and not has_released_dash:
				has_released_dash = true
			
			if sonic.input.x != 0:
				sonic.facing_dir = sign(sonic.input.x)
			
			sonic.animator.flip_h = sonic.facing_dir != 1
			
			sonic.move_and_slide()
			
			var current_time : float = Time.get_ticks_msec() / 1000.0
			
			if (current_time - dash_start_time) > max_dash_time:
				current_modifier = modifiers.Ground
				sonic.animator_ctrl.stop_update = false
				play_landing()
				return
			elif (current_time - dash_start_time) > min_dash_time and has_released_dash:
				current_modifier = modifiers.Ground
				sonic.animator_ctrl.stop_update = false
				play_landing()
				return
			

func play_landing() -> void:
	sonic.animator_ctrl.play("Landing",true)
	await sonic.animator.animation_finished

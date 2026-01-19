extends CharacterBody3D


## State Machine
#enum State {
	#IDLE, DASHING , RUNNING, JUMPING, FALLING, LANDING,
	#ATTACK_1, ATTACK_2, ATTACK_3, HEAVY_ATTACK, UPPER_ATTACK,
	#AIR_ACTION, AIR_ATTACK,
	#GUARD, HEAL_START, HEAL_LOOP, HEAL_END,
	#TURNING_AROUND, TURNING_AROUND_WHILE_RUNNING, STOPPING,
	#WALL_CLING
#}
#var current_state: State = State.IDLE
#
## Heavy Attack Phases (Sonic Flare style)
#enum HeavyPhase {
	#DROP,          # Initial drop - falling straight down
	#HANDSTAND,    # Land on one hand - brief ground pause
	#FLARE,        # Sweeping kick - the actual breakdance attack
	#LEG_LIFT,     # Shift weight, legs up high
	#RECOVERY      # Push back to standing - airborne
#}
#
## ===== MODULAR CONFIGURATION SECTION ===== #
##region Modular Config Variables
#@export_category("Movement Settings")
#@export var max_speed: float = 8.0
#@export var acceleration: float = 0.5
#@export var friction: float = 0.4
#@export var turn_friction_multiplier: float = 4.5 
#@export var turn_kickoff_boost: float = 0.75      
#@export var air_control_factor: float = 0.33
#var current_direction: String
#var running_start: bool = false
#var apply_dash_friction: bool = false
#
#@export_category("Jump Settings")
#@export var jump_force: float = 4.5
#@export var air_action_force: float = 8.0
#@export var air_action_upward_boost: float = 2.0
#
#@export_category("Combat Settings")
#@export var attack_cooldown_duration: float = 0.3
#@export var combo_window_ms: int = 500
#@export var input_buffer_duration: float = 0.1
#@export var heavy_attack_recovery: float = 0.5
#@export var air_attack_cooldown_duration: float = 0.6
#var attack_to_do: String 
#@export var upper_window_duration: float = 0.5
#@export var heavy_window_duration: float = 0.5
##this space is for a theorethical upper attack category, if it doesnt happen, then just move this to category above ;)
#var do_upper: bool = false
#
## Sonic Flare Phase Durations
#@export_category("Heavy Attack - Sonic Flare")
#@export var flare_drop_speed: float = 20.0
#@export var flare_handstand_duration: float = 0.15
#@export var flare_sweep_duration: float = 0.4
#@export var flare_leg_lift_duration: float = 0.25
#@export var flare_recovery_duration: float = 0.3
#@export var flare_recovery_lift: float = 3.0
#@export var flare_recoil_pushback: float = 2.0
#var do_heavy: bool = false
#
#@export_category("State Durations")
#@export var landing_duration: float = 0.2
#@export var attack_duration: float = 0.4
#@export var upper_attack_duration: float = 0.4
#@export var air_action_duration: float = 0.4
#@export var air_attack_duration: float = 0.3
#@export var turning_duration: float = 0.12            
#@export var turning_while_running_duration: float = 0.12 
#@export var stopping_duration: float = 0.08           
#@export var heal_start_duration: float = 0.3
#@export var heal_loop_duration: float = 1.0
#@export var heal_end_duration: float = 0.3
#@export var wall_cling_duration: float = 1.0
#
#@export_category("character stats")
#@export var Maxhealth: int = 100
#var health: int
#
#@export var Maxichikoro: float = 100.0
#var ichikoro: float
#
#@export var damage: int 
#@export var defence: int = 2
#
#@export_category("Healing Settings")
#@export var heal_amount_per_second: float = 20.0
#@export var ichikoro_regen_per_second: float = 30.0
#
#@export_category("Animation Settings")
#@onready var animated_sprite_3d: AnimatedSprite3D = $AnimatedSprite3D
##endregion
#
## ===== INTERNAL VARIABLES =====
##region Internal Variables
#var landing_timer: float = 0.0
#var attack_timer: float = 0.0
#var upper_attack_timer: float = 0.0
#var air_action_timer: float = 0.0
#var air_attack_timer: float = 0.0
#var turning_timer: float = 0.0
#var turning_while_running_timer: float = 0.0
#var stopping_timer: float = 0.0
#var heal_start_timer: float = 0.0
#var heal_loop_timer: float = 0.0
#var heal_end_timer: float = 0.0
#var wall_cling_timer: float = 0.0
#var heavy_window_timer: float = 0.0
#var upper_window_timer: float = 0.0
#var ichikoro_regen_cooldown: float = 0.0
#
#var attack_combo_count: int = 0
#var can_combo: bool = false
#var is_attacking: bool = false
#var last_attack_time: int = 0
#var is_healing: bool = false
#var has_air_action: bool = true
#var has_air_attacked: bool = false
#var attack_cooldown: float = 0.0
#var air_attack_cooldown: float = 0.0
#
#var heavy_phase: HeavyPhase = HeavyPhase.DROP
#var heavy_phase_timer: float = 0.0
#var attack_input_buffer: bool = false
#var attack_input_cooldown: float = 0.0
#
#var last_input_direction: Vector2 = Vector2.ZERO
#var current_facing_direction: int = 1
#var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
##endregion
#
#var KO_s: int
#
## ===== INITIALIZATION =====
#func _ready() -> void:
	#if not $attack_handler.animation_finished.is_connected(_on_attack_handler_animation_finished):
		#$attack_handler.animation_finished.connect(_on_attack_handler_animation_finished)
	#health = Maxhealth
	#ichikoro = 0
	#validate_animations()
	#change_state(State.IDLE)
#
#func validate_animations() -> void:
	#if animated_sprite_3d and animated_sprite_3d.sprite_frames:
		#var animations = animated_sprite_3d.sprite_frames.get_animation_names()
		#var critical_anims = ["1st attack", "2nd attack", "3rd attack", "Heavy attack", "Upper attack", "Air action", "Air attack", "Guard", "Heal start", "Heal loop", "Heal end", "Turning around", "Turning around while running"]
		#for anim_name in critical_anims:
			#if not animated_sprite_3d.sprite_frames.has_animation(anim_name):
				#print("WARNING: Animation '", anim_name, "' not found. Using fallback.")
#
## ===== MAIN PROCESS =====
#func _physics_process(delta: float) -> void:
	#update_cooldowns(delta)
	#apply_gravity(delta)
	#handle_attack_input()
	#handle_state(delta)
	#regenerate_ichikoro(delta)
	#move_and_slide()
	#_handle_hit_properties()
	#if Input.is_action_just_pressed("get_KOs (only for testing purposes)"):
		#KO_s = KO_s + 1
#
#
#func regenerate_ichikoro(delta: float) -> void:
	#if not is_attacking and not is_healing and current_state not in [State.ATTACK_1, State.ATTACK_2, State.ATTACK_3, State.HEAVY_ATTACK, State.AIR_ATTACK]:
		#ichikoro_regen_cooldown -= delta
		#if ichikoro_regen_cooldown <= 0:
			#ichikoro = min(ichikoro + 5.0 * delta, Maxichikoro)
			#ichikoro_regen_cooldown = 0.1
			#
#
#func update_cooldowns(delta: float) -> void:
	#if attack_cooldown > 0: attack_cooldown -= delta
	#if attack_input_cooldown > 0:
		#attack_input_cooldown -= delta
		#if attack_input_cooldown <= 0: attack_input_buffer = false
	#if air_attack_cooldown > 0:
		#air_attack_cooldown -= delta
		#if air_attack_cooldown < 0: air_attack_cooldown = 0.0
#
#func apply_gravity(delta: float) -> void:
	#if current_state == State.HEAVY_ATTACK and heavy_phase in [HeavyPhase.HANDSTAND, HeavyPhase.FLARE, HeavyPhase.LEG_LIFT]:
		#return
	#if not is_on_floor():
		#velocity.y -= gravity * delta
#
## ===== INPUT HANDLING =====
#func handle_attack_input() -> void:
	#if current_state in [State.HEAVY_ATTACK, State.AIR_ATTACK]: return
	#if Input.is_action_just_pressed("p"):
		#if heavy_window_timer > 0:
			#do_heavy = true
		#elif upper_window_timer > 0:
			#do_upper = true
		#process_attack_input()
	#process_buffered_attack()
#
#func process_attack_input() -> void:
	#if not is_on_floor():
		#if can_air_attack(): perform_air_attack()
		#else:
			#attack_input_buffer = true
			#attack_input_cooldown = input_buffer_duration
		#return
	#if is_on_floor() and can_attack(): 
		#if do_heavy == true:
			#change_state(State.HEAVY_ATTACK)
			#print("heavy")
		#elif do_upper == true:
			#change_state(State.UPPER_ATTACK)
			#print("upper")
		#else:
			#handle_combo_attack()
	#else:
		#attack_input_buffer = true
		#attack_input_cooldown = input_buffer_duration
#
#func process_buffered_attack() -> void:
	#if current_state in [State.HEAVY_ATTACK, State.AIR_ATTACK]: return
	#if attack_input_buffer and attack_cooldown <= 0:
		#if not is_on_floor() and can_air_attack(): perform_air_attack()
		#elif is_on_floor() and can_attack():handle_combo_attack()
		#
#
## ===== STATE MANAGEMENT =====
#func handle_state(delta: float) -> void:
	#var input_dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	#update_facing_direction(delta, input_dir)
	#handle_special_inputs(input_dir)
	#var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	#
	#match current_state:
		#State.IDLE: handle_idle_state(delta, input_dir, direction)
		#State.RUNNING: handle_running_state(delta, input_dir, direction)
		#State.DASHING: _apply_dashing (direction)
		#State.JUMPING: handle_jumping_state(delta, direction)
		#State.FALLING: handle_falling_state(delta, direction)
		#State.LANDING: handle_landing_state(delta, input_dir)
		#State.ATTACK_1, State.ATTACK_2, State.ATTACK_3: handle_attack_state(delta, input_dir)
		#State.HEAVY_ATTACK: handle_heavy_attack_state(delta, input_dir)
		#State.UPPER_ATTACK: handle_upper_attack_state(delta, input_dir)
		#State.AIR_ACTION: handle_air_action_state(delta, direction)
		#State.AIR_ATTACK: handle_air_attack_state(delta, direction)
		#State.GUARD: handle_guard_state(delta, input_dir)
		#State.HEAL_START: handle_heal_start_state(delta)
		#State.HEAL_LOOP: handle_heal_loop_state(delta)
		#State.HEAL_END: handle_heal_end_state(delta, input_dir)
		#State.TURNING_AROUND: handle_turning_around_state(delta, input_dir)
		#State.TURNING_AROUND_WHILE_RUNNING: handle_turning_around_while_running_state(delta, input_dir)
		#State.STOPPING: handle_stopping_state(delta, input_dir)
		#State.WALL_CLING: handle_wall_cling_state(delta, input_dir)
	#
	#if input_dir != Vector2.ZERO:
		#last_input_direction = input_dir
#
#func update_facing_direction(delta: float, input_dir: Vector2) -> void:
	#if current_facing_direction == 1 and Input.is_action_just_pressed("right_p1") or current_facing_direction == -1 and Input.is_action_just_pressed("left_p1") :
		#heavy_window_timer = heavy_window_duration
	#heavy_window_timer -= delta
	#if current_state in [State.TURNING_AROUND, State.TURNING_AROUND_WHILE_RUNNING]:
		#return
		#
	#if current_state not in [State.ATTACK_1, State.ATTACK_2, State.ATTACK_3, State.HEAVY_ATTACK]:
		#if input_dir.x != 0:
			#current_facing_direction = 1 if input_dir.x > 0 else -1
#
	#if animated_sprite_3d:
		#animated_sprite_3d.flip_h = (current_facing_direction == -1)
		#if current_state not in [State.TURNING_AROUND, State.TURNING_AROUND_WHILE_RUNNING, State.UPPER_ATTACK]:
			#if current_facing_direction == 1:
				#current_direction = "right"
			#else:
				#current_direction = "left"
#
#func handle_special_inputs(input_dir: Vector2) -> void:
	#if current_state in [State.HEAVY_ATTACK, State.AIR_ATTACK, State.UPPER_ATTACK]: return
	#if Input.is_action_just_pressed("shift") and can_guard(): change_state(State.GUARD)
	#if Input.is_action_just_pressed("ui_accept"):
		#if is_on_floor() and current_state in [State.IDLE, State.RUNNING, State.DASHING, State.LANDING]: jump()
		#elif can_air_action() and not is_on_floor(): perform_air_action(input_dir)
#
## ===== STATE HANDLERS =====
#func handle_idle_state(delta: float, input_dir: Vector2, direction: Vector3) -> void:
	#apply_friction()
	#if Input.is_action_just_pressed("dash_p1"):
		#running_start = true
	#if input_dir != Vector2.ZERO:
		#if last_input_direction.x != 0 and input_dir.x != 0 and sign(last_input_direction.x) != sign(input_dir.x):
			#change_state(State.TURNING_AROUND)
		#else: change_state(State.RUNNING)
#
	#if not is_on_floor(): change_state(State.FALLING)
#
#func handle_running_state(delta: float, input_dir: Vector2, direction: Vector3) -> void:
	#if Input.is_action_just_pressed("dash_p1"):
		#running_start = true
	#apply_movement(direction)
	#if input_dir.x != 0 and sign(input_dir.x) != current_facing_direction and running_start == false:
		#change_state(State.TURNING_AROUND_WHILE_RUNNING)
	#elif input_dir == Vector2.ZERO:
		#change_state(State.STOPPING)
	#elif Input.is_action_pressed("dash_p1"):
		#change_state(State.DASHING)
	#elif not is_on_floor():
		#change_state(State.FALLING)
		#
#
#func handle_jumping_state(delta: float, direction: Vector3) -> void:
	#apply_air_control(direction)
	#if velocity.y < 0: change_state(State.FALLING)
#
#func handle_falling_state(delta: float, direction: Vector3) -> void:
	#apply_air_control(direction)
	#if is_on_floor(): change_state(State.LANDING)
#
#func handle_landing_state(delta: float, input_dir: Vector2) -> void:
	#if Input.is_action_pressed("dash_p1"):
		#running_start = true
	#apply_friction()
	#landing_timer -= delta
	#if landing_timer <= 0:
		#has_air_action = true
		#has_air_attacked = false
		#attack_combo_count = 0
		#is_attacking = false
		#if input_dir != Vector2.ZERO: 
			#change_state(State.RUNNING)
		#else: change_state(State.IDLE)
#
#func handle_attack_state(delta: float, input_dir: Vector2) -> void:
	#apply_friction()
	#attack_timer -= delta
	#if Input.is_action_just_pressed("p") and attack_timer > 0.1:
		#attack_input_buffer = true
		#attack_input_cooldown = input_buffer_duration
	#if attack_timer <= 0:
		#is_attacking = false
		#if not is_on_floor(): change_state(State.FALLING)
		#elif input_dir != Vector2.ZERO: 
			#change_state(State.RUNNING)
		#else: change_state(State.IDLE)
#
#func handle_heavy_attack_state(delta: float, input_dir: Vector2) -> void:
	#match heavy_phase:
		#HeavyPhase.DROP:
			#velocity.x = 0; velocity.z = 0
			#velocity.y = -flare_drop_speed
			#if is_on_floor():
				#velocity.y = 0; heavy_phase = HeavyPhase.HANDSTAND
				#heavy_phase_timer = flare_handstand_duration
		#HeavyPhase.HANDSTAND:
			#velocity = Vector3.ZERO; heavy_phase_timer -= delta
			#if heavy_phase_timer <= 0:
				#heavy_phase = HeavyPhase.FLARE; heavy_phase_timer = flare_sweep_duration
		#HeavyPhase.FLARE:
			#velocity = Vector3.ZERO; heavy_phase_timer -= delta
			#if heavy_phase_timer <= 0:
				#heavy_phase = HeavyPhase.LEG_LIFT; heavy_phase_timer = flare_leg_lift_duration
		#HeavyPhase.LEG_LIFT:
			#velocity = Vector3.ZERO; heavy_phase_timer -= delta
			#if heavy_phase_timer <= 0:
				#heavy_phase = HeavyPhase.RECOVERY; heavy_phase_timer = flare_recovery_duration
				#velocity.y = flare_recovery_lift; velocity.x = -current_facing_direction * flare_recoil_pushback
		#HeavyPhase.RECOVERY:
			#heavy_phase_timer -= delta
			#if heavy_phase_timer <= 0:
				#attack_combo_count = 0; is_attacking = false
				#if is_on_floor(): change_state(State.IDLE)
				#else: change_state(State.FALLING)
	#do_heavy = false
#
#func handle_upper_attack_state(delta: float, input_dir: Vector2) -> void:
	#apply_friction(); upper_attack_timer -= delta
	#current_facing_direction = -1 if current_direction == "right" else 1
	#if upper_attack_timer <= 0:
		#if not is_on_floor(): change_state(State.FALLING)
		#elif input_dir != Vector2.ZERO: 
			#change_state(State.RUNNING)
		#else: change_state(State.IDLE)
	#do_upper = false
	#upper_window_timer = 0
#
#func handle_air_action_state(delta: float, direction: Vector3) -> void:
	#if direction:
		#velocity.x = move_toward(velocity.x, direction.x * max_speed, acceleration / 2.0)
		#velocity.z = move_toward(velocity.z, direction.z * max_speed, acceleration / 2.0)
	#air_action_timer -= delta
	#if air_action_timer <= 0: change_state(State.FALLING)
#
#func handle_air_attack_state(delta: float, direction: Vector3) -> void:
	#apply_air_control(direction); air_attack_timer -= delta
	#if air_attack_timer <= 0:
		#is_attacking = false; attack_combo_count = 0
		#attack_input_buffer = false; attack_input_cooldown = 0.0
		#has_air_attacked = true
		#if is_on_floor(): change_state(State.LANDING)
		#else: change_state(State.FALLING)
#
#func handle_guard_state(delta: float, input_dir: Vector2) -> void:
	#apply_friction()
	#if Input.is_action_just_pressed("p") and can_heavy_attack():
		#perform_heavy_attack()
		#return
	#if Input.is_action_pressed("shift"):
		#heal_loop_timer += delta
		#if heal_loop_timer >= heal_loop_duration and not is_healing:
			#change_state(State.HEAL_START)
	#else:
		#heal_loop_timer = 0.0
		#if not is_on_floor(): change_state(State.FALLING)
		#elif input_dir != Vector2.ZERO: 
			#change_state(State.RUNNING)
		#else: change_state(State.IDLE)
#
#func handle_heal_start_state(delta: float) -> void:
	#apply_friction(); heal_start_timer -= delta
	#if heal_start_timer <= 0: change_state(State.HEAL_LOOP)
#
#func handle_heal_loop_state(delta: float) -> void:
	#apply_friction()
	#if health < Maxhealth: health = min(health + heal_amount_per_second * delta, Maxhealth)
	#ichikoro = min(ichikoro + ichikoro_regen_per_second * delta, Maxichikoro)
	#if not Input.is_action_pressed("shift"): change_state(State.HEAL_END)
#
#func handle_heal_end_state(delta: float, input_dir: Vector2) -> void:
	#apply_friction(); heal_end_timer -= delta
	#if heal_end_timer <= 0:
		#is_healing = false
		#if not is_on_floor(): change_state(State.FALLING)
		#elif input_dir != Vector2.ZERO: 
			#change_state(State.RUNNING)
		#else: change_state(State.IDLE)
#
## JITTER FIX: Pivot states handle the flip exactly halfway through the timer to match the frame change
#func handle_turning_around_state(delta: float, input_dir: Vector2) -> void:
	#if Input.is_action_just_pressed("dash_p1"):
		#running_start = true
	#velocity.x = move_toward(velocity.x, 0, friction * turn_friction_multiplier)
	#velocity.z = move_toward(velocity.z, 0, friction * turn_friction_multiplier)
	#turning_timer -= delta
	#if upper_window_timer <= 0:
		#upper_window_timer = upper_window_duration
	#upper_window_timer -= delta
	#
	#if turning_timer < (turning_duration * 0.5):
		#if input_dir.x != 0:
			#var target_facing = 1 if input_dir.x > 0 else -1
			#if current_facing_direction != target_facing:
				#current_facing_direction = target_facing
				#if animated_sprite_3d: 
					#animated_sprite_3d.flip_h = (current_facing_direction == -1)
			#
	#if turning_timer <= 0:
		#if input_dir != Vector2.ZERO: 
			#change_state(State.RUNNING)
		#else: change_state(State.IDLE)
#
#func handle_turning_around_while_running_state(delta: float, input_dir: Vector2) -> void:
	#if Input.is_action_just_pressed("dash_p1"):
		#running_start = true
	#velocity.x = move_toward(velocity.x, 0, friction * turn_friction_multiplier)
	#velocity.z = move_toward(velocity.z, 0, friction * turn_friction_multiplier)
	#turning_while_running_timer -= delta
	#
	#if turning_while_running_timer < (turning_while_running_duration * 0.5):
		#if input_dir.x != 0:
			#var target_facing = 1 if input_dir.x > 0 else -1
			#if current_facing_direction != target_facing:
				#current_facing_direction = target_facing
				#if animated_sprite_3d:
					#animated_sprite_3d.flip_h = (current_facing_direction == -1)
#
	#if turning_while_running_timer <= 0:
		#if input_dir != Vector2.ZERO:
			#velocity.x = input_dir.x * (max_speed * turn_kickoff_boost)
			#change_state(State.RUNNING)
		#else: change_state(State.IDLE)
#
#func handle_wall_cling_state(delta: float, input_dir: Vector2) -> void:
	#velocity = Vector3.ZERO; wall_cling_timer -= delta
	#if Input.is_action_just_pressed("ui_accept"):
		#velocity.y = jump_force; velocity.x = current_facing_direction * -max_speed
		#change_state(State.JUMPING); return
	#if wall_cling_timer <= 0: change_state(State.FALLING)
#
#func handle_stopping_state(delta: float, input_dir: Vector2) -> void:
	#apply_friction(); stopping_timer -= delta
	#if stopping_timer <= 0: change_state(State.IDLE)
	#elif input_dir != Vector2.ZERO:
		#if sign(input_dir.x) != sign(last_input_direction.x) and running_start == false: change_state(State.TURNING_AROUND)
		#else: 
			#change_state(State.RUNNING)
#
## ===== MOVEMENT FUNCTIONS =====
#func apply_movement(direction: Vector3) -> void:
	#if direction:
		##if Input.is_action_pressed("dash_p1"):
			##change_state(State.DASHING)
		##else:
		#velocity.x = move_toward(velocity.x, direction.x * (max_speed/2), acceleration)
		#velocity.z = move_toward(velocity.z, direction.z * (max_speed/2.5), acceleration)
	#else: apply_friction()
#
#func apply_friction() -> void:
	#if apply_dash_friction == true:
		#velocity.x = move_toward(velocity.x, 0, friction * 3)
		#velocity.z = move_toward(velocity.z, 0, friction * 3)
		#apply_dash_friction = false
	#else:
		#velocity.x = move_toward(velocity.x, 0, friction)
		#velocity.z = move_toward(velocity.z, 0, friction)
#
#func _apply_dashing (direction: Vector3) -> void:
	#if direction:
		#if running_start == true:
			#velocity.x = direction.x * (max_speed + 1.75)
			#velocity.z =  direction.z * (max_speed + 1.25)
			#running_start = false
		#else:
			#velocity.x = move_toward(velocity.x, direction.x * max_speed, (acceleration / 2.75))
			#velocity.z = move_toward(velocity.z, direction.z * (max_speed - 0.75), (acceleration / 3.25))
	#else:
		#apply_friction()
		#change_state(State.LANDING)
		#apply_dash_friction = true
	#if Input.is_action_just_released("dash_p1"):
		#change_state(State.LANDING)
		#apply_dash_friction = true
#
#func apply_air_control(direction: Vector3) -> void:
	#if direction:
		#var air_accel = acceleration * air_control_factor
		#velocity.x = move_toward(velocity.x, direction.x * (max_speed - 1.5), air_accel)
		#velocity.z = move_toward(velocity.z, direction.z * (max_speed- 2), air_accel)
#
## ===== ACTION FUNCTIONS =====
#func jump() -> void:
	#velocity.y = jump_force; change_state(State.JUMPING)
#
#func perform_air_action(input_dir: Vector2) -> void:
	#var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	#if direction == Vector3.ZERO: direction = Vector3(current_facing_direction, 0, 0)
	#velocity.x = direction.x * air_action_force; velocity.z = direction.z * air_action_force
	#velocity.y = air_action_upward_boost; has_air_action = false; change_state(State.AIR_ACTION)
#
#func perform_air_attack() -> void:
	#attack_input_buffer = false; attack_input_cooldown = 0.0
	#attack_cooldown = attack_cooldown_duration + air_attack_duration
	#air_attack_cooldown = air_attack_cooldown_duration; has_air_attacked = true
	#change_state(State.AIR_ATTACK); is_attacking = true; last_attack_time = Time.get_ticks_msec()
#
## ===== COMBAT FUNCTIONS =====
#func handle_combo_attack() -> void:
	#attack_input_buffer = false; attack_input_cooldown = 0.0
	#attack_cooldown = attack_cooldown_duration
	#var current_time = Time.get_ticks_msec()
	#if not is_attacking or (current_time - last_attack_time) > combo_window_ms:
		#attack_combo_count = 1; change_state(State.ATTACK_1)
	#elif is_attacking:
		#match attack_combo_count:
			#1: attack_combo_count = 2; change_state(State.ATTACK_2)
			#2: attack_combo_count = 3; change_state(State.ATTACK_3)
			#3: attack_combo_count = 4; change_state(State.HEAVY_ATTACK)
			#_: attack_combo_count = 1; change_state(State.ATTACK_1)
	#is_attacking = true; last_attack_time = current_time
#
#func perform_heavy_attack() -> void:
	#attack_cooldown = max(attack_cooldown, heavy_attack_recovery + attack_cooldown_duration)
	#attack_input_buffer = false; attack_input_cooldown = heavy_attack_recovery
	#attack_combo_count = 4; change_state(State.HEAVY_ATTACK)
	#is_attacking = true; last_attack_time = Time.get_ticks_msec()
#
## ===== CONDITION CHECKS =====
#func can_attack() -> bool: return is_on_floor() and attack_cooldown <= 0
#func can_air_attack() -> bool: return not is_on_floor() and current_state != State.AIR_ATTACK and attack_cooldown <= 0 and air_attack_cooldown <= 0.0 and not has_air_attacked
#func can_heavy_attack() -> bool: return current_state in [State.IDLE, State.RUNNING, State.LANDING, State.GUARD]
#func can_air_action() -> bool: return not is_on_floor() and current_state in [State.JUMPING, State.FALLING] and has_air_action
#func can_guard() -> bool: return current_state in [State.IDLE, State.RUNNING, State.DASHING , State.LANDING]
#
## ===== STATE TRANSITION SYSTEM =====
#func change_state(new_state: State) -> void:
	#if current_state == new_state: return
	#if current_state == State.HEAVY_ATTACK and heavy_phase != HeavyPhase.RECOVERY: return
	#exit_current_state(new_state); current_state = new_state; enter_new_state(new_state)
#
#func exit_current_state(new_state: State) -> void:
	#match current_state:
		#State.LANDING: landing_timer = 0.0
		#State.ATTACK_1, State.ATTACK_2, State.ATTACK_3:
			#attack_timer = 0.0
			#if new_state not in [State.ATTACK_1, State.ATTACK_2, State.ATTACK_3, State.HEAVY_ATTACK]:
				#attack_combo_count = 0; is_attacking = false
		#State.HEAVY_ATTACK:
			#heavy_phase = HeavyPhase.DROP; heavy_phase_timer = 0.0
			#if new_state not in [State.ATTACK_1, State.ATTACK_2, State.ATTACK_3, State.HEAVY_ATTACK]:
				#attack_combo_count = 0; is_attacking = false
		#State.UPPER_ATTACK: upper_attack_timer = 0.0
		#State.AIR_ACTION: air_action_timer = 0.0
		#State.AIR_ATTACK: air_attack_timer = 0.0
		#State.TURNING_AROUND: turning_timer = 0.0
		#State.TURNING_AROUND_WHILE_RUNNING: turning_while_running_timer = 0.0
		#State.STOPPING: stopping_timer = 0.0
		#State.WALL_CLING: wall_cling_timer = 0.0
		#State.HEAL_START: heal_start_timer = 0.0
		#State.HEAL_END: heal_end_timer = 0.0
		#State.HEAL_LOOP: is_healing = false; heal_loop_timer = 0.0
		#State.GUARD: heal_loop_timer = 0.0
#
#func enter_new_state(new_state: State) -> void:
	#can_combo = new_state in [State.ATTACK_1, State.ATTACK_2, State.ATTACK_3]
	#set_state_timer(new_state); play_animation(get_animation_name(new_state))
	#if new_state == State.HEAL_START or new_state == State.HEAL_LOOP: is_healing = true
	#if new_state == State.HEAVY_ATTACK: heavy_phase = HeavyPhase.DROP; heavy_phase_timer = 0.0
#
#func get_animation_name(state: State) -> String:
	#match state:
		#State.IDLE: return "Idle"
		#State.RUNNING: return "Running"
		#State.DASHING: return "Dashing"
		#State.JUMPING: return "Jumping"
		#State.FALLING: return "Falling"
		#State.LANDING: return "Landing"
		##State.ATTACK_1: return "1st attack"
		##State.ATTACK_2: return "2nd attack"
		##State.ATTACK_3: return "3rd attack"
		##State.HEAVY_ATTACK: return "Heavy attack"
		#State.UPPER_ATTACK: return "Upper attack"
		#State.AIR_ACTION: return "Air action"
		#State.AIR_ATTACK: return "Air attack"
		#State.GUARD: return "Guard"
		#State.HEAL_START: return "Heal start"
		#State.HEAL_LOOP: return "Heal loop"
		#State.HEAL_END: return "Heal end"
		#State.TURNING_AROUND: return "Turning around"
		#State.TURNING_AROUND_WHILE_RUNNING: return "Turning around while running"
		#State.STOPPING: return "Stopping"
		#State.WALL_CLING: return "Wall cling"
		#_: return ""
#
#func set_state_timer(state: State) -> void:
	#match state:
		#State.LANDING: landing_timer = landing_duration
		#State.ATTACK_1, State.ATTACK_2, State.ATTACK_3: attack_timer = attack_duration
		#State.UPPER_ATTACK: upper_attack_timer = upper_attack_duration
		#State.AIR_ACTION: air_action_timer = air_action_duration
		#State.AIR_ATTACK: air_attack_timer = air_attack_duration
		#State.TURNING_AROUND: turning_timer = turning_duration
		#State.TURNING_AROUND_WHILE_RUNNING: turning_while_running_timer = turning_while_running_duration
		#State.STOPPING: stopping_timer = stopping_duration
		#State.WALL_CLING: wall_cling_timer = wall_cling_duration
		#State.HEAL_START: heal_start_timer = heal_start_duration
		#State.HEAL_END: heal_end_timer = heal_end_duration
#
#func play_animation(animation_name: String) -> void:
	#if animated_sprite_3d and animated_sprite_3d.sprite_frames:
		#if animated_sprite_3d.animation == animation_name and animated_sprite_3d.is_playing():
			#return
			#
		#if animated_sprite_3d.sprite_frames.has_animation(animation_name):
			#animated_sprite_3d.play(animation_name)
		#else:
			#var fallback = animation_name.to_lower()
			#if animated_sprite_3d.sprite_frames.has_animation(fallback): 
				#animated_sprite_3d.play(fallback)
			#elif animated_sprite_3d.sprite_frames.has_animation("Idle"): 
				#animated_sprite_3d.play("Idle")
#
#
#func _handle_hit_properties():
	##print(current_state)
	#if current_state == State.ATTACK_1:
		#attack_to_do = "1st attack " + current_direction
		##if not $attack_handler.is_playing(): # Prevents loop!
		#$attack_handler.active = true
		#$attack_handler.play(attack_to_do)
	#elif current_state == State.ATTACK_2:
		#attack_to_do = "2nd attack " + current_direction
		##if not $attack_handler.is_playing(): # Prevents loop!
		#$attack_handler.active = true
		#$attack_handler.play(attack_to_do)
	#elif current_state == State.ATTACK_3:
		#attack_to_do = "3rd attack " + current_direction
		##if not $attack_handler.is_playing(): # Prevents loop!
		#$attack_handler.active = true
		#$attack_handler.play(attack_to_do)
	#elif current_state == State.HEAVY_ATTACK:
		#attack_to_do = "Heavy attack " + current_direction
		##if not $attack_handler.is_playing(): # Prevents loop!
		#$attack_handler.active = true
		#$attack_handler.play(attack_to_do)
#
#
#
#
	#
#
#
#func _on_attack_handler_animation_finished(anim_name: StringName) -> void:
	#$attack_handler.stop() # Make sure nothing loops again
	##$attack_handler.active = false # AnimationPlayer no longer controls visuals
	#animated_sprite_3d.play("Idle") 
	##print("deactivated")
#
#
#func _on_hitbox_left_body_entered(body: Node3D) -> void:
	#if body.is_in_group("Player") and not body.is_in_group("main_sonic") :
		#print(damage)
#
#
#func _on_hitbox_right_body_entered(body: Node3D) -> void:
	#if body.is_in_group("Player") and not body.is_in_group("main_sonic") :
		#print(damage)

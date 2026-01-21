extends CharacterBody3D

# State Machine
enum State {
	IDLE, RUNNING, JUMPING, FALLING, LANDING,
	ATTACK_1, ATTACK_2, ATTACK_3, HEAVY_ATTACK, UPPER_ATTACK,
	AIR_ACTION, AIR_ATTACK, PURSUIT_ATTACK,
	GUARD, HEAL_START, HEAL_LOOP, HEAL_END,
	TURNING_AROUND, STOPPING
}

var current_state: State = State.IDLE

# ===== MODULAR CONFIGURATION SECTION ===== #
#region Modular Config Variables -----
# All tunable parameters are now in one easy-to-find section

# Movement Configuration
@export_category("Movement Settings")
@export var max_speed: float = 8.0
@export var acceleration: float = 0.5
@export var friction: float = 0.4
@export var air_control_factor: float = 0.33  # How much control in air (0.0-1.0)

# Jump Configuration
@export_category("Jump Settings")
@export var jump_force: float = 4.5
@export var air_action_force: float = 8.0
@export var air_action_upward_boost: float = 2.0

# Combat Configuration
@export_category("Combat Settings")
@export var attack_cooldown_duration: float = 0.3
@export var combo_window_ms: int = 500  # milliseconds
@export var input_buffer_duration: float = 0.1
# Extra recovery for heavy attack to make it feel slower and reduce spam
@export var heavy_attack_recovery: float = 0.5
# Upward lift applied right after heavy attack finishes
@export var heavy_attack_lift: float = 2.0
# Horizontal knockback applied when performing a heavy attack
@export var heavy_attack_knockback: float = 3.0
# New: Leftward force applied during landing after heavy attack
@export var heavy_attack_landing_force: float = 3.0
# New: Horizontal gravity applied leftward after heavy attack
@export var heavy_attack_horizontal_gravity: float = 2.0
# Separate cooldown for air attack to prevent spamming in the air
@export var air_attack_cooldown_duration: float = 0.6

# State Duration Configuration
@export_category("State Durations")
@export var landing_duration: float = 0.2
@export var attack_duration: float = 0.4
# Increased heavy attack duration to make it feel slower
@export var heavy_attack_duration: float = 1.2
@export var upper_attack_duration: float = 0.4
@export var air_action_duration: float = 0.4
@export var air_attack_duration: float = 0.3
@export var pursuit_attack_duration: float = 0.4
@export var turning_duration: float = 0.15
@export var stopping_duration: float = 0.2
@export var heal_start_duration: float = 0.3
@export var heal_loop_duration: float = 1.0
@export var heal_end_duration: float = 0.3

# Animation Configuration
@export_category("Animation Settings")
@onready var animated_sprite_3d: AnimatedSprite3D = $AnimatedSprite3D
#endregion

# ===== INTERNAL VARIABLES =====
#region Internal Variables
# Timers
var landing_timer: float = 0.0
var attack_timer: float = 0.0
var heavy_attack_timer: float = 0.0
var upper_attack_timer: float = 0.0
var air_action_timer: float = 0.0
var air_attack_timer: float = 0.0
var pursuit_attack_timer: float = 0.0
var turning_timer: float = 0.0
var stopping_timer: float = 0.0
var heal_start_timer: float = 0.0
var heal_loop_timer: float = 0.0
var heal_end_timer: float = 0.0

# Combat System
var attack_combo_count: int = 0
var can_combo: bool = false
var is_attacking: bool = false
var last_attack_time: int = 0
var is_healing: bool = false
var has_air_action: bool = true
var has_air_attacked: bool = false  # Limits air attack to once per air time
var was_heavy_attack: bool = false  # New: Tracks if last attack was heavy
var attack_cooldown: float = 0.0
var air_attack_cooldown: float = 0.0

# Input buffering
var attack_input_buffer: bool = false
var attack_input_cooldown: float = 0.0

# Direction tracking
var last_input_direction: Vector2 = Vector2.ZERO
var current_facing_direction: int = 1  # 1 for right, -1 for left

# Physics
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
#endregion

# ===== INITIALIZATION =====
func _ready() -> void:
	validate_animations()
	change_state(State.IDLE)

func validate_animations() -> void:
	if animated_sprite_3d and animated_sprite_3d.sprite_frames:
		var animations = animated_sprite_3d.sprite_frames.get_animation_names()
		print("=== AVAILABLE ANIMATIONS ===")
		for anim in animations:
			print(" - '", anim, "'")
		print("=============================")
		
		var critical_anims = ["Air Action", "Air Attack ", "Heavy Attack"]
		for anim_name in critical_anims:
			if animated_sprite_3d.sprite_frames.has_animation(anim_name):
				print("SUCCESS: '", anim_name, "' animation found!")
			else:
				print("ERROR: '", anim_name, "' animation NOT found in SpriteFrames!")
	else:
		print("ERROR: No SpriteFrames resource assigned to AnimatedSprite3D!")

# ===== MAIN PROCESS =====
func _physics_process(delta: float) -> void:
	update_cooldowns(delta)
	apply_gravity(delta)
	handle_attack_input()
	handle_state(delta)
	move_and_slide()

func update_cooldowns(delta: float) -> void:
	if attack_cooldown > 0:
		attack_cooldown -= delta
	
	if attack_input_cooldown > 0:
		attack_input_cooldown -= delta
		if attack_input_cooldown <= 0:
			attack_input_buffer = false

	if air_attack_cooldown > 0:
		air_attack_cooldown -= delta
		if air_attack_cooldown < 0:
			air_attack_cooldown = 0.0

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
		# Apply horizontal gravity leftward after heavy attack
		if was_heavy_attack:
			velocity.x -= heavy_attack_horizontal_gravity * delta

# ===== INPUT HANDLING =====
func handle_attack_input() -> void:
	if current_state in [State.HEAVY_ATTACK, State.AIR_ATTACK] or heavy_attack_timer > 0.0 or air_attack_cooldown > 0.0:
		return

	if Input.is_action_just_pressed("p"):
		process_attack_input()
	
	process_buffered_attack()

func process_attack_input() -> void:
	if not is_on_floor() and can_air_attack():
		perform_air_attack()
		return
	elif is_on_floor() and can_attack():
		handle_combo_attack()
		return
	else:
		attack_input_buffer = true
		attack_input_cooldown = input_buffer_duration

func process_buffered_attack() -> void:
	if current_state in [State.HEAVY_ATTACK, State.AIR_ATTACK] or heavy_attack_timer > 0.0 or air_attack_cooldown > 0.0:
		return

	if attack_input_buffer and attack_cooldown <= 0:
		if not is_on_floor() and can_air_attack():
			perform_air_attack()
		elif is_on_floor() and can_attack():
			handle_combo_attack()

# ===== STATE MANAGEMENT =====
func handle_state(delta: float) -> void:
	var input_dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	update_facing_direction(input_dir)
	handle_special_inputs(input_dir)
	
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	match current_state:
		State.IDLE:
			handle_idle_state(delta, input_dir, direction)
		State.RUNNING:
			handle_running_state(delta, input_dir, direction)
		State.JUMPING:
			handle_jumping_state(delta, direction)
		State.FALLING:
			handle_falling_state(delta, direction)
		State.LANDING:
			handle_landing_state(delta, input_dir)
		State.ATTACK_1, State.ATTACK_2, State.ATTACK_3:
			handle_attack_state(delta, input_dir)
		State.HEAVY_ATTACK:
			handle_heavy_attack_state(delta, input_dir)
		State.UPPER_ATTACK:
			handle_upper_attack_state(delta, input_dir)
		State.AIR_ACTION:
			handle_air_action_state(delta, direction)
		State.AIR_ATTACK:
			handle_air_attack_state(delta, direction)
		State.PURSUIT_ATTACK:
			handle_pursuit_attack_state(delta, direction)
		State.GUARD:
			handle_guard_state(delta, input_dir)
		State.HEAL_START:
			handle_heal_start_state(delta)
		State.HEAL_LOOP:
			handle_heal_loop_state()
		State.HEAL_END:
			handle_heal_end_state(delta, input_dir)
		State.TURNING_AROUND:
			handle_turning_around_state(delta, input_dir)
		State.STOPPING:
			handle_stopping_state(delta, input_dir)
	
	if input_dir != Vector2.ZERO:
		last_input_direction = input_dir

func update_facing_direction(input_dir: Vector2) -> void:
	if input_dir.x != 0:
		current_facing_direction = 1 if input_dir.x > 0 else -1
	if animated_sprite_3d:
		animated_sprite_3d.flip_h = current_facing_direction == -1

func handle_special_inputs(input_dir: Vector2) -> void:
	if current_state in [State.HEAVY_ATTACK, State.AIR_ATTACK] or heavy_attack_timer > 0.0:
		return

	if Input.is_action_just_pressed("shift") and can_guard():
		change_state(State.GUARD)
	
	if Input.is_action_just_pressed("ui_accept"):
		if is_on_floor() and current_state in [State.IDLE, State.RUNNING]:
			jump()
		elif can_air_action():
			perform_air_action(input_dir)

# ===== STATE HANDLERS =====
func handle_idle_state(delta: float, input_dir: Vector2, direction: Vector3) -> void:
	apply_friction()
	if input_dir != Vector2.ZERO:
		if last_input_direction.x != 0 and input_dir.x != 0 and sign(last_input_direction.x) != sign(input_dir.x):
			change_state(State.TURNING_AROUND)
		else:
			change_state(State.RUNNING)
	if not is_on_floor():
		change_state(State.FALLING)

func handle_running_state(delta: float, input_dir: Vector2, direction: Vector3) -> void:
	apply_movement(direction)
	if last_input_direction.x != 0 and input_dir.x != 0 and sign(last_input_direction.x) != sign(input_dir.x):
		change_state(State.TURNING_AROUND)
	elif input_dir == Vector2.ZERO:
		change_state(State.STOPPING)
	elif not is_on_floor():
		change_state(State.FALLING)

func handle_jumping_state(delta: float, direction: Vector3) -> void:
	apply_air_control(direction)
	if velocity.y < 0:
		change_state(State.FALLING)

func handle_falling_state(delta: float, direction: Vector3) -> void:
	apply_air_control(direction)
	if is_on_floor():
		change_state(State.LANDING)

func handle_landing_state(delta: float, input_dir: Vector2) -> void:
	apply_friction()
	# Apply leftward force during landing if last attack was heavy
	if was_heavy_attack:
		velocity.x -= heavy_attack_landing_force * delta
	landing_timer -= delta
	if landing_timer <= 0:
		has_air_action = true
		has_air_attacked = false
		was_heavy_attack = false  # Reset heavy attack flag on landing
		attack_combo_count = 0
		is_attacking = false
		if input_dir != Vector2.ZERO:
			change_state(State.RUNNING)
		else:
			change_state(State.IDLE)

func handle_attack_state(delta: float, input_dir: Vector2) -> void:
	apply_friction()
	attack_timer -= delta
	
	if Input.is_action_just_pressed("p") and attack_timer > 0.1:
		attack_input_buffer = true
		attack_input_cooldown = input_buffer_duration
	
	if attack_timer <= 0:
		is_attacking = false
		if not is_on_floor():
			change_state(State.FALLING)
		elif input_dir != Vector2.ZERO:
			change_state(State.RUNNING)
		else:
			change_state(State.IDLE)

func handle_heavy_attack_state(delta: float, input_dir: Vector2) -> void:
	apply_friction()
	if Input.is_action_just_pressed("p"):
		attack_input_buffer = false
		attack_input_cooldown = heavy_attack_recovery

	heavy_attack_timer -= delta
	if heavy_attack_timer <= 0:
		attack_combo_count = 0
		is_attacking = false
		was_heavy_attack = true  # Set flag to influence landing and gravity
		velocity.y = heavy_attack_lift
		change_state(State.FALLING)

func handle_upper_attack_state(delta: float, input_dir: Vector2) -> void:
	apply_friction()
	upper_attack_timer -= delta
	if upper_attack_timer <= 0:
		if not is_on_floor():
			change_state(State.FALLING)
		elif input_dir != Vector2.ZERO:
			change_state(State.RUNNING)
		else:
			change_state(State.IDLE)

func handle_air_action_state(delta: float, direction: Vector3) -> void:
	if direction:
		velocity.x = move_toward(velocity.x, direction.x * max_speed, acceleration / 2.0)
		velocity.z = move_toward(velocity.z, direction.z * max_speed, acceleration / 2.0)
	
	air_action_timer -= delta
	if air_action_timer <= 0:
		change_state(State.FALLING)

func handle_air_attack_state(delta: float, direction: Vector3) -> void:
	apply_air_control(direction)
	air_attack_timer -= delta
	if air_attack_timer <= 0:
		is_attacking = false
		attack_combo_count = 0
		attack_input_buffer = false
		attack_input_cooldown = 0.0
		if is_on_floor():
			change_state(State.IDLE)
		else:
			change_state(State.FALLING)

func handle_pursuit_attack_state(delta: float, direction: Vector3) -> void:
	apply_air_control(direction)
	pursuit_attack_timer -= delta
	if pursuit_attack_timer <= 0:
		change_state(State.FALLING)

func handle_guard_state(delta: float, input_dir: Vector2) -> void:
	apply_friction()
	if Input.is_action_pressed("shift"):
		heal_loop_timer += delta
		if heal_loop_timer >= heal_loop_duration and not is_healing:
			change_state(State.HEAL_START)
	else:
		heal_loop_timer = 0.0
		if not is_on_floor():
			change_state(State.FALLING)
		elif input_dir != Vector2.ZERO:
			change_state(State.RUNNING)
		else:
			change_state(State.IDLE)
	if Input.is_action_just_pressed("p") and can_heavy_attack():
		perform_heavy_attack()

func handle_heal_start_state(delta: float) -> void:
	apply_friction()
	heal_start_timer -= delta
	if heal_start_timer <= 0:
		change_state(State.HEAL_LOOP)

func handle_heal_loop_state() -> void:
	apply_friction()
	if not Input.is_action_pressed("shift"):
		change_state(State.HEAL_END)

func handle_heal_end_state(delta: float, input_dir: Vector2) -> void:
	apply_friction()
	heal_end_timer -= delta
	if heal_end_timer <= 0:
		is_healing = false
		if not is_on_floor():
			change_state(State.FALLING)
		elif input_dir != Vector2.ZERO:
			change_state(State.RUNNING)
		else:
			change_state(State.IDLE)

func handle_turning_around_state(delta: float, input_dir: Vector2) -> void:
	apply_friction()
	turning_timer -= delta
	if turning_timer <= 0:
		if input_dir != Vector2.ZERO:
			change_state(State.RUNNING)
		else:
			change_state(State.IDLE)

func handle_stopping_state(delta: float, input_dir: Vector2) -> void:
	apply_friction()
	stopping_timer -= delta
	if stopping_timer <= 0:
		change_state(State.IDLE)
	elif input_dir != Vector2.ZERO:
		if last_input_direction.x != 0 and sign(input_dir.x) != sign(last_input_direction.x):
			change_state(State.TURNING_AROUND)
		else:
			change_state(State.RUNNING)

# ===== MOVEMENT FUNCTIONS =====
func apply_movement(direction: Vector3) -> void:
	if direction:
		velocity.x = move_toward(velocity.x, direction.x * max_speed, acceleration)
		velocity.z = move_toward(velocity.z, direction.z * max_speed, acceleration)
	else:
		apply_friction()

func apply_friction() -> void:
	velocity.x = move_toward(velocity.x, 0, friction)
	velocity.z = move_toward(velocity.z, 0, friction)

func apply_air_control(direction: Vector3) -> void:
	if direction:
		var air_acceleration = acceleration * air_control_factor
		velocity.x = move_toward(velocity.x, direction.x * max_speed, air_acceleration)
		velocity.z = move_toward(velocity.z, direction.z * max_speed, air_acceleration)

# ===== ACTION FUNCTIONS =====
func jump() -> void:
	velocity.y = jump_force
	change_state(State.JUMPING)

func perform_air_action(input_dir: Vector2) -> void:
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction == Vector3.ZERO:
		direction = Vector3(current_facing_direction, 0, 0)
	velocity.x = direction.x * air_action_force
	velocity.z = direction.z * air_action_force
	velocity.y = air_action_upward_boost
	has_air_action = false
	change_state(State.AIR_ACTION)

func perform_air_attack() -> void:
	attack_input_buffer = false
	attack_input_cooldown = 0.0
	attack_cooldown = max(attack_cooldown, attack_cooldown_duration + air_attack_duration)
	air_attack_cooldown = air_attack_cooldown_duration
	has_air_attacked = true
	change_state(State.AIR_ATTACK)
	is_attacking = true
	last_attack_time = Time.get_ticks_msec()

# ===== COMBAT FUNCTIONS =====
func handle_combo_attack() -> void:
	attack_input_buffer = false
	attack_input_cooldown = 0.0
	attack_cooldown = attack_cooldown_duration
	was_heavy_attack = false  # Reset heavy attack flag for non-heavy attacks
	
	var current_time = Time.get_ticks_msec()
	
	if not is_attacking or (current_time - last_attack_time) > combo_window_ms:
		attack_combo_count = 1
		change_state(State.ATTACK_1)
	elif is_attacking:
		match attack_combo_count:
			1:
				attack_combo_count = 2
				change_state(State.ATTACK_2)
			2:
				attack_combo_count = 3
				change_state(State.ATTACK_3)
			3:
				attack_combo_count = 4
				change_state(State.HEAVY_ATTACK)
			_:
				attack_combo_count = 1
				change_state(State.ATTACK_1)
	
	is_attacking = true
	last_attack_time = current_time

func perform_heavy_attack() -> void:
	var desired_cooldown = heavy_attack_recovery + attack_cooldown_duration
	attack_cooldown = max(attack_cooldown, desired_cooldown)
	attack_input_buffer = false
	attack_input_cooldown = heavy_attack_recovery
	attack_combo_count = 4
	change_state(State.HEAVY_ATTACK)
	is_attacking = true
	last_attack_time = Time.get_ticks_msec()
	velocity.x += -current_facing_direction * heavy_attack_knockback

# ===== CONDITION CHECKS =====
func can_attack() -> bool:
	return is_on_floor() and attack_cooldown <= 0 and heavy_attack_timer <= 0.0

func can_air_attack() -> bool:
	return not is_on_floor() and current_state != State.AIR_ATTACK and attack_cooldown <= 0 and heavy_attack_timer <= 0.0 and air_attack_cooldown <= 0.0 and not has_air_attacked

func can_heavy_attack() -> bool:
	return current_state in [State.IDLE, State.RUNNING, State.LANDING, State.GUARD]

func can_air_action() -> bool:
	return current_state in [State.JUMPING, State.FALLING] and has_air_action

func can_guard() -> bool:
	return current_state in [State.IDLE, State.RUNNING, State.LANDING]

# ===== STATE TRANSITION SYSTEM =====
func change_state(new_state: State) -> void:
	if current_state == new_state:
		return
	
	if current_state == State.HEAVY_ATTACK and heavy_attack_timer > 0.0 and new_state != State.HEAVY_ATTACK:
		return

	exit_current_state(new_state)
	current_state = new_state
	enter_new_state(new_state)

func exit_current_state(new_state: State) -> void:
	match current_state:
		State.LANDING:
			landing_timer = 0.0
		State.ATTACK_1, State.ATTACK_2, State.ATTACK_3:
			attack_timer = 0.0
			if new_state not in [State.ATTACK_1, State.ATTACK_2, State.ATTACK_3, State.HEAVY_ATTACK]:
				attack_combo_count = 0
				is_attacking = false
		State.HEAVY_ATTACK:
			heavy_attack_timer = 0.0
			if new_state not in [State.ATTACK_1, State.ATTACK_2, State.ATTACK_3, State.HEAVY_ATTACK]:
				attack_combo_count = 0
				is_attacking = false
		State.UPPER_ATTACK:
			upper_attack_timer = 0.0
		State.AIR_ACTION:
			air_action_timer = 0.0
		State.AIR_ATTACK:
			air_attack_timer = 0.0
		State.PURSUIT_ATTACK:
			pursuit_attack_timer = 0.0
		State.TURNING_AROUND:
			turning_timer = 0.0
		State.STOPPING:
			stopping_timer = 0.0
		State.HEAL_START:
			heal_start_timer = 0.0
		State.HEAL_END:
			heal_end_timer = 0.0
		State.HEAL_LOOP:
			is_healing = false
			heal_loop_timer = 0.0
		State.GUARD:
			heal_loop_timer = 0.0

func enter_new_state(new_state: State) -> void:
	can_combo = new_state in [State.ATTACK_1, State.ATTACK_2, State.ATTACK_3]
	
	var animation_name = get_animation_name(new_state)
	set_state_timer(new_state)
	play_animation(animation_name)

func get_animation_name(state: State) -> String:
	match state:
		State.IDLE: return "Idle"
		State.RUNNING: return "Running"
		State.JUMPING: return "Jumping"
		State.FALLING: return "Falling"
		State.LANDING: return "Landing"
		State.ATTACK_1: return "1st Attack"
		State.ATTACK_2: return "2nd Attack"
		State.ATTACK_3: return "3rd Attack"
		State.HEAVY_ATTACK: return "Heavy Attack"
		State.UPPER_ATTACK: return "Upper Attack"
		State.AIR_ACTION: return "Air Action"
		State.AIR_ATTACK: return "Air Attack "
		State.PURSUIT_ATTACK: return "Pursuit Attack"
		State.GUARD: return "Guard"
		State.HEAL_START: return "Heal Start"
		State.HEAL_LOOP: return "Heal Loop"
		State.HEAL_END: return "Heal End"
		State.TURNING_AROUND: return "Turning Around "
		State.STOPPING: return "Stopping"
		_: return ""

func set_state_timer(state: State) -> void:
	match state:
		State.LANDING: landing_timer = landing_duration
		State.ATTACK_1, State.ATTACK_2, State.ATTACK_3: attack_timer = attack_duration
		State.HEAVY_ATTACK: heavy_attack_timer = heavy_attack_duration
		State.UPPER_ATTACK: upper_attack_timer = upper_attack_duration
		State.AIR_ACTION: air_action_timer = air_action_duration
		State.AIR_ATTACK: air_attack_timer = air_attack_duration
		State.PURSUIT_ATTACK: pursuit_attack_timer = pursuit_attack_duration
		State.TURNING_AROUND: turning_timer = turning_duration
		State.STOPPING: stopping_timer = stopping_duration
		State.HEAL_START: 
			heal_start_timer = heal_start_duration
			is_healing = true
		State.HEAL_END: heal_end_timer = heal_end_duration

func play_animation(animation_name: String) -> void:
	if animated_sprite_3d and animated_sprite_3d.sprite_frames:
		if animated_sprite_3d.sprite_frames.has_animation(animation_name):
			animated_sprite_3d.play(animation_name)
		else:
			if animated_sprite_3d.sprite_frames.has_animation("Idle"):
				animated_sprite_3d.play("Idle")

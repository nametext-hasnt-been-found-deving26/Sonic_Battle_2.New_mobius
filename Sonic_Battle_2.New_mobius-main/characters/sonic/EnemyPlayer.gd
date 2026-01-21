# EnemyAI.gd
extends CharacterBody3D

enum State { 
	IDLE, CHASING, 
	ATTACK_1, ATTACK_2, ATTACK_3, HEAVY_ATTACK, 
	RECOVERING, JUMPING, FALLING, AIR_ACTION 
}

var current_state: State = State.IDLE
@onready var animated_sprite_3d: AnimatedSprite3D = $AnimatedSprite3D
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

# Physics - Match player's system
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var current_facing = 1

# Timers
var attack_cooldown = 0.0
var state_timer = 0.0
var recovery_attempts = 0
var attack_combo_count = 0
var combo_decision = 0
var jump_check_timer = 0.0
var air_action_timer = 0.0

# Movement - Tuned to match player movement feel
const CHASE_SPEED = 6.0
const ACCELERATION = 0.4
const FRICTION = 0.3

# Jump & Air
const JUMP_FORCE = 4.5  # Match player's jump
const AIR_ACTION_FORCE = 8.0  # Match player's air action
const AIR_ACTION_UPWARD_BOOST = 2.0
const AIR_CONTROL_FACTOR = 0.33
var has_air_action = true

# Combat
const ATTACK_DISTANCE = 2.5
const MIN_SAFE_DISTANCE = 4.0
const DETECTION_RANGE = 12.0
const ATTACK_DAMAGE = 10
const MAX_RECOVERY_ATTEMPTS = 3
const ATTACK_DURATION = 0.4
const HEAVY_ATTACK_DURATION = 0.6
const AIR_ACTION_DURATION = 0.4

# Pathfinding
const PATH_UPDATE_RATE = 0.2  # Update path 5 times per second
const JUMP_CHECK_RATE = 0.5  # Check if jump needed twice per second
const WALL_DETECT_DISTANCE = 2.0
var path_update_timer = 0.0
var player_ref: CharacterBody3D = null

func _ready():
	# Setup NavigationAgent
	if navigation_agent:
		navigation_agent.path_desired_distance = 0.5
		navigation_agent.target_desired_distance = 0.5
		navigation_agent.max_speed = CHASE_SPEED
		# Wait for navigation to be ready
		call_deferred("_setup_navigation")
	
	# Find player on spawn
	player_ref = _find_player()
	if player_ref:
		print("Enemy found player: ", player_ref.name)
	else:
		print("WARNING: Enemy could not find player!")

func _setup_navigation():
	await get_tree().physics_frame
	if player_ref and navigation_agent:
		navigation_agent.target_position = player_ref.global_position

func _physics_process(delta):
	# Update timers
	if attack_cooldown > 0: 
		attack_cooldown -= delta
	if state_timer > 0: 
		state_timer -= delta
	if path_update_timer > 0:
		path_update_timer -= delta
	if jump_check_timer > 0:
		jump_check_timer -= delta
	
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0
		has_air_action = true  # Reset air action on landing
	
	# Get target (cache player reference)
	if not player_ref or not is_instance_valid(player_ref):
		player_ref = _find_player()
	
	if not player_ref:
		_change_state(State.IDLE)
		_apply_friction(delta)
		move_and_slide()
		return
	
	# Update navigation path periodically
	if navigation_agent and path_update_timer <= 0:
		navigation_agent.target_position = player_ref.global_position
		path_update_timer = PATH_UPDATE_RATE
	
	var dist = global_position.distance_to(player_ref.global_position)
	var to_player = (player_ref.global_position - global_position)
	var direction_2d = Vector2(to_player.x, to_player.z).normalized()
	
	# Face player
	if abs(direction_2d.x) > 0.1:
		current_facing = 1 if direction_2d.x > 0 else -1
		if animated_sprite_3d:
			animated_sprite_3d.flip_h = current_facing == -1
	
	# === STATE MACHINE ===
	match current_state:
		State.IDLE:
			_handle_idle_state(delta, dist)
		State.CHASING:
			_handle_chasing_state(delta, dist, direction_2d, to_player)
		State.JUMPING:
			_handle_jumping_state(delta, direction_2d)
		State.FALLING:
			_handle_falling_state(delta, direction_2d, dist, to_player)
		State.AIR_ACTION:
			_handle_air_action_state(delta, direction_2d)
		State.ATTACK_1:
			_handle_attack_state(delta, player_ref, direction_2d, 1)
		State.ATTACK_2:
			_handle_attack_state(delta, player_ref, direction_2d, 2)
		State.ATTACK_3:
			_handle_attack_state(delta, player_ref, direction_2d, 3)
		State.HEAVY_ATTACK:
			_handle_heavy_attack_state(delta, player_ref, direction_2d)
		State.RECOVERING:
			_handle_recovering_state(delta, dist, direction_2d)
	
	move_and_slide()

# ===== STATE HANDLERS =====
func _handle_idle_state(delta: float, dist: float):
	_apply_friction(delta)
	_play_anim("Idle")
	
	if dist < DETECTION_RANGE:
		_change_state(State.CHASING)
	
	if not is_on_floor():
		_change_state(State.FALLING)

func _handle_chasing_state(delta: float, dist: float, direction_2d: Vector2, to_player: Vector3):
	# Check if we should attack (only on ground)
	if is_on_floor() and dist < ATTACK_DISTANCE and attack_cooldown <= 0:
		combo_decision = randi() % 4 + 1
		attack_combo_count = 1
		_change_state(State.ATTACK_1)
		return
	
	# Check if player is too far
	if dist > DETECTION_RANGE * 1.5:
		_change_state(State.IDLE)
		return
	
	# Check if we fell
	if not is_on_floor():
		_change_state(State.FALLING)
		return
	
	# === PATHFINDING & JUMP LOGIC ===
	var move_direction = direction_2d
	
	# Use NavigationAgent if available
	if navigation_agent and not navigation_agent.is_navigation_finished():
		var next_path_position = navigation_agent.get_next_path_position()
		var direction_to_next = (next_path_position - global_position)
		move_direction = Vector2(direction_to_next.x, direction_to_next.z).normalized()
	
	# Check if we need to jump
	if jump_check_timer <= 0:
		jump_check_timer = JUMP_CHECK_RATE
		
		# Jump if player is significantly above us
		var height_diff = player_ref.global_position.y - global_position.y
		if height_diff > 2.0 and dist < 8.0:
			_jump()
			return
		
		# Jump if we're stuck against a wall
		if _is_blocked_by_wall(move_direction):
			_jump()
			return
	
	# Move toward target
	var target_velocity_x = move_direction.x * CHASE_SPEED
	var target_velocity_z = move_direction.y * CHASE_SPEED
	
	velocity.x = move_toward(velocity.x, target_velocity_x, ACCELERATION)
	velocity.z = move_toward(velocity.z, target_velocity_z, ACCELERATION)
	
	_play_anim("Running")

func _handle_jumping_state(delta: float, direction_2d: Vector2):
	# Air control while jumping
	_apply_air_control(delta, direction_2d)
	_play_anim("Jumping")
	
	# Check if we landed early
	if is_on_floor():
		_change_state(State.CHASING)
	elif velocity.y < 0:
		_change_state(State.FALLING)

func _handle_falling_state(delta: float, direction_2d: Vector2, dist: float, to_player: Vector3):
	# Air control while falling
	_apply_air_control(delta, direction_2d)
	_play_anim("Falling")
	
	# Check if we should use air action to chase player
	if has_air_action and dist > 5.0 and dist < 10.0:
		# Player is at medium distance - use air action to close gap
		var height_diff = player_ref.global_position.y - global_position.y
		if abs(height_diff) < 3.0:  # Only if roughly same height
			_perform_air_action(direction_2d)
			return
	
	if is_on_floor():
		_change_state(State.CHASING)

func _handle_air_action_state(delta: float, direction_2d: Vector2):
	# Limited air control during air action
	_apply_air_control(delta, direction_2d, 0.5)
	_play_anim("Air action")
	
	air_action_timer -= delta
	
	# Always check if we landed during air action
	if is_on_floor():
		_change_state(State.CHASING)
	elif air_action_timer <= 0:
		_change_state(State.FALLING)

func _handle_attack_state(delta: float, target: CharacterBody3D, direction_2d: Vector2, attack_num: int):
	# Stop moving during attack
	velocity.x = move_toward(velocity.x, 0, FRICTION * 2.0)
	velocity.z = move_toward(velocity.z, 0, FRICTION * 2.0)
	
	# Play appropriate animation
	match attack_num:
		1: _play_anim("1st attack")
		2: _play_anim("2nd attack")
		3: _play_anim("3rd attack")
	
	# Check if we fell off a ledge during attack
	if not is_on_floor():
		attack_combo_count = 0
		_change_state(State.FALLING)
		return
	
	if state_timer <= 0:
		_perform_attack(target)
		
		# Continue combo or finish
		if attack_combo_count < combo_decision:
			attack_combo_count += 1
			match attack_combo_count:
				2: _change_state(State.ATTACK_2)
				3: _change_state(State.ATTACK_3)
				4: _change_state(State.HEAVY_ATTACK)
		else:
			velocity.x = -direction_2d.x * 2.0
			velocity.z = -direction_2d.y * 2.0
			attack_combo_count = 0
			_change_state(State.RECOVERING)

func _handle_heavy_attack_state(delta: float, target: CharacterBody3D, direction_2d: Vector2):
	velocity.x = move_toward(velocity.x, 0, FRICTION * 2.0)
	velocity.z = move_toward(velocity.z, 0, FRICTION * 2.0)
	
	_play_anim("Heavy attack")
	
	# Check if we fell off during heavy attack
	if not is_on_floor():
		attack_combo_count = 0
		_change_state(State.FALLING)
		return
	
	if state_timer <= 0:
		_perform_attack(target)
		velocity.x = -direction_2d.x * 3.5
		velocity.z = -direction_2d.y * 3.5
		attack_combo_count = 0
		recovery_attempts = 0
		_change_state(State.RECOVERING)

func _handle_recovering_state(delta: float, dist: float, direction_2d: Vector2):
	velocity.x = move_toward(velocity.x, 0, FRICTION * 3.0)
	velocity.z = move_toward(velocity.z, 0, FRICTION * 3.0)
	_play_anim("Idle")
	
	if state_timer <= 0:
		if is_on_floor():
			_change_state(State.CHASING)
		else:
			_change_state(State.FALLING)

# ===== MOVEMENT FUNCTIONS =====
func _apply_friction(delta: float):
	velocity.x = move_toward(velocity.x, 0, FRICTION)
	velocity.z = move_toward(velocity.z, 0, FRICTION)

func _apply_air_control(delta: float, direction_2d: Vector2, control_mult: float = 1.0):
	if direction_2d != Vector2.ZERO:
		var air_accel = ACCELERATION * AIR_CONTROL_FACTOR * control_mult
		velocity.x = move_toward(velocity.x, direction_2d.x * CHASE_SPEED, air_accel)
		velocity.z = move_toward(velocity.z, direction_2d.y * CHASE_SPEED, air_accel)

func _jump():
	velocity.y = JUMP_FORCE
	_change_state(State.JUMPING)

func _perform_air_action(direction_2d: Vector2):
	var direction = direction_2d
	if direction == Vector2.ZERO:
		direction = Vector2(current_facing, 0)
	
	velocity.x = direction.x * AIR_ACTION_FORCE
	velocity.z = direction.y * AIR_ACTION_FORCE
	velocity.y = AIR_ACTION_UPWARD_BOOST
	has_air_action = false
	_change_state(State.AIR_ACTION)

func _is_blocked_by_wall(direction_2d: Vector2) -> bool:
	# Raycast to detect walls in front
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		global_position + Vector3(0, 0.5, 0),
		global_position + Vector3(direction_2d.x * WALL_DETECT_DISTANCE, 0.5, direction_2d.y * WALL_DETECT_DISTANCE)
	)
	query.exclude = [self]
	var result = space_state.intersect_ray(query)
	return result.size() > 0

# ===== STATE MANAGEMENT =====
func _change_state(new_state: State) -> void:
	if current_state == new_state:
		return
	
	current_state = new_state
	
	match new_state:
		State.IDLE:
			state_timer = 0
		State.CHASING:
			state_timer = 0
		State.JUMPING:
			state_timer = 0
		State.FALLING:
			state_timer = 0
		State.AIR_ACTION:
			air_action_timer = AIR_ACTION_DURATION
		State.ATTACK_1, State.ATTACK_2, State.ATTACK_3:
			state_timer = ATTACK_DURATION
		State.HEAVY_ATTACK:
			state_timer = HEAVY_ATTACK_DURATION
		State.RECOVERING:
			state_timer = 0.3
			attack_cooldown = 1.2

func _play_anim(name: String) -> void:
	if animated_sprite_3d and animated_sprite_3d.sprite_frames:
		if animated_sprite_3d.sprite_frames.has_animation(name):
			if animated_sprite_3d.animation != name:
				animated_sprite_3d.play(name)
		elif animated_sprite_3d.sprite_frames.has_animation("Idle"):
			if animated_sprite_3d.animation != "Idle":
				animated_sprite_3d.play("Idle")

func _find_player() -> CharacterBody3D:
	# Method 1: Check for player group
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	
	# Method 2: Look for node named "Player"
	var player = get_tree().root.find_child("Player", true, false)
	if player and player is CharacterBody3D:
		return player
	
	# Method 3: Find CharacterBody3D with player script
	var all_bodies = get_tree().root.find_children("*", "CharacterBody3D", true, false)
	for body in all_bodies:
		if body == self:
			continue
		if body.has_method("change_state") and body.get("current_state") != null:
			return body
	
	return null

func _perform_attack(target: CharacterBody3D) -> void:
	if not target or not is_instance_valid(target):
		return
	
	if target.has_method("take_damage"):
		target.take_damage(ATTACK_DAMAGE, global_position)
		print("Enemy dealt ", ATTACK_DAMAGE, " damage to ", target.name)
	elif target.has_method("hit"):
		target.hit(ATTACK_DAMAGE)
		print("Enemy hit ", target.name)

func take_damage(amount: int, from_position: Vector3 = Vector3.ZERO) -> void:
	print("Enemy took ", amount, " damage")
	if current_state in [State.ATTACK_1, State.ATTACK_2, State.ATTACK_3, State.HEAVY_ATTACK]:
		state_timer = 0
		_change_state(State.RECOVERING)

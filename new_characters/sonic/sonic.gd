extends CharacterBody3D
class_name Sonic

#@export var root_body : Node3D

var top_speed : float = 2.4
var accel : float = 30.0
var decel : float = 50.0
var air_accel : float = 8.0
var friction : float = 35.0
var jump_force : float = 3.4
var gravity : float = 9.8
var fall_gravity : float = 16.0


var input : Vector2 = Vector2.ZERO
var acceleration : float = accel
var ground_speed : float = 0.0


func _process(_delta: float) -> void:
	_handle_input()

func _handle_input() -> void:
	input = Input.get_vector("left","right","forward","backward")

func apply_gravity(delta : float) -> void:
	if velocity.y < 0.0:
		velocity.y -= fall_gravity * delta
	elif not is_on_floor():
		velocity.y -= gravity * delta

func handle_ground_movement(delta : float) -> void:
	
	acceleration = accel
	
	# Compute the dot product of the velocity.
	var desired_dir : float = velocity.normalized().dot(Vector3(input.x,0.0,input.y))
	
	# Compare the flat velocity and see if its not aligned
	# e.g When moving forward and pressing forward the dot prod of it is 1.
	if desired_dir < 0.0:
		acceleration = decel
	
	var target_velocity : Vector3 = Vector3(input.x,0.0,input.y) * top_speed
	
	# This slows down the player when we are on the floor or no input.
	apply_ground_friction()
	
	# Velocity in the up direction.
	var up_vel : Vector3 = Vector3.UP.normalized() * velocity.dot(Vector3.UP)
	# This handles air movement and ground movement.
	if is_on_floor() or not input.is_equal_approx(Vector2.ZERO):
		velocity = (velocity - up_vel).move_toward(target_velocity,acceleration * delta) + up_vel
	
	move_and_slide()

func apply_ground_friction() -> void:
	if input.is_equal_approx(Vector2.ZERO) and is_on_floor():
		acceleration = friction
	elif not is_on_floor():
		acceleration = air_accel

func apply_velocity(delta : float) -> void:
	if is_on_floor() or not input.is_equal_approx(Vector2.ZERO):
		var up_vel : Vector3 = Vector3.UP.normalized() * velocity.dot(Vector3.UP)
		var target_velocity : Vector3 = Vector3(input.x,0.0,input.y) * top_speed
		velocity = (velocity - up_vel).move_toward(target_velocity,acceleration * delta) + up_vel
	move_and_slide()

#func _physics_process(delta: float) -> void:
	#handle_input()
	#
	#handle_gravity(delta)
	#
	#handle_jump()
	#
	#handle_accelerations(delta)
	#
	#move_and_slide()
	#
	#velocity_angle = atan2(velocity.x,velocity.z)
	##if not velocity.is_equal_approx(Vector3.ZERO):
		##root_body.rotation.y = lerp_angle(root_body.rotation.y,velocity_angle - PI,visual_rot_smoothing * delta)
#
#func handle_input() -> void:
	#input = Input.get_vector("move_left","move_right","move_forward","move_backward")
#
#func handle_gravity(delta : float) -> void:
	#if velocity.y < 0.0:
		#velocity.y -= fall_gravity * delta
	#elif not is_on_floor():
		#velocity.y -= gravity * delta
	#
#
#func handle_jump() -> void:
	#if Input.is_action_just_pressed("jump") and is_on_floor():
		#velocity.y = jump_force
	#
	#if Input.is_action_just_released("jump") and velocity.y > 0.0:
		#velocity.y *= 0.5
		##velocity.y -= jump_force / 2.0
#
#func handle_accelerations(delta : float) -> void:
	#
	#var current_accel : float = accel
	#
	#var desired_dir : float = velocity.normalized().dot(Vector3(input.x,0.0,input.y))
	#
	#if desired_dir < 0.0:
		#print("Oh, wait a minute!")
		#current_accel = deccel
	#
	#var up_velocity : Vector3 = Vector3.UP.normalized() * velocity.dot(Vector3.UP)
	#
	#var target_velocity : Vector3 = Vector3(input.x,0.0,input.y) * top_speed
	#
	#if input.is_equal_approx(Vector2.ZERO) and is_on_floor():
		#current_accel = friction
		#
	#if is_on_floor() or not input.is_equal_approx(Vector2.ZERO):
		#velocity = (velocity - up_velocity).move_toward(target_velocity,current_accel * delta) + up_velocity

extends CharacterBody3D
class_name Sonic

@export_group("Node requirments")
@export var shadow : AnimatedSprite3D
@export var shadow_ray : RayCast3D
@export var animator : AnimatedSprite3D

@onready var animator_ctrl : AnimatorController = AnimatorController.new(animator)

var top_speed    : float = 2.4
var accel        : float = 20.0
var decel        : float = 40.0
var air_accel    : float = 8.0
var friction     : float = 35.0
var jump_force   : float = 3.4
var gravity      : float = 9.8
var fall_gravity : float = 16.0

var input        : Vector2 = Vector2.ZERO
var facing_dir   : int = 1
var acceleration : float = accel
var ground_speed : float = 0.0
var dir          : Vector3 = Vector3.ZERO


func _process(_delta: float) -> void:
	_handle_input()
	handle_shadow()
	


func _physics_process(_delta: float) -> void:
	animator_ctrl.update()

func _handle_input() -> void:
	input = Input.get_vector("left","right","forward","backward")
	
	if input:
		dir = Vector3(input.x,0.0,input.y).normalized()

func apply_gravity(delta : float) -> void:
	if velocity.y < 0.0:
		velocity.y -= fall_gravity * delta
	elif not is_on_floor():
		velocity.y -= gravity * delta

func handle_ground_movement(delta : float) -> void:
	
	acceleration = accel
	
	# Compute the dot product of the velocity.
	var desired_dir : float = velocity.normalized().dot(Vector3(input.x,0.0,input.y).normalized())
	
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

func has_turned_around() -> bool:
	var horizontal_dir : Vector3 = Vector3.RIGHT * velocity.dot(Vector3.RIGHT)
	var turning_dir : float = horizontal_dir.dot(Vector3(input.x,0.0,input.y))
	
	return turning_dir < 0.0 or facing_dir != (sign(input.x) if input.x != 0 else facing_dir)

func handle_shadow() -> void:
	var max_height : float = 1.0
	if not shadow.top_level:
		shadow.top_level = true
		
	shadow_ray.force_raycast_update()
	
	if shadow_ray.is_colliding():
		var point : Vector3 = shadow_ray.get_collision_point()
		
		var y_offset : float = 0.04
		var z_offset : float = 0.05
		
		shadow.global_position = point + Vector3(0.0,y_offset,-z_offset)
		var dist : float = point.distance_to(global_position)
		var ratio : float = dist / max_height
		
		var convert_to_frames : int = int(ratio * 4.0)
		shadow.frame = clampi(convert_to_frames,0,3)

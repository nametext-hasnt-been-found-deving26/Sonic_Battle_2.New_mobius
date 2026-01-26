extends SonicState


@export var air_dash_effect : AnimatedSprite3D
@export var air_dash_strength : float = 5.0
@export var dash_length : float = 0.26
var offset_position : Vector3
var previous_time : float = 0.0
var dir : Vector3 = Vector3.ZERO

func _ready() -> void:
	if not air_dash_effect.top_level:
		offset_position = air_dash_effect.position
		air_dash_effect.top_level = true

func _on_enter(_context : Dictionary = {}) -> void:
	sonic.animator_ctrl.set_base("Air dash")
	sonic.animator_ctrl.play("Air dash")
	
	air_dash_effect.play("default")
	air_dash_effect.global_position = sonic.global_position + offset_position
	air_dash_effect.scale.x = -1 if sonic.facing_dir == -1 else 1
	
	previous_time = Time.get_ticks_msec() / 1000.0
	if _context.has("Dir"):
		dir = _context.get("Dir")
	
	sonic.velocity = (dir + Vector3(0,0.45,0)) * air_dash_strength
	
func _on_exit() -> void:
	pass

func _on_update(_delta : float) -> void:
	pass

func _on_physics_update(delta : float) -> void:
	
	sonic.apply_gravity(delta)
	
	sonic.move_and_slide()
	
	var current_time : float = Time.get_ticks_msec() / 1000.0
	
	if (current_time - previous_time) > dash_length:
		transition("Airborne")
		return

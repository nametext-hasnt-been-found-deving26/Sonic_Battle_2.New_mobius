extends SonicState


@export var air_dash_strength : float = 5.0
@export var dash_length : float = 0.26
var previous_time : float = 0.0
var dir : Vector3 = Vector3.ZERO

func _on_enter(_context : Dictionary = {}) -> void:
	sonic.animator_ctrl.set_base("Air dash")
	sonic.animator_ctrl.play("Air dash")
	
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

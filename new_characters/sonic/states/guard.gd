extends SonicState


@export var guard_window : float = 0.5 # 500 milliseconds

enum modifiers {Guard,Healing}
var current_modifier : modifiers = modifiers.Guard
var previous_time : float = 0.0

func _on_enter(_context : Dictionary = {}) -> void:
	previous_time = Time.get_ticks_msec() / 1000.0
	sonic.animator_ctrl.set_base("Guard")
	

func _on_exit() -> void:
	current_modifier = modifiers.Guard

func _on_update(_delta : float) -> void:
	pass

func _on_physics_update(_delta : float) -> void:
	handle_modifiers(_delta)
	

func handle_modifiers(_delta : float) -> void:
	match current_modifier:
		modifiers.Guard:
			var current_time : float = Time.get_ticks_msec() / 1000.0
			
			if (current_time - previous_time) > guard_window:
				current_modifier = modifiers.Healing
				sonic.animator_ctrl.set_base("Heal loop")
				return
			
			if Input.is_action_just_released("block"):
				transition("Idle")
				return
			
		modifiers.Healing:
			
			print("Healing!!!")
			
			if Input.is_action_just_released("block"):
				transition("Idle")
